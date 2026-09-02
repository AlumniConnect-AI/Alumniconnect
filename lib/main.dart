import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: 'https://ylsduoglhyrimxhmyipj.supabase.co',
    anonKey: 'sb_publishable_dcxF_kH_lIamJevfxQEGzQ_g4qkTJQn',
  );
  runApp(const AlumniConnectApp());
}
