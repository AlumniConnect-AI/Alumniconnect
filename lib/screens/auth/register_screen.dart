import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

import '../../config/theme.dart';
import '../../services/alumni_verification_service.dart';
import '../../services/outcome_tracking_service.dart';
import '../profile/profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────
  final _nameController       = TextEditingController();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _phoneController      = TextEditingController();
  final _collegeIdController  = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────
  String _selectedRole    = 'student';
  int?   _selectedGradYear;
  bool   _consentGiven    = false;
  bool   _loading         = false;
  bool   _obscurePassword = true;

  // ── Country code (default India) ─────────────────────────────────────────
  static const String _countryCode = '+91';

  // ── Animation ────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    AlumniVerificationService.seedDemoData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _collegeIdController.dispose();
    super.dispose();
  }

  // ── Registration logic ───────────────────────────────────────────────────
  Future<void> _register() async {
    // ── 1. Validate all required fields ────────────────────────────────────
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone    = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('All fields are required');
      return;
    }

    if (phone.isEmpty) {
      _showError('Mobile number is required');
      return;
    }

    if (phone.length != 10 || int.tryParse(phone) == null) {
      _showError('Enter a valid 10-digit mobile number');
      return;
    }

    if (_selectedGradYear == null) {
      _showError('Please select your graduation year');
      return;
    }

    if (!_consentGiven) {
      _showError('Please accept the outcome tracking consent to continue');
      return;
    }

    // ── 2. Start loading ────────────────────────────────────────────────────
    if (!mounted) return;
    setState(() => _loading = true);

    // ── 3. Wrap entire flow in a timeout + broad catch ──────────────────────
    try {
      await _performRegistration(name, email, password, phone)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException(
            'Registration timed out. Please check your connection and try again.');
      });
    } on TimeoutException catch (e) {
      dev.log('[Register] Timeout: ${e.message}');
      _showError(e.message ?? 'Request timed out. Please try again.');
    } on FirebaseAuthException catch (e) {
      dev.log('[Register] FirebaseAuthException: ${e.code} — ${e.message}');
      _showError(_friendlyAuthError(e));
    } catch (e, st) {
      dev.log('[Register] Unexpected error: $e', stackTrace: st);
      _showError('Something went wrong. Please try again.');
    } finally {
      // Always reset loading — even on exception
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _performRegistration(
      String name, String email, String password, String phone) async {
    final e164Phone = '$_countryCode$phone';

    // ── Step A: Firebase Auth ───────────────────────────────────────────────
    dev.log('[Register] Step A: Creating Firebase Auth user...');
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    dev.log('[Register] Step A: Auth success — uid=$uid');

    // ── Step B: Navigate immediately after auth success ─────────────────────
    // Navigation does NOT wait for Firestore writes. This prevents the UI
    // from getting stuck if Firestore is slow or offline.
    if (!mounted) return;
    dev.log('[Register] Step B: Navigating to ProfileSetupScreen...');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
    );

    // ── Step C: Alumni verification (fire-and-forget, non-blocking) ─────────
    String verificationStatus = '';
    if (_selectedRole == 'alumni') {
      dev.log('[Register] Step C: Running alumni verification...');
      try {
        verificationStatus = await AlumniVerificationService.verify(
          collegeId: _collegeIdController.text.trim(),
          graduationYear: _selectedGradYear!,
        );
        dev.log('[Register] Step C: Verification status = $verificationStatus');
      } catch (e) {
        dev.log('[Register] Step C: Alumni verification failed (non-fatal): $e');
        verificationStatus = 'pending';
      }
    }

    // ── Step D: Firestore write (fire-and-forget after navigation) ──────────
    dev.log('[Register] Step D: Writing users/$uid to Firestore...');
    unawaited(
      FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': e164Phone,
        'profileCompleted': false,
        'role': _selectedRole,
        'graduationYear': _selectedGradYear,
        'consentGiven': _consentGiven,
        'consentTimestamp': FieldValue.serverTimestamp(),
        if (_selectedRole == 'alumni')
          'verificationStatus': verificationStatus,
        'engagementStats': {
          'mentorshipCount': 0,
          'referralsPosted': 0,
          'verificationsCompleted': 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
      }).then((_) {
        dev.log('[Register] Step D: Firestore write succeeded');
      }).catchError((e) {
        dev.log('[Register] Step D: Firestore write failed (non-fatal): $e');
      }),
    );

    // ── Step E: Outcome tracking init (fire-and-forget) ──────────────────────
    dev.log('[Register] Step E: Initialising outcome tracking...');
    unawaited(
      OutcomeTrackingService.initOutcome(uid).then((_) {
        dev.log('[Register] Step E: Outcome tracking initialised');
      }).catchError((e) {
        dev.log('[Register] Step E: Outcome tracking init failed (non-fatal): $e');
      }),
    );
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled. Contact support.';
      default:
        return e.message ?? 'Registration failed. Please try again.';
    }
  }

  void _showError(String msg) {
    dev.log('[Register] Error shown to user: $msg');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  List<int> get _gradYearOptions {
    final current = DateTime.now().year;
    return List.generate(12, (i) => current - 6 + i);
  }

  // ── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Logo ─────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppGradients.neonCyanPurple,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryNeon.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school,
                        size: 38, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Heading ───────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join the EduBridge alumni network',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Role Selector ─────────────────────────────────────────
                Text(
                  'I am a',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _roleChip(
                            'student', 'Student', Icons.school)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _roleChip('alumni', 'Alumni',
                            Icons.workspace_premium)),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Full Name ─────────────────────────────────────────────
                _input(context, 'Full Name', _nameController, Icons.person),
                const SizedBox(height: 14),

                // ── Email ─────────────────────────────────────────────────
                _input(context, 'Email', _emailController, Icons.email,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),

                // ── Password ──────────────────────────────────────────────
                _passwordInput(context),
                const SizedBox(height: 14),

                // ── Mobile Number (with +91 prefix) ──────────────────────
                _phoneInput(context),
                const SizedBox(height: 14),

                // ── Graduation Year ───────────────────────────────────────
                _gradYearPicker(context, isDark),

                // ── College ID (alumni only) ──────────────────────────────
                if (_selectedRole == 'alumni') ...[
                  const SizedBox(height: 14),
                  _input(
                    context,
                    'College ID (e.g. STU2022001)',
                    _collegeIdController,
                    Icons.badge_outlined,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Used to verify your alumni status against college records.',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Consent Checkbox ──────────────────────────────────────
                _consentCheckbox(context),

                const SizedBox(height: 28),

                // ── Submit Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: _loading
                      ? Shimmer.fromColors(
                          baseColor: theme.dividerColor,
                          highlightColor: theme.cardColor,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppGradients.neonCyanPurple,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNeon
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Already have an account? Login',
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ════════════════════════════════════════════════════════════════════════

  // ── Role chip ─────────────────────────────────────────────────────────────
  Widget _roleChip(String value, String label, IconData icon) {
    final selected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.neonCyanPurple : null,
          color: selected ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Theme.of(context).dividerColor,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNeon.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color:
                    selected ? Colors.white : AppColors.primary,
                size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Phone input with +91 prefix ───────────────────────────────────────────
  Widget _phoneInput(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Mobile Number (10 digits)',
        hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        prefixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.phone, size: 20),
            const SizedBox(width: 6),
            Text(
              '$_countryCode  ',
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Container(
              width: 1,
              height: 20,
              color: theme.dividerColor,
            ),
            const SizedBox(width: 4),
          ],
        ),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── Graduation year picker ────────────────────────────────────────────────
  Widget _gradYearPicker(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<int>(
      value: _selectedGradYear,
      dropdownColor: theme.cardColor,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: _selectedRole == 'alumni'
            ? 'Graduation Year'
            : 'Expected Graduation Year',
        hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        prefixIcon: Icon(Icons.calendar_today,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: _gradYearOptions
          .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
          .toList(),
      onChanged: (val) => setState(() => _selectedGradYear = val),
    );
  }

  // ── Consent checkbox ──────────────────────────────────────────────────────
  Widget _consentCheckbox(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _consentGiven
              ? AppColors.primary.withOpacity(0.5)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _consentGiven,
            activeColor: AppColors.primary,
            checkColor: Colors.black,
            onChanged: (v) =>
                setState(() => _consentGiven = v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _consentGiven = !_consentGiven),
              child: Text(
                'I consent to periodic outcome tracking (employment status check-ins) '
                'to help measure the impact of my training.',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Password input ────────────────────────────────────────────────────────
  Widget _passwordInput(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: 'Password (min 6 characters)',
        hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        prefixIcon: Icon(Icons.lock,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off
                : Icons.visibility,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ── Generic text input ────────────────────────────────────────────────────
  Widget _input(
    BuildContext context,
    String hint,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        prefixIcon: Icon(icon,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
