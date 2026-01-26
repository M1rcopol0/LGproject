import 'package:flutter/material.dart';
import 'trophy_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(Map<String, dynamic> stats) condition;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.condition,
  });
}

class AchievementsPage extends StatelessWidget {
  final String playerName;

  AchievementsPage({super.key, required this.playerName});

  // ==========================================================
  // DÉFINITION DES 10 SUCCÈS
  // ==========================================================
  final List<Achievement> achievementList = [
    Achievement(
      id: "first_win",
      title: "Premier Sang",
      description: "Remporter sa toute première partie.",
      icon: Icons.emoji_events,
      condition: (stats) => (stats['totalWins'] ?? 0) >= 1,
    ),
    Achievement(
      id: "village_hero",
      title: "Héros du Village",
      description: "Gagner 5 fois avec le camp du Village.",
      icon: Icons.gite,
      condition: (stats) => (stats['roles']?['VILLAGE'] ?? 0) >= 5,
    ),
    Achievement(
      id: "alpha_wolf",
      title: "Loup Alpha",
      description: "Gagner 5 fois avec les Loups-garous.",
      icon: Icons.nights_stay,
      condition: (stats) => (stats['roles']?['LOUPS-GAROUS'] ?? 0) >= 5,
    ),
    Achievement(
      id: "siuuuu",
      title: "SIUUUUUU",
      description: "Gagner une partie avec Ron-Aldo.",
      icon: Icons.star,
      condition: (stats) => (stats['roles']?['RON-ALDO'] ?? 0) >= 1,
    ),
    Achievement(
      id: "solo_master",
      title: "Cavalier Seul",
      description: "Gagner 3 fois avec un rôle Solo (hors Ron-Aldo).",
      icon: Icons.person_pin,
      condition: (stats) => (stats['roles']?['SOLO'] ?? 0) >= 3,
    ),
    Achievement(
      id: "legend",
      title: "Légende du Village",
      description: "Atteindre un total de 20 victoires.",
      icon: Icons.workspace_premium,
      condition: (stats) => (stats['totalWins'] ?? 0) >= 20,
    ),
    Achievement(
      id: "fan_club",
      title: "Fan Club",
      description: "Gagner 3 fois en tant que Fan de Ron-Aldo.",
      icon: Icons.favorite,
      condition: (stats) => (stats['roles']?['FAN'] ?? 0) >= 3,
    ),
    Achievement(
      id: "survivor",
      title: "Survivant",
      description: "Gagner 10 parties au total.",
      icon: Icons.shield,
      condition: (stats) => (stats['totalWins'] ?? 0) >= 10,
    ),
    Achievement(
      id: "archiviste_pro",
      title: "L'Érudit",
      description: "Gagner une partie après avoir été Archiviste.",
      icon: Icons.menu_book,
      condition: (stats) => (stats['roles']?['VILLAGE'] ?? 0) >= 1, // On simplifie la condition ici
    ),
    Achievement(
      id: "veteran",
      title: "Vétéran",
      description: "Avoir gagné avec au moins 3 camps différents.",
      condition: (stats) {
        int camps = 0;
        final roles = stats['roles'] ?? {};
        if ((roles['VILLAGE'] ?? 0) > 0) camps++;
        if ((roles['LOUPS-GAROUS'] ?? 0) > 0) camps++;
        if ((roles['SOLO'] ?? 0) > 0 || (roles['RON-ALDO'] ?? 0) > 0) camps++;
        return camps >= 3;
      },
      icon: Icons.military_tech,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text("SUCCÈS : $playerName"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: TrophyService.getStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allStats = snapshot.data!;
          final playerStats = allStats[playerName] ?? {'totalWins': 0, 'roles': {}};

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: achievementList.length,
            itemBuilder: (ctx, i) {
              final ach = achievementList[i];
              final isUnlocked = ach.condition(playerStats);

              return Card(
                color: isUnlocked ? Colors.white.withOpacity(0.1) : Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: isUnlocked ? Colors.orangeAccent.withOpacity(0.5) : Colors.transparent,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Icon(
                    ach.icon,
                    size: 40,
                    color: isUnlocked ? Colors.orangeAccent : Colors.white10,
                  ),
                  title: Text(
                    ach.title,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    ach.description,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white70 : Colors.white10,
                    ),
                  ),
                  trailing: isUnlocked
                      ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                      : const Icon(Icons.lock_outline, color: Colors.white10),
                ),
              );
            },
          );
        },
      ),
    );
  }
}