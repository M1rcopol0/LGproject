import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_menu_screen.dart';
import 'settings_screen.dart';
import 'wiki_page.dart';
import 'trophy_hub_screen.dart';
import 'globals.dart';
import 'models/player.dart';
import 'game_save_service.dart';
import 'storage_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _hasSave = false;

  @override
  void initState() {
    super.initState();
    _checkSave();
  }

  // Vérifie l'existence d'une sauvegarde de partie en cours
  void _checkSave() async {
    bool exists = await GameSaveService.hasSaveGame();
    if (mounted) {
      setState(() {
        _hasSave = exists;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0E21), Color(0xFF1A1A2E)],
          ),
        ),
        child: Stack(
          children: [
            // Haut Gauche : Trophées (Succès et Stats préservés)
            Positioned(
              top: safePadding.top + 10,
              left: 20,
              child: _buildCornerButton(
                icon: Icons.emoji_events,
                color: Colors.amber,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TrophyHubScreen())
                  );
                },
              ),
            ),

            // Haut Droite : Grimoire
            Positioned(
              top: safePadding.top + 10,
              right: 20,
              child: _buildCornerButton(
                icon: Icons.book,
                color: Colors.blueAccent,
                onPressed: () {
                  playSfx("grimoire_open.mp3");
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WikiPage())
                  );
                },
              ),
            ),

            // CONTENU CENTRAL
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. BOUTON REPRENDRE (Si une partie est en cours)
                  if (_hasSave) ...[
                    SizedBox(
                      width: 250,
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                          elevation: 10,
                        ),
                        onPressed: () async {
                          bool success = await GameSaveService.loadGame();
                          if (success && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GameMenuScreen(players: globalPlayers)),
                            ).then((_) => _checkSave());
                          }
                        },
                        icon: const Icon(Icons.history, size: 28),
                        label: const Text("REPRENDRE PARTIE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 2. BOUTON LANCER (Nouvelle partie - Nettoie la session mais garde le répertoire)
                  SizedBox(
                    width: 250,
                    height: 70,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                        elevation: 10,
                      ),
                      onPressed: () async {
                        // A. On réinitialise la session de jeu (RAM + Sauvegarde de partie)
                        await resetAllGameData();

                        // B. On charge les joueurs enregistrés dans globalPlayers pour la préparation
                        globalPlayers = await StorageService.loadPlayers();

                        // C. On s'assure qu'ils ne sont pas cochés "en jeu" par défaut
                        for (var p in globalPlayers) {
                          p.isPlaying = false;
                          p.isRoleLocked = false;
                          p.role = null;
                        }

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(name: routeGameMenu),
                              builder: (_) => GameMenuScreen(players: globalPlayers),
                            ),
                          ).then((_) => _checkSave());
                        }
                      },
                      icon: const Icon(Icons.play_arrow, size: 30),
                      label: const Text("LANCER LA PARTIE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            // Bas Gauche : Quitter
            Positioned(
              bottom: 30,
              left: 20,
              child: _buildCornerButton(
                icon: Icons.power_settings_new,
                color: Colors.redAccent,
                onPressed: () => SystemNavigator.pop(),
              ),
            ),

            // Bas Droite : Paramètres
            Positioned(
              bottom: 30,
              right: 20,
              child: _buildCornerButton(
                icon: Icons.settings,
                color: Colors.grey,
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())
                  ).then((_) => _checkSave());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2
            )
          ]
      ),
      child: IconButton(
          iconSize: 35,
          icon: Icon(icon, color: color),
          onPressed: onPressed
      ),
    );
  }
}