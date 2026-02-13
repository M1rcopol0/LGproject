import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/trophy_service.dart';
import '../globals.dart';
import '../models/achievement.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/player.dart'; // Nécessaire pour le type Player
import '../services/cloud_service.dart'; // Ajout pour le Force Upload

class TrophyHubScreen extends StatefulWidget {
  const TrophyHubScreen({super.key});

  @override
  State<TrophyHubScreen> createState() => _TrophyHubScreenState();
}

class _TrophyHubScreenState extends State<TrophyHubScreen> {
  Map<String, dynamic> _stats = {};
  Map<String, int> _globalStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await TrophyService.getStats();
    final global = await TrophyService.getGlobalStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _globalStats = global;
        _isLoading = false;
      });
    }
  }

  // ===========================================================================
  // 1. SÉLECTION DU JOUEUR (Annuaire Complet pour Admin)
  // ===========================================================================
  void _showPlayerPicker() async {
    final prefs = await SharedPreferences.getInstance();
    // On récupère tous les noms bruts (Annuaire + Stats)
    List<String> rawList = prefs.getStringList('saved_players_list') ?? [];
    rawList.addAll(_stats.keys);

    // NETTOYAGE ET DÉ-DOUBLONNAGE
    // On utilise un Set pour éliminer les doublons
    // On formate chaque nom pour que "claude" devienne "Claude"
    Set<String> cleanNames = {};
    for (String name in rawList) {
      if (name.trim().isNotEmpty) {
        cleanNames.add(Player.formatName(name));
      }
    }

    // Conversion en liste et tri
    List<String> allPlayers = cleanNames.toList();
    allPlayers.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Choisir un joueur", style: TextStyle(color: Colors.orangeAccent)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: allPlayers.isEmpty
              ? const Center(child: Text("Aucun joueur enregistré.", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              final name = allPlayers[index];
              return ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: Text(name, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.edit, color: Colors.blueAccent),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAchievementManager(name);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. GESTIONNAIRE DE SUCCÈS (ON/OFF)
  // ===========================================================================
  void _showAchievementManager(String playerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ajuster les succès", style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text(playerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: FutureBuilder<List<String>>(
            // On récupère la liste des succès actuels du joueur
            future: TrophyService.getUnlockedAchievements(playerName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
              }

              // Copie locale pour modification instantanée
              List<String> unlocked = List.from(snapshot.data ?? []);

              // StatefulBuilder permet de rafraîchir la liste sans fermer la popup
              return StatefulBuilder(
                builder: (context, setStateInner) {
                  return ListView.builder(
                    itemCount: AchievementData.allAchievements.length,
                    itemBuilder: (context, index) {
                      final ach = AchievementData.allAchievements[index];
                      final isUnlocked = unlocked.contains(ach.id);

                      return CheckboxListTile(
                        activeColor: ach.color,
                        checkColor: Colors.black,
                        title: Text(
                            ach.title,
                            style: TextStyle(
                                color: isUnlocked ? Colors.white : Colors.white38,
                                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal
                            )
                        ),
                        subtitle: Text(
                            ach.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white24, fontSize: 10)
                        ),
                        secondary: Text(ach.icon, style: const TextStyle(fontSize: 24)),
                        value: isUnlocked,
                        onChanged: (bool? value) async {
                          if (value == true) {
                            // ACTIVER
                            await TrophyService.unlockAchievement(playerName, ach.id);
                            unlocked.add(ach.id);
                          } else {
                            // DÉSACTIVER
                            await TrophyService.removeAchievement(playerName, ach.id);
                            unlocked.remove(ach.id);

                            // CORRECTION : Forcer l'envoi au Cloud pour supprimer là-bas aussi
                            if (context.mounted) {
                              CloudService.forceUploadData(context);
                            }
                          }
                          // Rafraîchir l'interface locale
                          setStateInner(() {});
                          // Rafraîchir l'écran parent en arrière-plan
                          _loadData();
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("FERMER", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Préparation de la liste triée pour l'affichage principal
    List<String> sortedPlayerNames = _stats.keys.toList();
    sortedPlayerNames.sort((a, b) {
      int winsA = (_stats[a]?['totalWins'] ?? 0) as int;
      int winsB = (_stats[b]?['totalWins'] ?? 0) as int;
      return winsB.compareTo(winsA); // Décroissant
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("SALLE DES TROPHÉES", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      // LE BOUTON D'ADMINISTRATION
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.build),
        label: const Text("AJUSTER SUCCÈS", style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showPlayerPicker,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
          : Column(
        children: [
          // Header Global (Sans le Top Player)
          _buildGlobalHeader(_globalStats),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("CLASSEMENT DES JOUEURS",
                style: TextStyle(color: Colors.white24, letterSpacing: 1.2, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: sortedPlayerNames.isEmpty
                ? const Center(child: Text("Aucun joueur dans le classement", style: TextStyle(color: Colors.white38)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: sortedPlayerNames.length,
              itemBuilder: (context, index) {
                final name = sortedPlayerNames[index];
                final pData = Map<String, dynamic>.from(_stats[name] ?? {});

                // On passe l'index pour afficher le rang (1er, 2ème...)
                return _buildPlayerCard(name, pData, index + 1);
              },
            ),
          ),
          // Espace pour ne pas que le FAB cache le dernier élément
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Header simplifié (sans top player)
  Widget _buildGlobalHeader(Map<String, int> global) {
    int totalGames = (global['VILLAGE'] ?? 0) + (global['LOUPS-GAROUS'] ?? 0) + (global['SOLO'] ?? 0);

    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text("PARTIES JOUÉES : $totalGames",
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

  Widget _buildPlayerCard(String name, Map<String, dynamic> pData, int rank) {
    int total = pData['totalWins'] ?? 0;
    final Map<String, dynamic> roles = pData['roles'] != null
        ? Map<String, dynamic>.from(pData['roles'])
        : {};

    // Couleur spéciale pour le top 3
    Color rankColor = Colors.white10;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.grey.shade400;
    if (rank == 3) rankColor = Colors.brown.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3 ? Border.all(color: rankColor.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            if (rank <= 3)
              Icon(Icons.emoji_events, color: rankColor.withOpacity(0.2), size: 40),
            CircleAvatar(
              backgroundColor: total > 0 ? Colors.orangeAccent : Colors.white10,
              radius: 18,
              child: Text("$total", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
        title: Row(
          children: [
            Text("#$rank ", style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(Player.formatName(name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
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
              Text(Player.formatName(name), style: const TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.bold)),
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

                    final rarityColor = ach.color;

                    // Générer les étoiles en fonction de la rareté
                    String stars = "⭐" * ach.rarity;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isUnlocked
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  rarityColor.withOpacity(0.15),
                                  rarityColor.withOpacity(0.05),
                                ],
                              )
                            : null,
                        color: isUnlocked ? null : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isUnlocked ? rarityColor.withOpacity(0.6) : Colors.white.withOpacity(0.05),
                            width: isUnlocked ? 2 : 1
                        ),
                        boxShadow: isUnlocked
                            ? [
                                BoxShadow(
                                  color: rarityColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icône du succès
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? rarityColor.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: isUnlocked
                                  ? Border.all(color: rarityColor.withOpacity(0.5), width: 1.5)
                                  : null,
                            ),
                            child: Text(
                              ach.icon,
                              style: TextStyle(
                                fontSize: 32,
                                color: isUnlocked ? null : Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Contenu du succès
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre + Badge de rareté
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ach.title,
                                        style: TextStyle(
                                          color: isUnlocked ? Colors.white : Colors.white24,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isUnlocked) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              rarityColor.withOpacity(0.3),
                                              rarityColor.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: rarityColor.withOpacity(0.7), width: 1),
                                        ),
                                        child: Text(
                                          ach.rarityLabel.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: rarityColor,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Étoiles de rareté
                                if (isUnlocked)
                                  Text(
                                    stars,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                const SizedBox(height: 8),
                                // Description
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.02),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isUnlocked
                                          ? rarityColor.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  child: Text(
                                    ach.description,
                                    style: TextStyle(
                                      color: isUnlocked ? Colors.white.withOpacity(0.85) : Colors.white10,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                // Date d'obtention
                                if (isUnlocked) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: rarityColor, size: 12),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Obtenu le $dateObtained",
                                        style: TextStyle(
                                          color: rarityColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.verified, color: rarityColor, size: 18),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
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