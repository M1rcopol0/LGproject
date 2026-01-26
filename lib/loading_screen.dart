import 'dart:async';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0.0;
  late Timer _progressTimer;
  late Timer _phraseTimer;

  // Liste enrichie de phrases immersives
  final List<String> _phrases = [
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
    // Mélange initial : garantit un ordre unique sans répétition
    _phrases.shuffle();
    _currentPhrase = _phrases[0];
    _startLoading();
  }

  void _startLoading() {
    // Timer pour la barre de progression
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.015;
          if (_progress >= 1.0) {
            _progress = 1.0;
            _stopTimers();
            _goToWelcome();
          }
        });
      }
    });

    // Timer pour les phrases (une nouvelle phrase toutes les 1.2 secondes)
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      // Parcours de la liste mélangée sans jamais revenir en arrière
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

          // 2. Phrases (Centre de l'écran)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _currentPhrase,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                ),
              ),
            ),
          ),

          // 3. Barre de progression et Pourcentage (Bas de l'écran)
          Positioned(
            bottom: bottomPadding + 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Pourcentage juste au-dessus de la barre
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}