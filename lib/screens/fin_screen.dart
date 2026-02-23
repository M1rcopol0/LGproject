import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/achievement.dart';
import '../globals.dart';
import '../services/trophy_service.dart';
import '../logic/achievement_logic.dart';
import '../services/cloud_service.dart';
import '../player_storage.dart'; // Pour mettre à jour l'annuaire

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

    // Délai court pour laisser l'animation Fade se terminer (500ms) avant le calcul.
    Future.delayed(const Duration(milliseconds: 200), _processGameEnd);
  }

  Future<void> _processGameEnd() async {
    // Évite la double exécution si le widget se reconstruit ou n'est plus monté
    if (_hasProcessed || !mounted) return;
    _hasProcessed = true;

    final sw = Stopwatch()..start();
    debugPrint("⏱️ [GameOver] Début _processGameEnd (instance: ${identityHashCode(this)})");

    try {
      // 1. Identification des gagnants
      List<Player> activePlayers = widget.players.where((p) => p.isPlaying).toList();

      List<Player> computedWinners = activePlayers.where((p) {
        final role = p.role?.toUpperCase().trim() ?? "";
        final team = p.team.toLowerCase();

        switch (widget.winnerType) {
          case "VILLAGE":
            return team == "village" && !p.isFanOfRonAldo && !p.isAwayAsMJ;

          case "LOUPS-GAROUS":
          case "LOUPS": // Sécurité pour les deux formats
            return team == "loups" && !p.isAwayAsMJ;

          case "ARCHIVISTE":
            return role == "ARCHIVISTE" && team == "solo" && !p.isAwayAsMJ;

          case "RON-ALDO":
            return role == "RON-ALDO" || p.isFanOfRonAldo;

          case "DRESSEUR":
          case "POKÉMON":
          case "POKEMON":
          case "DRESSEUR_POKÉMON":
            return role == "DRESSEUR" || role == "POKÉMON" || role == "POKEMON";

          case "PHYL":
            return role == "PHYL";

          case "MAÎTRE DU TEMPS":
            return role == "MAÎTRE DU TEMPS";

          case "PANTIN":
            return role == "PANTIN";

          case "CHUCHOTEUR":
            return role == "CHUCHOTEUR";

          case "EXORCISTE":
          // L'Exorciste fait gagner tout le village
            return team == "village" && !p.isFanOfRonAldo && !p.isAwayAsMJ;

          default:
          // Cas par défaut (victoire solo spécifique)
            return role == widget.winnerType;
        }
      }).toList();

      // Dédoublonnage au cas où
      computedWinners = computedWinners.toSet().toList();
      if (mounted) setState(() => winners = computedWinners);

      debugPrint("⏱️ [GameOver] +${sw.elapsedMilliseconds}ms — Gagnants calculés : ${computedWinners.length}");

      // 1.5. Mise à jour de l'annuaire des joueurs (TOUJOURS, même en cas d'égalité)
      try {
        // Incrémenter gamesPlayed pour tous les joueurs qui ont participé
        for (var player in widget.players) {
          await PlayerDirectory.incrementGamesPlayed(player.name);
        }

        // Incrémenter wins pour les gagnants (seulement si pas d'égalité)
        if (widget.winnerType != "ÉGALITÉ_SANGUINAIRE" && computedWinners.isNotEmpty) {
          for (var winner in computedWinners) {
            await PlayerDirectory.incrementWins(winner.name);
          }
        }

        debugPrint("📂 LOG [GameOver] : Annuaire des joueurs mis à jour.");
        debugPrint("⏱️ [GameOver] +${sw.elapsedMilliseconds}ms — Annuaire mis à jour");
      } catch (e) {
        debugPrint("❌ LOG [GameOver] : Erreur lors de la mise à jour de l'annuaire : $e");
      }

      // 2. Enregistrement des statistiques et succès
      if (widget.winnerType != "ÉGALITÉ_SANGUINAIRE" && winners.isNotEmpty) {
        String roleGroup = "SOLO";
        if (widget.winnerType == "VILLAGE" || widget.winnerType == "EXORCISTE") roleGroup = "VILLAGE";
        if (widget.winnerType.contains("LOUPS")) roleGroup = "LOUPS-GAROUS";

        // Stats globales de la partie
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
          'parking_shot_global_flag': parkingShotUnlocked,
          'exorcisme_success_win': exorcistWin,
        };

        try {
          await TrophyService.recordWin(winners, roleGroup, customData: customStats);
          debugPrint("⏱️ [GameOver] +${sw.elapsedMilliseconds}ms — recordWin terminé");
        } catch (e) {
          debugPrint("❌ LOG [GameOver] : Erreur recordWin : $e");
        }

        try {
          await TrophyService.recordGamePlayed(activePlayers);
          debugPrint("⏱️ [GameOver] +${sw.elapsedMilliseconds}ms — recordGamePlayed terminé");
        } catch (e) {
          debugPrint("❌ LOG [GameOver] : Erreur recordGamePlayed : $e");
        }

        // Vérification des succès de fin de partie
        if (mounted) {
          try {
            await AchievementLogic.checkEndGameAchievements(context, winners, activePlayers);
            debugPrint("⏱️ [GameOver] +${sw.elapsedMilliseconds}ms — checkEndGameAchievements terminé");
          } catch (e) {
            debugPrint("❌ LOG [GameOver] : Erreur checkEndGameAchievements : $e");
          }
        }

        // Vérification des succès individuels pour chaque gagnant
        for (var winner in winners) {
          try {
            Map<String, dynamic> stats = await TrophyService.getStats();
            Map<String, dynamic> playerStats = stats[winner.name] ?? {};
            Map<String, dynamic> counters = playerStats['counters'] ?? {};

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
              'was_revived': winner.wasRevivedInThisGame,
              'totalVotesReceivedDuringGame': winner.totalVotesReceivedDuringGame,
              'hasBetrayedRonAldo': winner.hasBetrayedRonAldo,
              'dingo_shots_fired': winner.dingoShotsFired,
              'dingo_shots_hit': winner.dingoShotsHit,
              'dingo_self_voted_all_game': winner.dingoSelfVotedOnly,
              'parking_shot_achieved': (winner.role?.toLowerCase() == "dingo" && winner.parkingShotUnlocked),
              'chaman_sniper_achieved': chamanSniperAchieved && (winner.role?.toLowerCase() == "loup-garou chaman"),
              'canaclean_present': winner.canacleanPresent,
              'saved_by_own_quiche': winner.hasSavedSelfWithQuiche,
              'bled_protected_everyone': winner.protectedPlayersHistory.length >= (widget.players.length - 1),
              'devin_reveals_count': winner.devinRevealsCount,
              'devin_revealed_same_twice': winner.hasRevealedSamePlayerTwice,
              'traveler_killed_wolf': winner.travelerKilledWolf,
              'tardos_suicide': winner.tardosSuicide,
            };

            for (var ach in AchievementData.allAchievements) {
              if (mounted) {
                await TrophyService.checkAndUnlockImmediate(
                  context: context,
                  playerName: winner.name,
                  achievementId: ach.id,
                  checkData: checkData,
                );
              }
            }
          } catch (e) {
            debugPrint("❌ LOG [GameOver] : Erreur lors du check succès individuel pour ${winner.name}: $e");
          }
        }
        debugPrint("⏱️ [GameOver] +${sw.elapsedMilliseconds}ms — Succès individuels terminés (${winners.length} gagnants)");
      }

    } catch (globalError) {
      debugPrint("❌ ERREUR FATALE DANS GAMEOVER SCREEN : $globalError");
    } finally {
      debugPrint("⏱️ [GameOver] +${sw.elapsedMilliseconds}ms — Succès terminés → affichage écran");
      sw.stop();
      if (mounted) setState(() => _isLoading = false);
    }

    // 3. Sync cloud en arrière-plan (n'affecte pas le spinner)
    _syncCloudInBackground();
  }

  void _syncCloudInBackground() async {
    debugPrint("☁️ LOG [GameOver] : Sync cloud en arrière-plan...");
    try {
      bool syncSuccess = await CloudService.pushLocalToCloud(context);
      debugPrint("☁️ LOG [GameOver] : Sync cloud terminée (succès: $syncSuccess)");

      if (!syncSuccess && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("⚠️ Synchronisation Impossible"),
            content: const Text(
              "Pas de connexion internet.\n\n"
              "Les données de cette partie sont sauvegardées localement mais ne sont pas dans le cloud.\n\n"
              "Mettez à jour manuellement la backup cloud via Paramètres → Export/Import, "
              "sinon ces données seront perdues au prochain lancement de l'app."
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("J'ai compris"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ Erreur lors de la sync cloud (arrière-plan) : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = "";
    String message = "";
    Color themeColor = Colors.orangeAccent;
    IconData icon = Icons.emoji_events;

    // Normalisation du winnerType pour gérer les variantes
    String winKey = widget.winnerType.toUpperCase();
    if (winKey.contains("LOUP")) winKey = "LOUPS-GAROUS";
    if (winKey.contains("POKEMON") || winKey.contains("POKÉMON") || winKey.contains("DRESSEUR")) winKey = "DRESSEUR";

    switch (winKey) {
      case "VILLAGE":
        title = "VICTOIRE DU VILLAGE";
        message = "La paix revient enfin sur le village.";
        themeColor = Colors.greenAccent;
        icon = Icons.gite;
        break;

      case "EXORCISTE":
        title = "VICTOIRE DU VILLAGE";
        message = "L'Exorciste a purifié le mal !";
        themeColor = Colors.cyanAccent;
        icon = Icons.auto_awesome;
        break;

      case "LOUPS-GAROUS":
        title = "VICTOIRE DES LOUPS";
        message = "Le village a été dévoré...";
        themeColor = Colors.redAccent;
        icon = Icons.nights_stay;
        break;

      case "ARCHIVISTE":
        title = "HISTOIRE RÉÉCRITE";
        message = "L'Archiviste a supprimé tout le monde.";
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
        message = "L'ordre chronologique a été rétabli.";
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

      case "ÉGALITÉ_SANGUINAIRE":
        title = "ÉGALITÉ SANGUINAIRE";
        message = "Personne n'a survécu...";
        icon = Icons.dangerous;
        themeColor = Colors.grey;
        break;

      default:
        title = "VICTOIRE SOLITAIRE";
        message = "${widget.winnerType} a survécu à tous.";
        themeColor = Colors.grey;
    }

    // CORRECTION VISUELLE : PopScope remplace WillPopScope (déprécié)
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            // CORRECTION VISUELLE : Dégradé simplifié pour éviter la surcharge GPU
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [themeColor.withOpacity(0.3), const Color(0xFF0A0E21)],
            ),
          ),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: themeColor))
              : SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeColor.withOpacity(0.1),
                        border: Border.all(color: themeColor, width: 2),
                        // CORRECTION VISUELLE : Suppression du BoxShadow ici
                        // boxShadow: [BoxShadow(color: themeColor.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
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
                        // CORRECTION VISUELLE : Suppression des shadows sur le texte
                        // shadows: [Shadow(color: themeColor, blurRadius: 10)],
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
                          elevation: 5, // Réduction de l'élévation
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () async {
                          debugPrint("🏠 LOG [GameOver] : Reset de la partie et retour à l'accueil.");
                          globalGameSessionActive = false;
                          await resetAllGameData();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                          }
                        },
                        child: const Text("RETOUR À L'ACCUEIL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
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