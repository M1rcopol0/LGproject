import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/player.dart';
import 'trophy_service.dart';
import 'globals.dart';

class AchievementLogic {
  static List<String> _traitorsThisTurn = [];
  static final Map<String, int> _shockTracker = {};

  // ==========================================================
  // 1. ÉVÉNEMENTS DE FIN DE PARTIE (VICTOIRE)
  // ==========================================================

  static void checkEndGameAchievements(BuildContext context, List<Player> winners, List<Player> allPlayers) {
    if (winners.isEmpty) return;

    for (var p in winners) {
      _safeUnlock(p.name, "first_win");

      if (p.team == "village") _safeUnlock(p.name, "village_hero");
      if (p.team == "loups") _safeUnlock(p.name, "wolf_pack");
      if (p.team == "solo") _safeUnlock(p.name, "lone_wolf");

      if (p.role?.toLowerCase() == "dresseur") {
        try {
          var pokemon = allPlayers.firstWhere(
                  (pl) => pl.role?.toLowerCase() == "pokémon" || pl.role?.toLowerCase() == "pokemon",
              orElse: () => Player(name: "Unknown", isAlive: true)
          );
          if (pokemon.name != "Unknown" && !pokemon.isAlive) {
            TrophyService.unlockAchievement(p.name, "master_no_pokemon");
          }
        } catch (e) {
          debugPrint("⚠️ Erreur check Maître sans Pokémon : $e");
        }
      }

      if (p.role?.toLowerCase() == "dingo" && (p.parkingShotUnlocked || parkingShotUnlocked)) {
        debugPrint("🎯 LOG [Achievement] : Tir du Parking confirmé par la victoire !");
        TrophyService.unlockAchievement(p.name, "parking_shot");
      }
    }

    // Vérification spéciale Archiviste en fin de partie
    for (var p in allPlayers) {
      if (p.role?.toLowerCase() == "archiviste") {
        checkArchivisteEndGame(context, p);
      }
    }
  }

  static void _safeUnlock(String name, String id) {
    try {
      TrophyService.unlockAchievement(name, id);
    } catch (_) {}
  }

  // ==========================================================
  // 2. ÉVÉNEMENTS DE MORT ET RÉSILIENCE
  // ==========================================================

  static void checkDeathAchievements(BuildContext? context, Player victim, List<Player> allPlayers) {
    final roleLower = victim.role?.toLowerCase() ?? "";

    if ((roleLower == "pokémon" || roleLower == "pokemon") && globalTurnNumber == 1) {
      if (context != null) {
        TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: victim.name,
          achievementId: "pokemon_fail",
          checkData: {'pokemon_died_t1': true, 'player_role': 'Pokémon'},
        );
      } else {
        _safeUnlock(victim.name, "pokemon_fail");
      }
    }

    if (roleLower == "maison" && globalTurnNumber == 1) {
      if (context != null) {
        TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: victim.name,
          achievementId: "house_fast_death",
          checkData: {'turn_count': 1, 'player_role': 'Maison', 'death_cause': 'direct_hit'},
        );
      }
    }
  }

  static void checkHouseCollapse(Player houseOwner) {
    _safeUnlock(houseOwner.name, "house_collapse");
  }

  static void checkFirstBlood(Player victim) {
    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      _safeUnlock(victim.name, "first_blood");
    }
  }

  static void recordRevive(Player revivedPlayer) {
    if (revivedPlayer.role?.toLowerCase() == "pokémon" || revivedPlayer.role?.toLowerCase() == "pokemon") {
      revivedPlayer.wasRevivedInThisGame = true;
    }
  }

  // ==========================================================
  // 3. ACTIONS DE JEU AVEC POP-UP IMMÉDIAT
  // ==========================================================

  static void checkApollo13(BuildContext context, Player houston, Player p1, Player p2) {
    bool teamsAreDifferent = (p1.team != p2.team);

    if (teamsAreDifferent) {
      bool p1NotVillage = p1.team != "village";
      bool p2NotVillage = p2.team != "village";

      if (p1NotVillage && p2NotVillage) {
        houston.houstonApollo13Triggered = true;
        debugPrint("🚀 LOG [Achievement] : APOLLO 13 validé pour ${houston.name} !");

        TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: houston.name,
          achievementId: "apollo_13",
          checkData: {'houstonApollo13Triggered': true},
        );
      }
    }
  }

  static void checkParkingShot(BuildContext? context, Player dingo, Player victim, List<Player> allPlayers) {
    if (dingo.role?.toLowerCase() != "dingo") return;

    bool isEnemy = (victim.team == "loups" || victim.team == "solo");

    if (isEnemy) {
      bool otherEnemiesAlive = allPlayers.any((p) =>
      p.isAlive &&
          p.name != victim.name &&
          p.name != dingo.name &&
          (p.team == "loups" || p.team == "solo")
      );

      if (!otherEnemiesAlive) {
        debugPrint("🎯 LOG [Achievement] : Condition Tir du Parking remplie (Dernier ennemi abattu).");
        dingo.parkingShotUnlocked = true;
        parkingShotUnlocked = true;
      }
    }
  }

  static void checkParkingShotCondition(Player dingo, Player victim, List<Player> allPlayers) {
    checkParkingShot(null, dingo, victim, allPlayers);
  }

  static void checkFanSacrifice(BuildContext context, Player deadFan, Player ronAldo) {
    if (deadFan.isFanOfRonAldo) {
      if (ronAldo.isAlive) {
        fanSacrificeAchieved = true;
        TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: deadFan.name,
          achievementId: "fan_sacrifice",
          checkData: {'is_fan_sacrifice': true},
        );
      }
    }
  }

  static void checkEvolvedHunger(BuildContext? context, Player votedPlayer) {
    if (nightWolvesTarget != null &&
        votedPlayer.name == nightWolvesTarget!.name &&
        nightWolvesTargetSurvived) {
      evolvedHungerAchieved = true;
    }
  }

  static void checkDevinAchievements(BuildContext context, Player devin) {
    if (devin.hasRevealedSamePlayerTwice) {
      TrophyService.checkAndUnlockImmediate(
        context: context,
        playerName: devin.name,
        achievementId: "double_check_devin",
        checkData: {'devin_revealed_same_twice': true},
      );
    }
  }

  static void checkBledAchievements(BuildContext context, Player bled, int totalPlayers) {
    if (bled.protectedPlayersHistory.length >= (totalPlayers - 1)) {
      TrophyService.checkAndUnlockImmediate(
        context: context,
        playerName: bled.name,
        achievementId: "bled_all_covered",
        checkData: {'bled_protected_everyone': true},
      );
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
            TrophyService.checkAndUnlockImmediate(
              context: context,
              playerName: p.name,
              achievementId: "canaclean",
              checkData: {'canaclean_present': true},
            );
          }
        }
      }
    }
  }

  static void checkWelcomeWolf(BuildContext context, Player maison) {
    TrophyService.checkAndUnlockImmediate(
      context: context,
      playerName: maison.name,
      achievementId: "welcome_wolf",
      checkData: {'maison_hosted_wolf': true},
    );
  }

  static void checkTraitorFan(BuildContext context, Player voter, Player target) {
    final targetRole = target.role?.toUpperCase().trim() ?? "";
    if (voter.isFanOfRonAldo && (targetRole == "RON-ALDO" || targetRole == "RON ALDO")) {
      if (!_traitorsThisTurn.contains(voter.name)) {
        _traitorsThisTurn.add(voter.name);
        debugPrint("🐍 LOG [Achievement] : Fan Traître détecté -> ${voter.name}");
      }
    }
  }

  static void checkTardosOups(BuildContext context, Player tardos) {
    if (tardos.tardosSuicide) {
      TrophyService.checkAndUnlockImmediate(
        context: context,
        playerName: tardos.name,
        achievementId: "tardos_oups",
        checkData: {'tardos_suicide': true},
      );
    }
  }

  // --- MÉTHODE SPÉCIALE CLUTCH PANTIN ---
  static void checkClutchManual(BuildContext context, Player pantin) {
    TrophyService.checkAndUnlockImmediate(
      context: context,
      playerName: pantin.name,
      achievementId: "pantin_clutch",
      checkData: {'pantin_clutch_triggered': true},
    );
  }

  // --- ARCHIVISTE : ROI & PRINCE ---
  static void checkArchivisteEndGame(BuildContext context, Player p) async {
    if (p.role?.toLowerCase() != "archiviste") return;

    // Liste des actions attendues
    const Set<String> requiredPowers = {
      "mute",
      "cancel_vote",
      "scapegoat",
      "transcendance_start"
    };

    final Set<String> usedThisGame = p.archivisteActionsUsed.toSet();

    // 1. LE ROI DU CDI
    if (usedThisGame.containsAll(requiredPowers)) {
      TrophyService.checkAndUnlockImmediate(
        context: context,
        playerName: p.name,
        achievementId: "archiviste_king",
        checkData: {'archiviste_king_qualified': true},
      );
    }

    // 2. LE PRINCE DU CDI (Cumulatif)
    try {
      final prefs = await SharedPreferences.getInstance();
      const String historyKey = "archiviste_powers_history";

      List<String> historyList = prefs.getStringList(historyKey) ?? [];
      Set<String> historySet = historyList.toSet();

      // On ajoute les nouvelles actions
      historySet.addAll(usedThisGame);
      await prefs.setStringList(historyKey, historySet.toList());

      // Vérification
      if (historySet.containsAll(requiredPowers)) {
        TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: p.name,
          achievementId: "archiviste_prince",
          checkData: {'archiviste_prince_qualified': true},
        );
      }
    } catch (e) {
      debugPrint("⚠️ Erreur check Prince du CDI : $e");
    }
  }

  // --- UTILITAIRES SANS POP-UP IMMÉDIAT (Stats) ---

  static void updateVoyageur(Player voyageur) {
    if (voyageur.isInTravel) {
      voyageur.travelNightsCount++;
      if (voyageur.travelNightsCount % 2 == 0) {
        voyageur.travelerBullets++;
      }
    }
  }

  static void checkPantinCurses(List<Player> players) {
    int cursedCount = players.where((p) => p.isAlive && p.pantinCurseTimer != null).length;
    for (var p in players) {
      if (p.role?.toLowerCase() == "pantin" && cursedCount >= 4) {
        if (cursedCount > p.maxSimultaneousCurses) {
          p.maxSimultaneousCurses = cursedCount;
        }
      }
    }
  }

  static void recordPhylChange(Player phyl) {
    phyl.roleChangesCount++;
  }

  // ==========================================================
  // 4. LOGIQUE DE TRANSITION ET RESET
  // ==========================================================

  static void clearTurnData() {
    _traitorsThisTurn.clear();
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
  }

  static void resetFullGameData() {
    debugPrint("🔄 LOG [Achievement] : RESET COMPLET DES SUCCÈS.");
    _traitorsThisTurn.clear();
    _shockTracker.clear();
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