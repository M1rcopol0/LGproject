import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/player.dart';
import 'models/achievement.dart'; // Import nécessaire pour le scan générique
import 'trophy_service.dart';
import 'globals.dart';

class AchievementLogic {
  static List<String> _traitorsThisTurn = [];
  static final Map<String, int> _shockTracker = {};

  // Suivi local pour "Un choix cornélien"
  static final Map<String, bool> _cornellienFailed = {};

  // ==========================================================
  // 1. MÉTHODE PUBLIQUE POUR VÉRIFICATION EN COURS DE JEU
  // ==========================================================

  static Future<void> checkMidGameAchievements(BuildContext context, List<Player> allPlayers) async {
    // On lance le scan avec winnerRole = null (partie pas finie)
    await _evaluateGenericAchievements(context, allPlayers, winnerRole: null);
  }

  // ==========================================================
  // 2. SCAN GÉNÉRIQUE DES SUCCÈS (Le Cœur du Système)
  // ==========================================================

  static Future<void> _evaluateGenericAchievements(BuildContext context, List<Player> allPlayers, {String? winnerRole}) async {
    debugPrint("🔍 CAPTEUR [Global Scan] : Début analyse. Vainqueur potentiel: $winnerRole");

    for (var p in allPlayers) {
      // 1. Construction de la fiche de stats
      Map<String, dynamic> stats = _buildPlayerStats(p, winnerRole, allPlayers);

      // --- LOGS DÉBOGAGE CIBLÉS ---
      if (p.role?.toLowerCase().contains("archiviste") == true && winnerRole != null) {
        debugPrint("🔍 CAPTEUR [Archiviste] ${p.name} :");
        debugPrint("   > Role Joueur: ${stats['player_role']}");
        debugPrint("   > Team Joueur: '${stats['team']}' (Attendu: 'solo')");
        debugPrint("   > Role Vainqueur: '$winnerRole' (Attendu: 'ARCHIVISTE' ou 'SOLO')");
      }

      if (p.role?.toLowerCase().contains("ron-aldo") == true || p.role?.toLowerCase().contains("maison") == true || p.wasMaisonConverted) {
        if (stats['ramenez_la_coupe'] == true) {
          debugPrint("🔍 CAPTEUR [Coupe Maison] ${p.name} : FLAG ACTIF (Succès devrait tomber)");
        }
      }

      if (winnerRole != null && p.isAlive) {
        bool valid = stats['choix_cornelien_valid'];
        if (!valid) {
          debugPrint("🔍 CAPTEUR [Cornélien] ${p.name} : ÉCHEC. Historique: ${p.votedAgainstHistory}");
        }
      }
      // -----------------------------

      // 2. Test de TOUTES les conditions
      for (var achievement in AchievementData.allAchievements) {
        try {
          if (achievement.checkCondition(stats)) {
            await TrophyService.checkAndUnlockImmediate(
              context: context,
              playerName: p.name,
              achievementId: achievement.id,
              checkData: {achievement.id: true},
            );
          }
        } catch (e) {
          // Ignorer les erreurs
        }
      }
    }
  }

  static Map<String, dynamic> _buildPlayerStats(Player p, String? winnerRole, List<Player> allPlayers) {
    bool hasDuplicateVotes = p.votedAgainstHistory.length != p.votedAgainstHistory.toSet().length;

    return {
      'player_role': p.role,
      'is_player_alive': p.isAlive,
      'winner_role': winnerRole,
      'turn_count': globalTurnNumber,
      'is_wolf_faction': p.team == "loups",
      'team': p.team,
      'roles': {
        'VILLAGE': p.team == "village" ? 1 : 0,
        'LOUPS-GAROUS': p.team == "loups" ? 1 : 0,
        'SOLO': p.team == "solo" ? 1 : 0,
      },
      'wolves_alive_count': allPlayers.where((pl) => pl.team == "loups" && pl.isAlive).length,
      'wolves_night_kills': wolvesNightKills,
      'no_friendly_fire_vote': !wolfVotedWolf,
      'evolved_hunger_achieved': evolvedHungerAchieved,
      'chaman_sniper_achieved': chamanSniperAchieved,
      'paradox_achieved': paradoxAchieved,
      'pokemon_died_t1': pokemonDiedTour1,
      'totalVotesReceivedDuringGame': p.totalVotesReceivedDuringGame,
      'somnifere_uses_left': p.somnifereUses,
      'dingo_shots_fired': p.dingoShotsFired,
      'dingo_shots_hit': p.dingoShotsHit,
      'dingo_self_voted_all_game': p.dingoSelfVotedOnly,
      'parking_shot_achieved': p.parkingShotUnlocked,
      'devin_reveals_count': p.devinRevealsCount,
      'devin_revealed_same_twice': p.hasRevealedSamePlayerTwice,
      'bled_protected_everyone': (p.protectedPlayersHistory.length >= (allPlayers.length - 1)),
      'saved_by_own_quiche': p.hasSavedSelfWithQuiche,
      'quiche_saved_count': quicheSavedThisNight,
      'houstonApollo13Triggered': p.houstonApollo13Triggered,
      'maison_hosted_wolf': false,
      'hosted_enemies_count': p.hostedEnemiesCount,
      'tardos_suicide': p.tardosSuicide,
      'traveler_killed_wolf': p.travelerKilledWolf,
      'was_revived': p.wasRevivedInThisGame,
      'pantinClutchTriggered': p.pantinClutchTriggered,
      'canaclean_present': p.canacleanPresent,
      'is_fan': p.isFanOfRonAldo,
      'ultimate_fan_action': false,
      'is_fan_sacrifice': false,
      'ramenez_la_coupe': p.wasMaisonConverted,
      'house_collapsed': false,
      'is_first_blood': false,
      'choix_cornelien_valid': p.isAlive && !hasDuplicateVotes,
    };
  }

  // ==========================================================
  // 3. ÉVÉNEMENTS DE FIN DE PARTIE
  // ==========================================================

  static Future<void> checkEndGameAchievements(BuildContext context, List<Player> winners, List<Player> allPlayers) async {
    if (winners.isEmpty) return;

    debugPrint("🏁 CAPTEUR [EndGame] : Calcul des succès de fin.");

    String winnerRole = "VILLAGE";
    if (winners.any((p) => p.team == "loups")) {
      winnerRole = "LOUPS-GAROUS";
    } else if (winners.any((p) => p.role?.toLowerCase() == "ron-aldo")) {
      winnerRole = "RON-ALDO";
    } else if (winners.any((p) => p.team == "solo")) {
      if (winners.any((p) => p.role?.toLowerCase() == "dresseur" || p.role?.toLowerCase() == "pokémon")) {
        winnerRole = "DRESSEUR";
      } else if (winners.any((p) => p.role?.toLowerCase() == "maître du temps")) {
        winnerRole = "MAÎTRE DU TEMPS";
      } else if (winners.any((p) => p.role?.toLowerCase() == "phyl")) {
        winnerRole = "PHYL";
      } else if (winners.any((p) => p.role?.toLowerCase() == "archiviste")) {
        winnerRole = "ARCHIVISTE";
      } else {
        winnerRole = winners.first.role?.toUpperCase() ?? "SOLO";
      }
    }

    debugPrint("🏆 CAPTEUR [EndGame] : WinnerRole déduit -> $winnerRole");

    await _evaluateGenericAchievements(context, allPlayers, winnerRole: winnerRole);

    for (var p in winners) {
      await _safeUnlock(p.name, "first_win");
      if (p.team == "village") await _safeUnlock(p.name, "village_hero");
      if (p.team == "loups") await _safeUnlock(p.name, "wolf_pack");
      if (p.team == "solo") await _safeUnlock(p.name, "lone_wolf");
    }

    for (var p in allPlayers) {
      if (p.role?.toLowerCase() == "archiviste") {
        await checkArchivisteEndGame(context, p);
      }
      if (p.role?.toLowerCase() == "dresseur" && winnerRole == "DRESSEUR") {
        try {
          var pokemon = allPlayers.firstWhere((pl) => pl.role?.toLowerCase() == "pokémon" || pl.role?.toLowerCase() == "pokemon", orElse: () => Player(name: "Unknown", isAlive: true));
          if (pokemon.name != "Unknown" && !pokemon.isAlive) {
            await TrophyService.unlockAchievement(p.name, "master_no_pokemon");
          }
        } catch (_) {}
      }
    }
  }

  static Future<void> _safeUnlock(String name, String id) async {
    try {
      await TrophyService.unlockAchievement(name, id);
    } catch (_) {}
  }

  // ==========================================================
  // 4. ÉVÉNEMENTS MANUELS
  // ==========================================================

  static void trackVote(Player voter, Player target) {
    debugPrint("🗳️ CAPTEUR [Vote] : ${voter.name} vote pour ${target.name}.");
    voter.votedAgainstHistory.add(target.name);
    debugPrint("   > Historique actuel: ${voter.votedAgainstHistory}");
  }

  static void checkDeathAchievements(BuildContext? context, Player victim, List<Player> allPlayers) {
    final roleLower = victim.role?.toLowerCase() ?? "";

    if ((roleLower == "pokémon" || roleLower == "pokemon") && globalTurnNumber == 1) {
      if (context != null) {
        TrophyService.checkAndUnlockImmediate(context: context, playerName: victim.name, achievementId: "pokemon_fail", checkData: {'pokemon_died_t1': true, 'player_role': 'Pokémon'});
      } else {
        _safeUnlock(victim.name, "pokemon_fail");
      }
    }

    if (roleLower == "maison" && globalTurnNumber == 1) {
      if (context != null) {
        TrophyService.checkAndUnlockImmediate(context: context, playerName: victim.name, achievementId: "house_fast_death", checkData: {'turn_count': 1, 'player_role': 'Maison', 'death_cause': 'direct_hit'});
      }
    }
  }

  static void checkHouseCollapse(BuildContext context, Player houseOwner) {
    TrophyService.checkAndUnlockImmediate(context: context, playerName: houseOwner.name, achievementId: "house_collapse", checkData: {'house_collapsed': true});
  }

  static void checkFirstBlood(BuildContext context, Player victim) {
    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      TrophyService.checkAndUnlockImmediate(context: context, playerName: victim.name, achievementId: "first_blood", checkData: {'is_first_blood': true});
    }
  }

  static void recordRevive(Player revivedPlayer) {
    if (revivedPlayer.role?.toLowerCase().contains("pok") == true) {
      revivedPlayer.wasRevivedInThisGame = true;
    }
  }

  static void checkApollo13(BuildContext context, Player houston, Player p1, Player p2) {
    bool teamsAreDifferent = (p1.team != p2.team);
    if (teamsAreDifferent) {
      bool p1NotVillage = p1.team != "village";
      bool p2NotVillage = p2.team != "village";
      if (p1NotVillage && p2NotVillage) {
        houston.houstonApollo13Triggered = true;
        debugPrint("🚀 CAPTEUR [Achievement] : APOLLO 13 validé pour ${houston.name} !");
        TrophyService.checkAndUnlockImmediate(context: context, playerName: houston.name, achievementId: "apollo_13", checkData: {'houstonApollo13Triggered': true});
      }
    }
  }

  static void checkParkingShot(BuildContext? context, Player dingo, Player victim, List<Player> allPlayers) {
    if (dingo.role?.toLowerCase() != "dingo") return;
    bool isEnemy = (victim.team == "loups" || victim.team == "solo");
    if (isEnemy) {
      bool otherEnemiesAlive = allPlayers.any((p) => p.isAlive && p.name != victim.name && p.name != dingo.name && (p.team == "loups" || p.team == "solo"));
      if (!otherEnemiesAlive) {
        debugPrint("🎯 CAPTEUR [Achievement] : Condition Tir du Parking remplie.");
        dingo.parkingShotUnlocked = true;
        parkingShotUnlocked = true;
        if (context != null) {
          TrophyService.checkAndUnlockImmediate(context: context, playerName: dingo.name, achievementId: "parking_shot", checkData: {'parking_shot_achieved': true});
        }
      }
    }
  }

  static void checkParkingShotCondition(Player dingo, Player victim, List<Player> allPlayers) {
    checkParkingShot(null, dingo, victim, allPlayers);
  }

  // --- CORRECTION CRITIQUE : FAN ULTIME ---
  static void checkFanSacrifice(BuildContext context, Player victim, Player savedPlayer) {
    bool isFan = victim.isFanOfRonAldo;
    bool isRonAldoSaved = savedPlayer.role?.toLowerCase() == "ron-aldo";

    if (isFan && isRonAldoSaved) {
      // 1. Succès Garde du Corps (Toujours vrai si sacrifice)
      TrophyService.checkAndUnlockImmediate(
        context: context,
        playerName: victim.name,
        achievementId: "fan_sacrifice",
        checkData: {'sacrificed': true},
      );

      debugPrint("🛡️ CAPTEUR [Sacrifice] : ${victim.name} (Fan) s'est sacrifié.");

      // 2. Succès Fan Ultime :
      // La condition est : Le FAN (Victim) a voté contre RON-ALDO (SavedPlayer)
      // C'est ce qui constitue la "trahison pardonnée" par le sacrifice.
      bool fanVotedAgainstRonAldo = false;
      if (victim.targetVote != null && victim.targetVote!.name == savedPlayer.name) {
        fanVotedAgainstRonAldo = true;
      }

      if (fanVotedAgainstRonAldo) {
        debugPrint("🏆 CAPTEUR [Fan Ultime] : ${victim.name} a trahi Ron-Aldo puis est mort pour lui !");
        TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: victim.name,
          achievementId: "ultimate_fan",
          checkData: {'ultimate_fan_action': true},
        );
      } else {
        debugPrint("ℹ️ CAPTEUR [Fan Ultime] : Echec. Le fan n'avait pas voté contre Ron-Aldo (${victim.targetVote?.name}).");
      }
    }
  }

  static void checkEvolvedHunger(BuildContext context, Player votedPlayer, List<Player> allPlayers) {
    if (votedPlayer.hasSurvivedWolfBite) {
      evolvedHungerAchieved = true;
      debugPrint("🩸 CAPTEUR [Achievement] : Condition Fringale Nocturne remplie.");
      for (var p in allPlayers) {
        if (p.team == "loups") {
          TrophyService.checkAndUnlockImmediate(context: context, playerName: p.name, achievementId: "evolved_hunger", checkData: {'is_wolf_faction': true, 'evolved_hunger_achieved': true});
        }
      }
      _evaluateGenericAchievements(context, allPlayers);
    }
  }

  static void checkDevinAchievements(BuildContext context, Player devin) {
    if (devin.hasRevealedSamePlayerTwice) {
      TrophyService.checkAndUnlockImmediate(context: context, playerName: devin.name, achievementId: "double_check_devin", checkData: {'devin_revealed_same_twice': true});
    }
  }

  static void checkBledAchievements(BuildContext context, Player bled, int totalPlayers) {
    if (bled.protectedPlayersHistory.length >= (totalPlayers - 1)) {
      TrophyService.checkAndUnlockImmediate(context: context, playerName: bled.name, achievementId: "bled_all_covered", checkData: {'bled_protected_everyone': true});
    }
  }

  static void checkCanacleanCondition(BuildContext? context, List<Player> players) {
    const requiredNames = ["Clara", "Gabriel", "Jean", "Marc"];
    for (var p in players.where((p) => p.isAlive)) {
      List<Player> mates = players.where((target) => requiredNames.contains(target.name)).toList();
      if (mates.length == 4) {
        bool allSameTeamAndAlive = mates.every((m) => m.team == p.team && m.isAlive);
        if (allSameTeamAndAlive) {
          p.canacleanPresent = true;
          if (context != null) {
            TrophyService.checkAndUnlockImmediate(context: context, playerName: p.name, achievementId: "canaclean", checkData: {'canaclean_present': true});
          }
        }
      }
    }
  }

  static void checkWelcomeWolf(BuildContext context, Player maison) {
    TrophyService.checkAndUnlockImmediate(context: context, playerName: maison.name, achievementId: "welcome_wolf", checkData: {'maison_hosted_wolf': true});
  }

  static void checkTraitorFan(BuildContext context, Player voter, Player target) {
    final targetRole = target.role?.toUpperCase().trim() ?? "";
    if (voter.isFanOfRonAldo && (targetRole == "RON-ALDO" || targetRole == "RON ALDO")) {
      if (!_traitorsThisTurn.contains(voter.name)) {
        _traitorsThisTurn.add(voter.name);
        debugPrint("🐍 CAPTEUR [Achievement] : Fan Traître détecté -> ${voter.name}");
      }
    }
  }

  static void checkTardosOups(BuildContext context, Player tardos) {
    if (tardos.tardosSuicide) {
      TrophyService.checkAndUnlockImmediate(context: context, playerName: tardos.name, achievementId: "tardos_oups", checkData: {'tardos_suicide': true});
    }
  }

  static void checkClutchManual(BuildContext context, Player pantin) {
    TrophyService.checkAndUnlockImmediate(context: context, playerName: pantin.name, achievementId: "pantin_clutch", checkData: {'pantin_clutch_triggered': true});
  }

  static Future<void> checkArchivisteEndGame(BuildContext context, Player p) async {
    if (p.role?.toLowerCase() != "archiviste") return;
    const Set<String> requiredPowers = {"mute", "cancel_vote", "scapegoat", "transcendance_start"};
    final Set<String> usedThisGame = p.archivisteActionsUsed.toSet();

    debugPrint("📚 CAPTEUR [Archiviste] : Pouvoirs utilisés par ${p.name}: $usedThisGame");

    if (usedThisGame.containsAll(requiredPowers)) {
      await TrophyService.checkAndUnlockImmediate(context: context, playerName: p.name, achievementId: "archiviste_king", checkData: {'archiviste_king_qualified': true});
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String historyKey = "archiviste_powers_history_${p.name}";
      List<String> historyList = prefs.getStringList(historyKey) ?? [];
      Set<String> historySet = historyList.toSet();
      historySet.addAll(usedThisGame);
      await prefs.setStringList(historyKey, historySet.toList());
      if (historySet.containsAll(requiredPowers)) {
        await TrophyService.checkAndUnlockImmediate(context: context, playerName: p.name, achievementId: "archiviste_prince", checkData: {'archiviste_prince_qualified': true});
      }
    } catch (e) { debugPrint("⚠️ Erreur check Prince du CDI : $e"); }
  }

  static void updateVoyageur(Player voyageur) {
    if (voyageur.isInTravel) {
      voyageur.travelNightsCount++;
      if (voyageur.travelNightsCount % 2 == 0) {
        voyageur.travelerBullets++;
      }
    }
  }

  static void recordPhylChange(Player phyl) {
    phyl.roleChangesCount++;
  }

  static void clearTurnData() {
    _traitorsThisTurn.clear();
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
  }

  static void resetFullGameData() {
    debugPrint("🔄 LOG [Achievement] : RESET COMPLET DES SUCCÈS.");
    _traitorsThisTurn.clear();
    _shockTracker.clear();
    _cornellienFailed.clear();
    anybodyDeadYet = false;
    pokemonDiedTour1 = false;
    chamanSniperAchieved = false;
    evolvedHungerAchieved = false;
    pantinClutchSave = false;
    paradoxAchieved = false;
    fanSacrificeAchieved = false;
    ultimateFanAchieved = false;
    parkingShotUnlocked = false;
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
  }
}