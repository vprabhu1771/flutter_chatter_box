import 'package:flutter/material.dart';
import 'package:flutter_chatter_box/screens/HomeScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPA_BASE_URL'] ?? "",
    anonKey: dotenv.env['SUPA_BASE_ANON_KEY'] ?? "",
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(title: 'Home'),
    );
  }
}