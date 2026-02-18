import 'dart:async';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import '../services/cloud_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0.0;
  late Timer _progressTimer;
  late Timer _phraseTimer;
  bool _cloudSyncDone = false;

  final List<String> _phrases = [
    "Synchronisation cloud...",
    "Chargement des données...",
    "Préparation des rôles...",
    "Affûtage des crocs des Loups-garous...",
    "Chargement des fusils...",
    "Consultation du grimoire...",
    "Consultation des archives...",
    "Préparation des bulletins de vote...",
    "Le Dresseur prépare son Pokémon...",
    "Le Chuchoteur murmure aux oreilles...",
    "Réveil du Tardos...",
    "Nettoyage du Pokémon...",
    "Distribution des cartes...",
    "Ron-Aldo recrute des fans...",
    "Le Pantin maudit ses cibles...",
    "L'Enculateur prépare sa capote...",
    "Les villageois ferment les volets...",
    "Le Devin se concentre...",
    "Exorcisme en cours...",
    "Le village s'endort...",
    "Le Roi se prépare à grâcier...",
    "Les Loups-garous se réveillent...",
    "Election du maire...",
    "Phyl vise ses victimes...",
    "Le Voyageur boucle sa valise...",
    "Le Maire ajuste son écharpe...",
    "Le Dictateur prépare son décret...",
    "Le Dingo arme son lance-pierres...",
    "Pré-chauffage du four de la Grand-mère...",
  ];

  int _phraseIndex = 0;
  String _currentPhrase = "";

  @override
  void initState() {
    super.initState();
    _currentPhrase = "Synchronisation cloud...";
    _startLoading();
    _syncCloudData();
  }

  // Synchronisation cloud au démarrage
  Future<void> _syncCloudData() async {
    try {
      await CloudService.pullAndOverwriteLocal(context);
    } catch (e) {
      debugPrint("⚠️ Erreur sync cloud dans LoadingScreen: $e");
    } finally {
      if (mounted) {
        setState(() {
          _cloudSyncDone = true;
        });
      }
    }
  }

  void _startLoading() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          // Progression ralentie si sync cloud pas terminée
          if (!_cloudSyncDone && _progress >= 0.7) {
            _progress += 0.003; // Ralentir à 70% en attendant le cloud
          } else {
            _progress += 0.015;
          }

          if (_progress >= 1.0) {
            _progress = 1.0;
            _stopTimers();
            _goToWelcome();
          }
        });
      }
    });

    _phraseTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted && _phraseIndex < _phrases.length - 1) {
        setState(() {
          _phraseIndex++;
          _currentPhrase = _phrases[_phraseIndex];
        });
      }
    });
  }

  void _stopTimers() {
    _progressTimer.cancel();
    _phraseTimer.cancel();
  }

  void _goToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fond d'écran
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/loading.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),

          // 2. Groupe du bas : Pourcentage + Barre + Phrase
          Positioned(
            // On remonte un peu plus (50px + padding) pour laisser la place au texte en dessous
            bottom: bottomPadding + 50,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pourcentage
                Text(
                  "${(_progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Barre de chargement
                SizedBox(
                  width: 300,
                  height: 8,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.orangeAccent],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25), // Espace entre la barre et le texte

                // Phrase (Déplacée ici, sous la barre)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    _currentPhrase,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18, // Légèrement plus petit pour bien tenir
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}