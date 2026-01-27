import 'package:flutter/material.dart';
import 'trophy_service.dart';
import 'models/achievement.dart'; // C'est ici qu'on récupère la classe et les données déplacées

class AchievementsPage extends StatelessWidget {
  final String playerName;

  const AchievementsPage({super.key, required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text("SUCCÈS : $playerName", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<String>>(
        // On récupère la liste des IDs débloqués (ex: "first_blood", "bad_shooter")
        future: TrophyService.getUnlockedAchievements(playerName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }

          final unlockedIds = snapshot.data ?? [];
          // On récupère la définition des succès depuis le modèle centralisé (gain de place ici)
          final allAchievements = AchievementData.allAchievements;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: allAchievements.length,
            itemBuilder: (context, index) {
              final ach = allAchievements[index];
              final isUnlocked = unlockedIds.contains(ach.id);

              // La couleur est désormais gérée par le modèle (facile=bleu, légendaire=or...)
              final rarityColor = ach.color;

              return Card(
                color: isUnlocked
                    ? rarityColor.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isUnlocked ? rarityColor.withOpacity(0.8) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

                  // ICÔNE (Emoji)
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked ? rarityColor.withOpacity(0.2) : Colors.white10,
                    ),
                    child: Text(
                      ach.icon,
                      style: TextStyle(
                        fontSize: 24,
                        color: isUnlocked ? null : Colors.white24,
                      ),
                    ),
                  ),

                  // TITRE + BADGE RARETÉ
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ach.title,
                          style: TextStyle(
                            color: isUnlocked ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isUnlocked)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: rarityColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ach.rarityLabel,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // DESCRIPTION
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      ach.description,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white70 : Colors.white24,
                        fontSize: 12,
                        fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),

                  // CHECKMARK ou CADENAS
                  trailing: isUnlocked
                      ? Icon(Icons.check_circle, color: rarityColor)
                      : const Icon(Icons.lock_outline, color: Colors.white12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}