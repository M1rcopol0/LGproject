import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../services/trophy_service.dart';
import '../globals.dart';
import 'achievement_scanner.dart';

class AchievementEvents {

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

  static void checkFanSacrifice(BuildContext context, Player victim, Player savedPlayer) {
    bool isFan = victim.isFanOfRonAldo;
    bool isRonAldoSaved = savedPlayer.role?.toLowerCase() == "ron-aldo";

    if (isFan && isRonAldoSaved) {
      TrophyService.checkAndUnlockImmediate(
        context: context,
        playerName: victim.name,
        achievementId: "fan_sacrifice",
        checkData: {'sacrificed': true},
      );

      debugPrint("🛡️ CAPTEUR [Sacrifice] : ${victim.name} (Fan) s'est sacrifié.");

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
      AchievementScanner.evaluateGenericAchievements(context, allPlayers);
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
      debugPrint("🐍 CAPTEUR [Achievement] : Fan Traître détecté -> ${voter.name}");
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

  static Future<void> _safeUnlock(String name, String id) async {
    try {
      await TrophyService.unlockAchievement(name, id);
    } catch (_) {}
  }
}
