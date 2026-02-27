import 'package:flutter/material.dart';
import '../state/game_history.dart';

class GameHistoryScreen extends StatelessWidget {
  final List<TurnHistoryEntry> history;

  const GameHistoryScreen({super.key, required this.history});

  Color _factionColor(String? team) {
    switch (team) {
      case "loups": return Colors.redAccent;
      case "village": return Colors.greenAccent;
      case "solo": return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }

  IconData _factionIcon(String? team) {
    switch (team) {
      case "loups": return Icons.whatshot;
      case "village": return Icons.shield;
      case "solo": return Icons.star;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("📜 HISTORIQUE"),
        backgroundColor: const Color(0xFF1D1E33),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                "Aucun événement pour l'instant.",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final isNight = entry.phase == "nuit";

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête du tour
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8, top: 4),
                      decoration: BoxDecoration(
                        color: isNight
                            ? const Color(0xFF1A1040)
                            : const Color(0xFF2A1A00),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isNight
                              ? Colors.deepPurple.withOpacity(0.5)
                              : Colors.orange.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        isNight
                            ? "⚔️ Nuit ${entry.turn}"
                            : "🗳️ Jour ${entry.turn}",
                        style: TextStyle(
                          color: isNight ? Colors.deepPurpleAccent : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Éliminations
                    ...entry.eliminations.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 6, left: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _factionColor(e.team).withOpacity(0.08),
                        border: Border.all(
                            color: _factionColor(e.team).withOpacity(0.5),
                            width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(_factionIcon(e.team),
                              color: _factionColor(e.team), size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.playerName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Text(
                                  "${e.role}  •  ${e.reason}",
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
    );
  }
}
