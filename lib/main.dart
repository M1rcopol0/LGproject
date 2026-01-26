import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loading_screen.dart';
import 'globals.dart';
import 'models/player.dart';
import 'game_menu_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Charger les réglages audio (Persistent)
  await loadAudioSettings();

  // 2. Charger les données du jeu
  await loadSavedData();

  runApp(const LoupGarouApp());
}

Future<void> loadSavedData() async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? savedNames = prefs.getStringList('saved_players_list');

  if (savedNames != null && savedNames.isNotEmpty) {
    globalPlayers = savedNames.map((name) => Player(name: name, isPlaying: false)).toList();
  }
}

class LoupGarouApp extends StatelessWidget {
  const LoupGarouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loup Garou 3.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.orangeAccent,
          surface: Color(0xFF1D1E33),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1D1E33),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == routeGameMenu) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => GameMenuScreen(players: globalPlayers),
          );
        }
        return null;
      },
    );
  }
}