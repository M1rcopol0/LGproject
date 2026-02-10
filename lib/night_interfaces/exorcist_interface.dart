import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';

class ExorcistInterface extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final Function(String, dynamic) onAction;

  const ExorcistInterface({
    super.key,
    required this.player,
    required this.allPlayers,
    required this.onAction,
  });

  @override
  State<ExorcistInterface> createState() => _ExorcistInterfaceState();
}

class _ExorcistInterfaceState extends State<ExorcistInterface> {
  Player? _targetToMimic;

  @override
  void initState() {
    super.initState();
    _pickRandomTarget();
  }

  void _pickRandomTarget() {
    // Filtrage des candidats éligibles au mimétisme
    final candidates = widget.allPlayers.where((p) {
      // 1. Doit être vivant et ne pas être l'Exorciste lui-même
      if (!p.isAlive || p.name == widget.player.name) return false;

      String role = p.role?.toLowerCase() ?? "";

      // 2. Archiviste : Ne pas mimer s'il est devenu MJ (absent)
      if (role == "archiviste" && p.isAwayAsMJ) {
        return false;
      }

      // 3. Voyageur : Ne pas mimer s'il est rentré définitivement (contraint ou non)
      // (canTravelAgain passe à false dès qu'il rentre au village)
      if (role == "voyageur" && !p.canTravelAgain) {
        return false;
      }

      // 4. Pokémon : Ne pas mimer s'il a été ressuscité (forme alternative/réduite)
      if ((role == "pokémon" || role == "pokemon") && p.wasRevivedInThisGame) {
        return false;
      }

      return true;
    }).toList();

    if (candidates.isNotEmpty) {
      setState(() {
        _targetToMimic = candidates[Random().nextInt(candidates.length)];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology, size: 80, color: Colors.purpleAccent),
            const SizedBox(height: 30),

            if (_targetToMimic != null) ...[
              const Text(
                "⚠️ GAGE DE L'EXORCISTE ⚠️",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tu dois mimer le joueur suivant :",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.purpleAccent),
                ),
                child: Column(
                  children: [
                    Text(
                      _targetToMimic!.name,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "(${_targetToMimic!.role})",
                      style: const TextStyle(color: Colors.white54, fontSize: 18, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                icon: const Icon(Icons.check_circle, size: 30),
                label: const Text("C'EST RÉUSSI !", style: TextStyle(fontSize: 18)),
                onPressed: () {
                  // Envoi de "SUCCESS" pour déclencher la victoire villageoise (voir night_actions_screen.dart)
                  widget.onAction("SUCCESS", null);
                },
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  widget.onAction("SKIP", null);
                },
                child: const Text("J'ai échoué / Je passe", style: TextStyle(color: Colors.white38)),
              ),
            ] else ...[
              const Text(
                "Personne à mimer (Aucun joueur éligible).",
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => widget.onAction("SKIP", null),
                child: const Text("PASSER"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}