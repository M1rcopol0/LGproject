import 'dart:math';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'globals.dart';
import 'achievement_logic.dart';
import 'role_distribution_logic.dart';
import 'trophy_service.dart';
import 'game_save_service.dart';

class GameLogic {
  static const List<String> _wolfRoles = [
    "loup-garou chaman",
    "loup-garou évolué",
    "somnifère"
  ];

  static const List<String> _soloRoles = [
    "chuchoteur",
    "maître du temps",
    "pantin",
    "phyl",
    "dresseur",
    "pokémon",
    "ron-aldo",
    "fan de ron-aldo"
  ];

  // ==========================================================
  // 1. TRANSITION DE TOUR (CENTRALISÉE)
  // ==========================================================
  static void nextTurn(List<Player> allPlayers) {
    AchievementLogic.clearTurnData();
    AchievementLogic.checkPantinCurses(allPlayers);

    _enforceMaisonFanPolicy(allPlayers);

    // Reset des cibles de nuit
    nightChamanTarget = null;
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
    quicheSavedThisNight = 0;

    for (var p in allPlayers) {
      if (!p.isAlive) {
        p.pantinCurseTimer = null;
        p.hasBeenHitByDart = false;
        p.hasBakedQuiche = false;
        p.isVillageProtected = false;
        continue;
      }

      // Reset des états quotidiens
      p.isImmunizedFromVote = false;
      p.votes = 0;
      p.isVoteCancelled = false;
      p.isMutedDay = false;
      p.powerActiveThisTurn = false;

      // Note: isVillageProtected n'est pas reset ici car il doit durer
      // tout le jour suivant la nuit de protection (Jour N).
      // Il est reset dans le cleanup matinal de NightActionsLogic.

      p.resetTemporaryStates();
    }

    // UNIQUE ENDROIT OÙ LE TOUR AUGMENTE
    // Passage de la fin du Jour N à la Nuit N+1
    globalTurnNumber++;
    isDayTime = false;
    debugPrint("🌙 Passage à la Nuit $globalTurnNumber");
  }

  static void _enforceMaisonFanPolicy(List<Player> allPlayers) {
    try {
      Player maison = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "maison");
      if (maison.isFanOfRonAldo) {
        for (var p in allPlayers) {
          p.isInHouse = false;
        }
      }
    } catch (e) { /* Pas de maison */ }
  }

  // ==========================================================
  // 2. GESTION DES VOTES
  // ==========================================================
  static void processVillageVote(BuildContext context, List<Player> allPlayers) {
    List<Player> votablePlayers =
    allPlayers.where((p) => p.isAlive && !p.isImmunizedFromVote).toList();

    for (var p in allPlayers.where((p) => p.isAlive)) {
      if (p.role?.toLowerCase() == "dingo" && p.targetVote != p) {
        p.dingoSelfVotedOnly = false;
      }

      if (p.isFanOfRonAldo && p.targetVote != null) {
        if (p.targetVote!.role?.toLowerCase() == "ron-aldo") {
          p.hasBetrayedRonAldo = true;
          AchievementLogic.checkTraitorFan(p, p.targetVote!);
        }
      }
      if (p.votes > 0) {
        p.totalVotesReceivedDuringGame += p.votes;
      }
    }

    if (votablePlayers.isEmpty) return;

    // Tri par nombre de votes (plus grand au plus petit)
    votablePlayers.sort((a, b) {
      if (b.votes != a.votes) return b.votes.compareTo(a.votes);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    Player first = votablePlayers[0];
    Player? second = votablePlayers.length > 1 ? votablePlayers[1] : null;

    // Protection spéciale Pantin (Clutch save achievement)
    if (second != null && second.role?.toLowerCase() == "pantin") {
      if ((first.votes - second.votes) < 2 && second.targetVote == first) {
        pantinClutchSave = true;
      }
    }

    _checkVoteAchievements(context, first);
    eliminatePlayer(context, allPlayers, first, isVote: true);
  }

  static void _checkVoteAchievements(BuildContext context, Player votedPlayer) {
    if (nightChamanTarget != null && votedPlayer == nightChamanTarget) {
      chamanSniperAchieved = true;
    }
    AchievementLogic.checkEvolvedHunger(votedPlayer);
  }

  // ==========================================================
  // 3. ÉLIMINATION
  // ==========================================================
  static Player eliminatePlayer(BuildContext context, List<Player> allPlayers, Player target,
      {bool isVote = false}) {
    if (!target.isAlive) return target;

    final String roleLower = target.role?.toLowerCase() ?? "";

    // Invulnérabilité nocturne du Pantin
    if (!isVote && roleLower == "pantin") {
      debugPrint("🛡️ Pantin survit à la nuit.");
      return target;
    }

    // Pouvoir du Bouc Émissaire (Archiviste)
    if (isVote && target.hasScapegoatPower) {
      target.hasScapegoatPower = false;
      debugPrint("🐏 Bouc émissaire utilisé pour ${target.name}");
      return target;
    }

    // Malédiction du Pantin au vote
    if (roleLower == "pantin" && isVote && target.pantinCurseTimer == null) {
      target.pantinCurseTimer = 2;
      debugPrint("🎭 Pantin maudit le village en mourant au vote.");
      return target;
    }

    // Protection du Voyageur en déplacement
    if (roleLower == "voyageur" && target.isInTravel) {
      target.isInTravel = false;
      target.canTravelAgain = false;
      debugPrint("✈️ Voyageur forcé de rentrer prématurément.");
      return target;
    }

    Player victim = target;

    // --- LOGIQUE MAISON ---
    if (target.isInHouse) {
      // On cherche le propriétaire (vivant et dont la maison n'est pas déjà cassée)
      Player? houseOwner;
      try {
        houseOwner = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "maison" && p.isAlive && !p.isHouseDestroyed);
      } catch (e) { houseOwner = null; }

      if (houseOwner != null) {
        if (houseOwner.isFanOfRonAldo) {
          victim = target; // Protection désactivée si fan
        } else {
          victim = houseOwner; // La maison prend le coup
          houseOwner.isHouseDestroyed = true; // Crucial : Marquer comme détruite immédiatement
          for (var p in allPlayers) { p.isInHouse = false; } // Expulser tout le monde
          return victim; // On sort immédiatement
        }
      } else {
        victim = target; // Plus de maison ou déjà cassée ce tour
      }
    }
    // Logique Sacrifice Ron-Aldo
    else if (roleLower == "ron-aldo") {
      List<Player> aliveFans =
      allPlayers.where((p) => p.isFanOfRonAldo && p.isAlive).toList();
      aliveFans.sort((a, b) => a.fanJoinOrder.compareTo(b.fanJoinOrder));

      if (aliveFans.isNotEmpty) {
        victim = aliveFans.first;
        TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: victim.name,
          achievementId: "fan_sacrifice",
          checkData: {'is_fan_sacrifice': true},
        );
      }
    }

    victim.isAlive = false;

    // Cleanup si la maison meurt
    if (victim.role?.toLowerCase() == "maison") {
      for (var p in allPlayers) { p.isInHouse = false; }
    }

    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      firstDeadPlayerName = victim.name;
    }
    AchievementLogic.checkFirstBlood(victim);

    if (roleLower == "pokémon" && globalTurnNumber == 1 && !isDayTime) {
      pokemonDiedTour1 = true;
    }

    return victim;
  }

  // ==========================================================
  // 4. RÉPARTITION DES RÔLES
  // ==========================================================
  static void assignRoles(List<Player> players) {
    RoleDistributionLogic.distribute(players);
    _finalizeTeams(players);
  }

  static void _finalizeTeams(List<Player> players) {
    for (var p in players) {
      _initializePlayerState(p);
      final rLower = p.role?.toLowerCase() ?? "";

      if (_wolfRoles.contains(rLower) || rLower.contains("loup")) {
        p.team = "loups";
      } else if (_soloRoles.contains(rLower)) {
        p.team = "solo";
      } else {
        p.team = "village";
      }
    }
  }

  static void _initializePlayerState(Player p) {
    p.isAlive = true;
    p.votes = 0;
    p.pantinCurseTimer = null;
    p.roleChangesCount = 0;
    p.killsThisGame = 0;
    p.mutedPlayersCount = 0;
    p.hasHeardWolfSecrets = false;
    p.wasRevivedInThisGame = false;
    p.hasBetrayedRonAldo = false;
    p.travelerBullets = 0;
    p.somnifereUses = (p.role?.toLowerCase() == "somnifère") ? 2 : 0;
    p.bombTimer = 0;
    p.hasPlacedBomb = false;
    p.dingoStrikeCount = 0;
    p.dingoShotsFired = 0;
    p.dingoShotsHit = 0;
    p.dingoSelfVotedOnly = true;
    p.phylTargets = [];
    p.isFanOfRonAldo = false;
    p.isVillageChief = false;
    p.maxSimultaneousCurses = 0;
    p.hasBeenHitByDart = false;
    p.isEffectivelyAsleep = false;
    p.powerActiveThisTurn = false;
    p.lastDresseurAction = null;
    p.hasBakedQuiche = false;
    p.isVillageProtected = false;
    p.archivisteActionsUsed = [];

    if (globalTurnNumber == 1) {
      AchievementLogic.resetFullGameData();
    }
  }

  // ==========================================================
  // 5. VÉRIFICATION DE VICTOIRE
  // ==========================================================
  static String? checkWinner(List<Player> players) {
    final alive = players.where((p) => p.isAlive).toList();
    if (alive.isEmpty && players.isNotEmpty) return "ÉGALITÉ_SANGUINAIRE";
    if (players.isEmpty) return null;

    try {
      Player phyl = alive.firstWhere((p) => p.role?.toLowerCase() == "phyl");
      if (phyl.isVillageChief && phyl.phylTargets.length >= 2) {
        if (phyl.phylTargets.every((t) => !t.isAlive)) return "PHYL";
      }
    } catch (e) {}

    Set<String> activeFactions = {};
    for (var p in alive) {
      if (p.team == "village") {
        activeFactions.add(p.isFanOfRonAldo ? "RON-ALDO" : "VILLAGE");
      } else if (p.team == "loups") {
        activeFactions.add("LOUPS-GAROUS");
      } else if (p.team == "solo") {
        String role = p.role?.toLowerCase() ?? "";
        if (role == "ron-aldo" || p.isFanOfRonAldo) {
          activeFactions.add("RON-ALDO");
        } else if (role == "dresseur" || role == "pokémon") {
          activeFactions.add("DRESSEUR");
        } else if (role == "archiviste") {
          activeFactions.add("ARCHIVISTE");
        } else {
          activeFactions.add(role.toUpperCase());
        }
      }
    }

    if (activeFactions.length > 1) return null;
    return activeFactions.length == 1 ? activeFactions.first : null;
  }
}