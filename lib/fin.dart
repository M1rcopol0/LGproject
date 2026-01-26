import 'package:flutter/material.dart';
import 'models/player.dart';
import 'models/achievement.dart';
import 'globals.dart';
import 'trophy_service.dart';
import 'achievement_logic.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GameOverScreen extends StatefulWidget {
  final String winnerType;
  final List<Player> players;

  const GameOverScreen({
    super.key,
    required this.winnerType,
    required this.players,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  List<Player> winners = [];
  bool _isLoading = true;
  bool _hasProcessed = false;

  @override
  void initState() {
    super.initState();
    debugPrint("🏁 LOG [GameOver] : Arrivée sur l'écran de fin. Vainqueur annoncé : ${widget.winnerType}");
    _processGameEnd();
  }

  Future<void> _processGameEnd() async {
    if (_hasProcessed) return;
    _hasProcessed = true;

    // 1. Filtrage des joueurs actifs
    List<Player> activePlayers = widget.players.where((p) => p.isPlaying).toList();

    // 2. Détermination des Vainqueurs
    List<Player> computedWinners = activePlayers.where((p) {
      final role = p.role?.toUpperCase().trim() ?? "";
      final team = p.team.toLowerCase();

      switch (widget.winnerType) {
        case "VILLAGE":
          return team == "village" && !p.isFanOfRonAldo;
        case "LOUPS-GAROUS":
          return team == "loups";
        case "ARCHIVISTE":
          return role == "ARCHIVISTE" && team == "solo";
        case "RON-ALDO":
          return role == "RON-ALDO" || p.isFanOfRonAldo;
        case "DRESSEUR":
        case "POKÉMON":
        case "DRESSEUR_POKÉMON":
          return role == "DRESSEUR" || role == "POKÉMON";
        case "PHYL":
          return role == "PHYL";
        case "MAÎTRE DU TEMPS":
          return role == "MAÎTRE DU TEMPS";
        case "PANTIN":
          return role == "PANTIN";
        case "CHUCHOTEUR":
          return role == "CHUCHOTEUR";
        default:
          return role == widget.winnerType;
      }
    }).toList();

    computedWinners = computedWinners.toSet().toList();
    debugPrint("🏆 LOG [GameOver] : Nombre de vainqueurs identifiés : ${computedWinners.length}");

    if (mounted) {
      setState(() => winners = computedWinners);
    }

    // 3. Traitement des Succès et Statistiques
    if (widget.winnerType != "ÉGALITÉ_SANGUINAIRE" && winners.isNotEmpty) {
      String roleGroup = "SOLO";
      if (widget.winnerType == "VILLAGE") roleGroup = "VILLAGE";
      if (widget.winnerType == "LOUPS-GAROUS") roleGroup = "LOUPS-GAROUS";

      // Stats globales pour l'historique
      Map<String, dynamic> customStats = {
        'winner_role': widget.winnerType,
        'turn_count': globalTurnNumber,
        'pokemon_died_t1': pokemonDiedTour1,
        'pantin_clutch_save': pantinClutchSave,
        'paradox_achieved': paradoxAchieved,
        'fan_sacrifice_achieved': fanSacrificeAchieved,
        'ultimate_fan_achieved': ultimateFanAchieved,
        'wolves_alive_count': activePlayers.where((p) => p.team == "loups" && p.isAlive).length,
        'no_friendly_fire_vote': !wolfVotedWolf,
        'first_dead_name': firstDeadPlayerName,
        'chaman_sniper_achieved': chamanSniperAchieved,
        'evolved_hunger_achieved': evolvedHungerAchieved,
        'wolves_night_kills': wolvesNightKills,
        'quiche_saved_count': quicheSavedThisNight,
        'parking_shot_global_flag': parkingShotUnlocked, // Juste pour l'info globale
      };

      debugPrint("📊 LOG [GameOver] : Statistiques globales enregistrées.");
      await TrophyService.recordWin(winners, roleGroup, customData: customStats);

      for (var winner in winners) {
        Map<String, dynamic> stats = await TrophyService.getStats();
        Map<String, dynamic> playerStats = stats[winner.name] ?? {};
        Map<String, dynamic> counters = playerStats['counters'] ?? {};

        // Données spécifiques au joueur pour checking des succès
        Map<String, dynamic> checkData = {
          ...playerStats,
          ...counters,
          ...customStats,
          'player_name': winner.name,
          'player_role': winner.role,
          'is_player_alive': winner.isAlive,
          'is_fan': winner.isFanOfRonAldo,
          'is_wolf_faction': winner.team == "loups",
          'somnifere_uses_left': winner.somnifereUses,
          'roleChangesCount': winner.roleChangesCount,
          'mutedPlayersCount': winner.mutedPlayersCount,
          'max_simultaneous_curses': winner.maxSimultaneousCurses,
          'was_revived': winner.wasRevivedInThisGame,
          'totalVotesReceivedDuringGame': winner.totalVotesReceivedDuringGame,
          'hasBetrayedRonAldo': winner.hasBetrayedRonAldo,

          // --- LOGIQUE DINGO SPÉCIFIQUE ---
          'dingo_shots_fired': winner.dingoShotsFired,
          'dingo_shots_hit': winner.dingoShotsHit,
          'dingo_self_voted_all_game': winner.dingoSelfVotedOnly,
          // Correction : On utilise le flag personnel et non global
          'parking_shot_achieved': (winner.role?.toLowerCase() == "dingo" && winner.parkingShotUnlocked),

          // --- LOGIQUE CANACLEAN ---
          'canaclean_present': winner.canacleanPresent,

          // --- LOGIQUE ARCHIVISTE ---
          'archiviste_all_powers_used_in_game': winner.archivisteActionsUsed.toSet().length >= 4,
          'archiviste_all_powers_cumulated': (counters['archiviste_actions_all_time']?.length ?? 0) >= 4,
          'bled_protected_everyone': winner.mutedPlayersCount >= (activePlayers.length - 1),

          // --- LOGIQUE GRAND-MÈRE CORRIGÉE ---
          // On utilise le flag hasSavedSelfWithQuiche calculé dans la NightLogic
          'saved_by_own_quiche': winner.hasSavedSelfWithQuiche,
        };

        debugPrint("🔍 LOG [GameOver] : Check ${winner.name} -> DingoPark=${checkData['parking_shot_achieved']} | QuicheSelf=${checkData['saved_by_own_quiche']}");

        for (var ach in AchievementData.allAchievements) {
          try {
            if (ach.checkCondition(checkData)) {
              bool isNew = await TrophyService.unlockAchievement(winner.name, ach.id);
              if (isNew && mounted) {
                debugPrint("🎁 LOG [GameOver] : SUCCÈS DÉBLOQUÉ -> ${ach.id} (${winner.name})");
                TrophyService.showAchievementPopup(context, ach.title, ach.icon, winner.name);
              }
            }
          } catch (e) {
            debugPrint("❌ LOG [GameOver] : Erreur check succès ${ach.id}: $e");
          }
        }
      }

      if (firstDeadPlayerName != null) {
        await TrophyService.unlockAchievement(firstDeadPlayerName!, "first_blood");
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "";
    String message = "";
    Color themeColor = Colors.orangeAccent;
    IconData icon = Icons.emoji_events;

    switch (widget.winnerType) {
      case "VILLAGE":
        title = "VICTOIRE DU VILLAGE";
        message = "La paix revient enfin sur le village.";
        themeColor = Colors.greenAccent;
        icon = Icons.gite;
        break;
      case "LOUPS-GAROUS":
        title = "VICTOIRE DES LOUPS";
        message = "Le village a été dévoré...";
        themeColor = Colors.redAccent;
        icon = Icons.nights_stay;
        break;
      case "ARCHIVISTE":
        title = "HISTOIRE RÉÉCRITE";
        message = "L'Archiviste a supprimé tout le monde des registres.";
        themeColor = Colors.brown;
        icon = Icons.auto_stories;
        break;
      case "RON-ALDO":
        title = "SIUUUUUU !";
        message = "Ron-Aldo et ses fans règnent sans partage.";
        themeColor = Colors.orange;
        icon = Icons.star;
        break;
      case "DRESSEUR":
      case "POKÉMON":
      case "DRESSEUR_POKÉMON":
        title = "MAÎTRE POKÉMON !";
        message = "Le duo légendaire a triomphé !";
        themeColor = Colors.blueAccent;
        icon = Icons.catching_pokemon;
        break;
      case "PHYL":
        title = "USURPATION TOTALE";
        message = "Phyl a effacé toutes les autres identités.";
        themeColor = Colors.deepPurpleAccent;
        icon = Icons.fingerprint;
        break;
      case "MAÎTRE DU TEMPS":
        title = "TEMPS ÉCOULÉ";
        message = "L'ordre chronologique a été rétabli par le vide.";
        themeColor = Colors.cyanAccent;
        icon = Icons.hourglass_bottom;
        break;
      case "PANTIN":
        title = "SPECTACLE TERMINÉ";
        message = "Le Pantin a coupé les fils de tout le monde.";
        themeColor = Colors.pinkAccent;
        icon = Icons.theater_comedy;
        break;
      case "CHUCHOTEUR":
        title = "SILENCE ABSOLU";
        message = "Le Chuchoteur a eu le dernier mot.";
        themeColor = Colors.blueGrey;
        icon = Icons.volume_off;
        break;
      default:
        title = "VICTOIRE SOLITAIRE";
        message = "${widget.winnerType} a survécu à tous.";
        if (widget.winnerType == "ÉGALITÉ_SANGUINAIRE") {
          title = "ÉGALITÉ SANGUINAIRE";
          message = "Personne n'a survécu...";
          icon = Icons.dangerous;
        }
        themeColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [themeColor.withOpacity(0.3), const Color(0xFF0A0E21), const Color(0xFF0A0E21)],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: themeColor))
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withOpacity(0.1),
                    border: Border.all(color: themeColor, width: 2),
                    boxShadow: [BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                  ),
                  child: Icon(icon, size: 80, color: themeColor),
                ),
                const SizedBox(height: 30),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: themeColor,
                    letterSpacing: 2,
                    shadows: [Shadow(color: themeColor, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 50),
                if (winners.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(child: Divider(color: themeColor.withOpacity(0.5))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("VAINQUEURS (+1 PT)", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                      Expanded(child: Divider(color: themeColor.withOpacity(0.5))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: winners.map((p) => _buildWinnerChip(p, themeColor)).toList(),
                  ),
                ] else if (widget.winnerType != "ÉGALITÉ_SANGUINAIRE") ...[
                  const Text("Erreur : Aucun vainqueur identifié.", style: TextStyle(color: Colors.red)),
                ] else ...[
                  const Text("Aucun survivant.", style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold))
                ],
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.black,
                      elevation: 10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      debugPrint("🏠 LOG [GameOver] : Reset de la partie et retour à l'accueil.");
                      resetAllGameData();
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    },
                    child: const Text("RETOUR À L'ACCUEIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerChip(Player p, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          if (p.role != null) Text(p.role!, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}