import 'package:flutter/material.dart';
import 'trophy_service.dart';
import 'globals.dart';
import 'models/achievement.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TrophyHubScreen extends StatefulWidget {
  const TrophyHubScreen({super.key});

  @override
  State<TrophyHubScreen> createState() => _TrophyHubScreenState();
}

class _TrophyHubScreenState extends State<TrophyHubScreen> {
  // Helper pour obtenir la couleur selon la rareté
  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 3: return Colors.amberAccent; // Légendaire
      case 2: return Colors.purpleAccent; // Rare
      default: return Colors.blueAccent; // Commun
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("SALLE DES TROPHÉES", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: TrophyService.getStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }

          final allStats = snapshot.data ?? {};

          return FutureBuilder<Map<String, int>>(
            future: TrophyService.getGlobalStats(),
            builder: (context, globalSnapshot) {
              final global = globalSnapshot.data ?? {'VILLAGE': 0, 'LOUPS-GAROUS': 0, 'SOLO': 0};

              // Calcul du total des parties pour affichage
              int totalGames = (global['VILLAGE'] ?? 0) + (global['LOUPS-GAROUS'] ?? 0) + (global['SOLO'] ?? 0);

              return Column(
                children: [
                  _buildGlobalHeader(global, totalGames),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text("RÉPERTOIRE DES JOUEURS",
                        style: TextStyle(color: Colors.white24, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: globalPlayers.isEmpty
                        ? const Center(child: Text("Aucun joueur dans le répertoire", style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: globalPlayers.length,
                      itemBuilder: (context, index) {
                        final player = globalPlayers[index];
                        final rawData = allStats[player.name];
                        final Map<String, dynamic> pData = rawData != null
                            ? Map<String, dynamic>.from(rawData)
                            : {'totalWins': 0, 'roles': {}, 'achievements': {}};

                        return _buildPlayerCard(player.name, pData);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGlobalHeader(Map<String, int> global, int totalGames) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text("PARTIES TERMINÉES : $totalGames",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCircle("Village", global['VILLAGE'] ?? 0, Colors.greenAccent),
              _statCircle("Loups", global['LOUPS-GAROUS'] ?? 0, Colors.redAccent),
              _statCircle("Solo", global['SOLO'] ?? 0, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCircle(String label, int value, Color color) {
    return Column(
      children: [
        Text("$value", style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildPlayerCard(String name, Map<String, dynamic> pData) {
    int total = pData['totalWins'] ?? 0;
    final Map<String, dynamic> roles = pData['roles'] != null
        ? Map<String, dynamic>.from(pData['roles'])
        : {};

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: total > 0 ? Colors.orangeAccent : Colors.white10,
          child: Text("$total", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        title: Text(formatPlayerName(name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("V : ${roles['VILLAGE'] ?? 0} | L : ${roles['LOUPS-GAROUS'] ?? 0} | S : ${roles['SOLO'] ?? 0}",
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white10),
        onTap: () => _showPlayerDetails(name, pData),
      ),
    );
  }

  void _showPlayerDetails(String name, Map<String, dynamic> pData) {
    final Map<String, dynamic> unlocked = Map<String, dynamic>.from(pData['achievements'] ?? {});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(formatPlayerName(name), style: const TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("PALMARÈS DES SUCCÈS", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5)),
              const Divider(height: 30, color: Colors.white10),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: AchievementData.allAchievements.length,
                  itemBuilder: (context, index) {
                    final ach = AchievementData.allAchievements[index];
                    final isUnlocked = unlocked.containsKey(ach.id);
                    final dateObtained = unlocked[ach.id];
                    final rarityColor = _getRarityColor(ach.rarity);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isUnlocked ? rarityColor.withOpacity(0.08) : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: isUnlocked ? rarityColor.withOpacity(0.5) : Colors.transparent,
                            width: isUnlocked ? 1.5 : 1
                        ),
                      ),
                      child: Row(
                        children: [
                          // Affichage de l'Emoji du succès
                          Text(ach.icon, style: TextStyle(fontSize: 30, color: isUnlocked ? null : Colors.grey.withOpacity(0.2))),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ach.title,
                                    style: TextStyle(
                                        color: isUnlocked ? Colors.white : Colors.white24,
                                        fontWeight: FontWeight.bold
                                    )),
                                Text(ach.description,
                                    style: TextStyle(
                                        color: isUnlocked ? Colors.white70 : Colors.white10,
                                        fontSize: 12
                                    )),
                                if (isUnlocked)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text("Obtenu le $dateObtained",
                                        style: TextStyle(color: rarityColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),
                          if (isUnlocked) Icon(Icons.verified, color: rarityColor, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}