import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lobby_screen.dart';
import 'player_directory_screen.dart'; // NOUVEL IMPORT
import 'settings_screen.dart';
import 'wiki_screen.dart';
import 'trophy_hub_screen.dart';
import '../globals.dart';
import '../models/player.dart';
import '../services/game_save_service.dart';
import '../logic/role_distribution_logic.dart';
import '../player_storage.dart';

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
    RoleDistributionLogic.logMemoryState();
  }

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
            // Haut Gauche : Trophées
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

            // Haut Droite : Grimoire + Annuaire (Groupe de boutons)
            Positioned(
              top: safePadding.top + 10,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NOUVEAU BOUTON : ANNUAIRE
                  _buildCornerButton(
                    icon: Icons.person, // Bonhomme
                    color: Colors.greenAccent,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlayerDirectoryScreen())
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  // BOUTON GRIMOIRE (Existant)
                  _buildCornerButton(
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
                ],
              ),
            ),

            // CONTENU CENTRAL (Inchangé)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                              MaterialPageRoute(builder: (_) => LobbyScreen(players: globalPlayers)),
                            ).then((_) => _checkSave());
                          }
                        },
                        icon: const Icon(Icons.history, size: 28),
                        label: const Text("REPRENDRE PARTIE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

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
                        await resetAllGameData();
                        final names = await PlayerDirectory.getSavedPlayers();
                        globalPlayers = names.map((n) => Player(name: n)).toList();
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
                              builder: (_) => LobbyScreen(players: globalPlayers),
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