import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'loading_screen.dart';
import 'globals.dart';
import 'models/player.dart';
import 'game_menu_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation du système de Logs (Talker)
  globalTalker = TalkerFlutter.init(
    settings: TalkerSettings(
      // CORRECTION : Augmentation de la limite à 10 000 pour conserver plus d'historique récent
      maxHistoryItems: 10000,
      // On désactive l'écriture console automatique pour éviter les doublons/boucles
      useConsoleLogs: false,
    ),
  );

  // 2. Redirection des debugPrint
  debugPrint = (String? message, {int? wrapWidth}) {
    // A. On envoie à Talker (pour l'historique dans l'appli)
    globalTalker.debug(message);

    // B. On imprime manuellement dans la console Android Studio
    if (message != null) print(message);
  };

  // 3. Gestion des erreurs Flutter (Crashs)
  FlutterError.onError = (details) => globalTalker.handle(details.exception, details.stack);

  // 4. Charger les réglages audio (Persistent)
  try {
    await loadAudioSettings();
  } catch (e) {
    globalTalker.error("Erreur chargement audio", e);
  }

  // 5. Charger les données du jeu
  await loadSavedData();

  runApp(const LoupGarouApp());
}

Future<void> loadSavedData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    List<String>? savedNames = prefs.getStringList('saved_players_list');

    if (savedNames != null && savedNames.isNotEmpty) {
      globalPlayers = savedNames.map((name) => Player(name: name, isPlaying: false)).toList();
      debugPrint("📂 Données chargées : ${globalPlayers.length} joueurs récupérés.");
    }
  } catch (e) {
    debugPrint("❌ Erreur chargement sauvegarde : $e");
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

      // Ajout de l'observateur pour voir les changements d'écran dans les logs
      navigatorObservers: [TalkerRouteObserver(globalTalker)],

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