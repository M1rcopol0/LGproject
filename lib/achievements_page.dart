import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/achievement.dart';
import 'services/trophy_service.dart';

class AchievementsPage extends StatelessWidget {
  final String? playerName; // DEVENU OPTIONNEL POUR ÉVITER L'ERREUR DE COMPILATION

  const AchievementsPage({super.key, this.playerName});

  @override
  Widget build(BuildContext context) {
    // Titre dynamique selon le contexte
    String title = playerName != null
        ? "SUCCÈS DE ${playerName!.toUpperCase()}"
        : "LISTE DES TROPHEES";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<String>>(
        // Si pas de joueur spécifié, on renvoie une liste vide (tous les succès apparaîtront verrouillés)
        // ou on pourrait imaginer une liste globale débloquée sur le téléphone.
        future: playerName != null
            ? TrophyService.getUnlockedAchievements(playerName!)
            : Future.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }

          final unlockedIds = snapshot.data ?? [];
          final allAchievements = AchievementData.allAchievements;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: allAchievements.length,
            itemBuilder: (context, index) {
              final ach = allAchievements[index];
              final isUnlocked = unlockedIds.contains(ach.id);
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
                            decoration: isUnlocked ? null : TextDecoration.lineThrough,
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
                      ? Icon(FontAwesomeIcons.trophy, color: rarityColor, size: 20)
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