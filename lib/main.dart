import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'screens/loading_screen.dart';
import 'globals.dart';
import 'models/player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// IMPORTANT : On importe le nouvel écran de Lobby
import 'screens/lobby_screen.dart';
// IMPORTANT : On importe le service de stockage pour la synchro
import 'player_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation du système de Logs (Talker)
  // CONFIGURATION CRITIQUE : On garde les 20 000 lignes les plus récentes.
  globalTalker = TalkerFlutter.init(
    settings: TalkerSettings(
      maxHistoryItems: 20000, // Les anciens logs seront écrasés par les nouveaux
      useConsoleLogs: false,  // On gère nous-même le print pour éviter les doublons
    ),
  );

  // 2. Redirection des debugPrint
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      // A. On envoie à Talker (pour l'historique dans l'appli et l'export)
      globalTalker.debug(message);

      // B. On imprime manuellement dans la console Android Studio (pour le débug direct)
      print(message);
    }
  };

  // 3. Gestion des erreurs Flutter (Crashs)
  FlutterError.onError = (details) => globalTalker.handle(details.exception, details.stack);

  // 4. Charger les réglages audio (Persistent)
  try {
    await loadAudioSettings();
  } catch (e) {
    globalTalker.error("Erreur chargement audio", e);
  }

  // 5. Charger les données du jeu (Joueurs + Annuaire)
  await loadSavedData();

  runApp(const LoupGarouApp());
}

Future<void> loadSavedData() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // --- ÉTAPE 1 : MIGRATION (Si nécessaire) ---
    // On vérifie s'il existe une vieille liste de sauvegarde "simple"
    List<String>? legacyNames = prefs.getStringList('saved_players_list');

    if (legacyNames != null && legacyNames.isNotEmpty) {
      debugPrint("📂 Migration détectée : Synchronisation des anciens joueurs vers l'Annuaire...");
      // On injecte les anciens noms dans le nouvel annuaire structuré
      await PlayerDirectory.synchronizeWithLegacy(legacyNames);
    }

    // --- ÉTAPE 2 : CHARGEMENT DEPUIS LA SOURCE UNIQUE (ANNUAIRE) ---
    // On récupère la liste des noms depuis l'annuaire (qui est maintenant la source de vérité)
    List<String> loadedNames = await PlayerDirectory.getSavedPlayers();

    if (loadedNames.isNotEmpty) {
      // On recrée les objets Player globaux
      globalPlayers = loadedNames.map((name) => Player(name: name, isPlaying: false)).toList();

      // --- ÉTAPE 3 : HYDRATATION (Numéros de téléphone) ---
      // On récupère les numéros de téléphone pour chaque joueur
      for (var p in globalPlayers) {
        p.phoneNumber = await PlayerDirectory.getPhoneNumber(p.name);
      }

      debugPrint("📂 Données chargées avec succès : ${globalPlayers.length} joueurs (avec numéros).");
    } else {
      debugPrint("📂 Aucun joueur trouvé dans l'annuaire.");
    }

  } catch (e) {
    debugPrint("❌ Erreur critique lors du chargement de la sauvegarde : $e");
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
          // On pointe vers le LobbyScreen (Préparation) au lieu de l'ancien GameMenuScreen
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => LobbyScreen(players: globalPlayers),
          );
        }
        return null;
      },
    );
  }
}