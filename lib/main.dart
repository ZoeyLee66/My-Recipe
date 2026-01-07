import 'package:flutter/material.dart';
import 'package:assignment/recipe_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'db/isar_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.db;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF187C5C), //point colour
    );
    final kantumruyFamily = GoogleFonts.kantumruyPro().fontFamily;

    return MaterialApp(
      title: 'my recipe',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        fontFamily: kantumruyFamily,
        scaffoldBackgroundColor: const Color(0xFFFFFEF0),
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: RecipeApp(),
    );
  }
}


