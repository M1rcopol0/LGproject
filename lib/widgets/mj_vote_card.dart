import 'package:flutter/material.dart';
import '../models/player.dart';

class MJVoteCard extends StatelessWidget {
  final Player player;
  final List<Player> allPlayers; // Nécessaire pour check Ron-Aldo fans
  final VoidCallback onTap;

  const MJVoteCard({
    super.key,
    required this.player,
    required this.allPlayers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul de l'immunité visuelle
    bool isImmunized = player.isImmunizedFromVote || player.isInHouse;

    // Protection Ron-Aldo visuelle (Si des fans sont en vie)
    if (player.role?.toLowerCase() == "ron-aldo") {
      if (allPlayers.any((f) => f.isFanOfRonAldo && f.isAlive)) isImmunized = true;
    }

    return Card(
      color: isImmunized ? Colors.cyan.withOpacity(0.1) : Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        leading: isImmunized
            ? const Icon(Icons.shield, color: Colors.cyanAccent, size: 28)
            : const Icon(Icons.person_outline, color: Colors.white24),
        title: Text(
          Player.formatName(player.name),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isImmunized ? Colors.cyanAccent : Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.role?.toUpperCase() ?? "INCONNU",
              style: TextStyle(
                color: isImmunized
                    ? Colors.cyanAccent.withOpacity(0.6)
                    : Colors.orangeAccent,
                fontSize: 12,
              ),
            ),
            if (player.hasScapegoatPower)
              const Text("🐐 Possède le Bouc Émissaire",
                  style: TextStyle(
                      color: Colors.brown,
                      fontSize: 10,
                      fontWeight: FontWeight.bold))
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: isImmunized ? Colors.cyan[900] : Colors.red[900],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text("${player.votes} VOIX",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        onTap: onTap,
      ),
    );
  }
}