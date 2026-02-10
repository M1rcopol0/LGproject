import 'package:flutter/material.dart';

class GameActionButtons extends StatelessWidget {
  final bool isGameStarted;
  final VoidCallback onVote;
  final VoidCallback onNight;
  final VoidCallback onStartGame;
  final VoidCallback onAddPlayer;

  const GameActionButtons({
    super.key,
    required this.isGameStarted,
    required this.onVote,
    required this.onNight,
    required this.onStartGame,
    required this.onAddPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1D1E33),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          if (isGameStarted) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: onVote,
                    icon: const Icon(Icons.how_to_vote, color: Colors.white),
                    label: const Text(
                      "VOTE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: onNight,
                    icon: const Icon(Icons.nights_stay, color: Colors.white),
                    label: const Text(
                      "NUIT",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: onStartGame,
              child: const Text(
                "LANCER LA PARTIE",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onAddPlayer,
              icon: const Icon(Icons.add, color: Colors.orangeAccent),
              label: const Text(
                "AJOUTER UN JOUEUR",
                style: TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}