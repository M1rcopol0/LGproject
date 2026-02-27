import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/achievement.dart';
import '../services/trophy_service.dart';

class AchievementsPage extends StatelessWidget {
  final String? playerName;
  final List<String> activeRoles; // rôles en jeu + pseudo-tokens (MODE_X, PLAYER_Name)

  const AchievementsPage({super.key, this.playerName, this.activeRoles = const []});

  bool _isObtainable(Achievement ach) {
    if (activeRoles.isEmpty) return true; // vue générique = tout affiché normalement
    if (ach.requiredRoles.isEmpty) return true; // pas de prérequis = toujours obtainable
    return ach.requiredRoles.any((r) => activeRoles.contains(r));
  }

  @override
  Widget build(BuildContext context) {
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
        future: playerName != null
            ? TrophyService.getUnlockedAchievements(playerName!)
            : Future.value([]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }

          final unlockedIds = snapshot.data ?? [];
          final allAchievements = AchievementData.allAchievements;

          // Si activeRoles est vide (vue générique), affichage uniforme
          if (activeRoles.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: allAchievements.length,
              itemBuilder: (context, index) =>
                  _buildAchievementCard(allAchievements[index], unlockedIds, obtainable: true),
            );
          }

          // Vue en partie : séparer obtenables / non-obtenables
          final obtainable = allAchievements.where(_isObtainable).toList();
          final unavailable = allAchievements.where((a) => !_isObtainable(a)).toList();

          final itemCount = obtainable.length + (unavailable.isNotEmpty ? 1 + unavailable.length : 0);

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index < obtainable.length) {
                return _buildAchievementCard(obtainable[index], unlockedIds, obtainable: true);
              }
              if (index == obtainable.length) {
                // Header section non-disponibles
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 12),
                  child: Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white24)),
                      const SizedBox(width: 10),
                      Text(
                        "🚫 NON DISPONIBLES DANS CETTE PARTIE",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),
                );
              }
              final ach = unavailable[index - obtainable.length - 1];
              return _buildAchievementCard(ach, unlockedIds, obtainable: false);
            },
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard(Achievement ach, List<String> unlockedIds, {required bool obtainable}) {
    final isUnlocked = unlockedIds.contains(ach.id);
    final rarityColor = ach.color;

    // Succès non-obtainable : toujours affiché comme verrouillé/grisé
    final effectiveUnlocked = isUnlocked && obtainable;

    return Card(
      color: effectiveUnlocked
          ? rarityColor.withOpacity(0.15)
          : Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: effectiveUnlocked ? rarityColor.withOpacity(0.8) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveUnlocked ? rarityColor.withOpacity(0.2) : Colors.white10,
          ),
          child: Text(
            ach.icon,
            style: TextStyle(
              fontSize: 24,
              color: effectiveUnlocked ? null : Colors.white24,
            ),
          ),
        ),

        title: Row(
          children: [
            Expanded(
              child: Text(
                ach.title,
                style: TextStyle(
                  color: effectiveUnlocked ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  decoration: effectiveUnlocked ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            if (effectiveUnlocked)
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
              )
            else if (!obtainable)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "INDISPONIBLE",
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            ach.description,
            style: TextStyle(
              color: effectiveUnlocked ? Colors.white70 : Colors.white24,
              fontSize: 12,
              fontStyle: effectiveUnlocked ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),

        trailing: effectiveUnlocked
            ? Icon(FontAwesomeIcons.trophy, color: rarityColor, size: 20)
            : const Icon(Icons.lock_outline, color: Colors.white12),
      ),
    );
  }
}
