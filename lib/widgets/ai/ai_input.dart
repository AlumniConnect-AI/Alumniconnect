import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../theme/glass_card.dart';

class AIInputWidget extends StatefulWidget {
  final Function(String profileText, String jdText, double expYears) onAnalyze;
  final bool isLoading;

  const AIInputWidget({
    super.key,
    required this.onAnalyze,
    required this.isLoading,
  });

  @override
  State<AIInputWidget> createState() => _AIInputWidgetState();
}

class _AIInputWidgetState extends State<AIInputWidget> {
  final _profileController = TextEditingController();
  final _jdController = TextEditingController();
  final _expController = TextEditingController(text: '2.0');
  String? _uploadedPdfName;

  void _loadPreset(String profile, String jd, String exp) {
    setState(() {
      _profileController.text = profile;
      _jdController.text = jd;
      _expController.text = exp;
      _uploadedPdfName = null;
    });
  }

  Future<void> _pickPdfResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String extractedText = "";

        if (file.bytes != null && file.bytes!.isNotEmpty) {
          final rawString = String.fromCharCodes(file.bytes!);
          final matches = RegExp(r'[A-Za-z0-9\s.,@\-+:;\(\)\/]{3,}').allMatches(rawString);
          final textBlocks = matches
              .map((m) => m.group(0)!.trim())
              .where((t) => t.length > 3 && !t.contains("PDF") && !t.contains("obj") && !t.contains("endobj"))
              .toList();
          extractedText = textBlocks.join("\n");
        }

        if (extractedText.trim().length < 15) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Unable to parse uploaded resume. Please ensure the PDF contains readable text."),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        setState(() {
          _uploadedPdfName = file.name;
          _profileController.text = extractedText.trim();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Successfully extracted text from: ${file.name}"),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF Selection Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _profileController.dispose();
    _jdController.dispose();
    _expController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UPLOAD PDF RESUME BANNER
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.primaryNeon.withValues(alpha: 0.4),
          backgroundColor: AppColors.primarySoft,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primaryNeon,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uploadedPdfName != null
                          ? "Loaded: $_uploadedPdfName"
                          : "Upload PDF Resume (One-Click Auto AI)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Supports Canva, Word, LinkedIn, Naukri & ATS PDFs",
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _pickPdfResume,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text("Upload", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        // Preset sample quick loader
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Sample Presets",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _presetChip(
                    "Flutter Dev",
                    "Experienced Flutter & Dart developer proficient in Firebase, Supabase, Git, and state management.",
                    "Seeking a Senior Flutter Developer with 2+ years experience in Dart, Firebase, and mobile deployment.",
                    "2.0",
                  ),
                  const SizedBox(width: 6),
                  _presetChip(
                    "Data Scientist",
                    "Data Scientist experienced in Python, Machine Learning, Scikit-learn, TensorFlow, and SQL.",
                    "Looking for a Data Scientist to build ML models using Python, Scikit-learn, and SQL databases.",
                    "3.0",
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Profile / Resume Multiline Input
        Text(
          "Candidate Profile / Resume Text *",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _profileController,
          maxLines: 5,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Paste candidate skills, background, experience, or resume summary...",
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Job Description Multiline Input
        Text(
          "Target Job Description",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _jdController,
          maxLines: 4,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Paste target job posting details or requirements (optional)...",
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Required Experience Input
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Required Experience (Years)",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _expController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "e.g. 2.0",
                      filled: true,
                      fillColor: theme.cardColor,
                      prefixIcon: const Icon(Icons.work_history, color: AppColors.primary, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Analyze Action Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.isLoading
                ? null
                : () {
                    final exp = double.tryParse(_expController.text.trim()) ?? 0.0;
                    widget.onAnalyze(
                      _profileController.text.trim(),
                      _jdController.text.trim(),
                      exp,
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 20),
                      SizedBox(width: 10),
                      Text(
                        "Run AI Career Twin Analysis",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _presetChip(String label, String profile, String jd, String exp) {
    return ActionChip(
      avatar: const Icon(Icons.bolt, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.primarySoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => _loadPreset(profile, jd, exp),
    );
  }
}
