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

  static String getTeamForRole(String role) {
    final rLower = role.toLowerCase().trim();
    if (_wolfRoles.contains(rLower) || rLower.contains("loup")) return "loups";
    if (_soloRoles.contains(rLower)) return "solo";
    return "village";
  }

  // ==========================================================
  // 1. TRANSITION DE TOUR (CENTRALISÉE)
  // ==========================================================
  static void nextTurn(List<Player> allPlayers) {
    debugPrint("--------------------------------------------------");
    debugPrint("🔄 LOG [GameLogic] : Initialisation du prochain tour...");

    // Check Succès (null context car auto)
    AchievementLogic.checkCanacleanCondition(null, allPlayers);

    AchievementLogic.clearTurnData();
    AchievementLogic.checkPantinCurses(allPlayers);

    _enforceMaisonFanPolicy(allPlayers);

    nightChamanTarget = null;
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
    quicheSavedThisNight = 0;

    for (var p in allPlayers) {
      // RESET CRITIQUE DES VOTES
      p.votes = 0;
      p.targetVote = null;

      if (!p.isAlive) {
        p.pantinCurseTimer = null;
        p.hasBeenHitByDart = false;
        p.zookeeperEffectReady = false;
        p.hasBakedQuiche = false;
        p.isVillageProtected = false;
        continue;
      }

      p.isImmunizedFromVote = false;
      p.isVoteCancelled = false;
      p.isMutedDay = false;
      p.powerActiveThisTurn = false;
      p.resetTemporaryStates();
    }

    globalTurnNumber++;
    isDayTime = false;
    debugPrint("🌙 LOG [GameLogic] : PASSAGE À LA NUIT $globalTurnNumber");
    debugPrint("--------------------------------------------------");
  }

  static void _enforceMaisonFanPolicy(List<Player> allPlayers) {
    try {
      Player maison = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "maison");
      if (maison.isFanOfRonAldo) {
        debugPrint("🏟️ LOG [Stade] : La Maison appartient au club Ron-Aldo. Plus d'hébergement possible.");
        for (var p in allPlayers) {
          p.isInHouse = false;
        }
      }
    } catch (e) {}
  }

  // ==========================================================
  // 2. ANALYSE DES VOTES
  // ==========================================================
  static void validateVoteStats(BuildContext context, List<Player> allPlayers) {
    debugPrint("📊 LOG [GameLogic] : Analyse statistique des votes...");

    for (var p in allPlayers.where((p) => p.isAlive)) {
      if (p.role?.toLowerCase() == "dingo") {
        if (p.targetVote == null || p.targetVote!.name != p.name) {
          debugPrint("❌ LOG [Dingo] : ${p.name} a voté pour ${p.targetVote?.name ?? 'Personne'}. Série 'Self Vote' brisée.");
          p.dingoSelfVotedOnly = false;
        } else {
          debugPrint("🤪 LOG [Dingo] : ${p.name} vote pour lui-même. Série OK.");
        }
      }

      if (p.isFanOfRonAldo && p.targetVote != null) {
        if (p.targetVote!.role?.toLowerCase() == "ron-aldo") {
          p.hasBetrayedRonAldo = true;
          AchievementLogic.checkTraitorFan(context, p, p.targetVote!);
          debugPrint("🐍 LOG [Trahison] : Le fan ${p.name} a voté contre Ron-Aldo !");
        }
      }

      if (p.votes > 0) {
        p.totalVotesReceivedDuringGame += p.votes;
        AchievementLogic.checkEvolvedHunger(context, p);
      }
    }
  }

  // ==========================================================
  // 3. GESTION DES VOTES
  // ==========================================================
  static void processVillageVote(BuildContext context, List<Player> allPlayers) {
    debugPrint("🗳️ LOG [Vote] : Calcul du résultat du vote.");

    hasVotedThisTurn = true;

    for (var p in allPlayers) {
      p.votes = 0;
    }
    for (var voter in allPlayers.where((p) => p.isAlive)) {
      if (voter.targetVote != null) {
        // Le Pantin vote double
        int weight = (voter.role?.toLowerCase() == "pantin") ? 2 : 1;
        try {
          var target = allPlayers.firstWhere((p) => p.name == voter.targetVote!.name);
          target.votes += weight;
        } catch (e) {
          debugPrint("⚠️ Vote ignoré : Cible introuvable.");
        }
      }
    }

    validateVoteStats(context, allPlayers);

    List<Player> votablePlayers =
    allPlayers.where((p) => p.isAlive && !p.isImmunizedFromVote).toList();

    if (votablePlayers.isEmpty) {
      debugPrint("🕊️ LOG [Vote] : Personne n'est éliminable aujourd'hui.");
      return;
    }

    votablePlayers.sort((a, b) {
      int voteComp = b.votes.compareTo(a.votes);
      if (voteComp != 0) return voteComp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    Player first = votablePlayers[0];
    debugPrint("💀 LOG [Vote] : Cible désignée -> ${first.name} avec ${first.votes} voix.");

    for (var p in allPlayers.where((p) => p.isAlive && p.role?.toLowerCase() == "dingo")) {
      if (p.targetVote == first) {
        AchievementLogic.checkParkingShot(context, p, first, allPlayers);
      }
    }

    AchievementLogic.checkEvolvedHunger(context, first);
    // Note : Le MJ appelle eliminatePlayer manuellement via MJResultScreen.
  }

  // ==========================================================
  // 4. ÉLIMINATION
  // ==========================================================
  static Player eliminatePlayer(BuildContext context, List<Player> allPlayers, Player target,
      {bool isVote = false, String reason = ""}) {

    Player realTarget = allPlayers.firstWhere((p) => p.name == target.name, orElse: () => target);

    if (!realTarget.isAlive) return realTarget;

    final String roleLower = realTarget.role?.toLowerCase() ?? "";

    if (realTarget.isAwayAsMJ) {
      debugPrint("🛡️ LOG [Archiviste] : Cible absente (Switch MJ). Immunité totale.");
      return realTarget;
    }

    // --- LOGIQUE PANTIN ---
    if (roleLower == "pantin") {
      if (!isVote) {
        debugPrint("🛡️ LOG [Pantin] : Survit à l'attaque nocturne.");
        return realTarget;
      } else {
        if (!realTarget.hasSurvivedVote) {
          // Check Clutch si le Pantin est la cible éliminée par le MJ
          try {
            List<Player> survivors = allPlayers.where((p) => p.isAlive).toList();
            survivors.sort((a, b) => b.votes.compareTo(a.votes));
            // Recherche du concurrent le plus proche (celui qui n'est pas le pantin)
            Player competitor = survivors.firstWhere((p) => p.name != realTarget.name, orElse: () => realTarget);
            int diff = (competitor.votes - realTarget.votes).abs();

            // Si écart de 1 voix et que le Pantin a voté pour son concurrent direct
            if (diff <= 1 && realTarget.targetVote?.name == competitor.name) {
              realTarget.pantinClutchTriggered = true;
              TrophyService.checkAndUnlockImmediate(
                context: context,
                playerName: realTarget.name,
                achievementId: "pantin_clutch",
                checkData: {'pantin_clutch_triggered': true},
              );
            }
          } catch(e) {}

          realTarget.hasSurvivedVote = true;
          debugPrint("🎭 LOG [Pantin] : Le Pantin survit à son premier vote.");
          return realTarget;
        }
      }
    }

    // --- DETECTION CLUTCH SI LE MJ ELIMINE LA PERSONNE LA PLUS VOTÉE ---
    if (isVote && roleLower != "pantin") {
      try {
        Player pantin = allPlayers.firstWhere((p) => p.isAlive && p.role?.toLowerCase() == "pantin");
        List<Player> survivors = allPlayers.where((p) => p.isAlive).toList();
        survivors.sort((a, b) => b.votes.compareTo(a.votes));

        // RÈGLE : La victime doit être le premier au score et l'écart avec le Pantin doit être de 1
        if (realTarget.name == survivors[0].name) {
          int diff = (realTarget.votes - pantin.votes).abs();
          if (diff <= 1 && pantin.targetVote?.name == realTarget.name) {
            pantin.pantinClutchTriggered = true;
            debugPrint("🎭 LOG [Pantin] : CLUTCH DÉTECTÉ pour ${pantin.name} !");

            TrophyService.checkAndUnlockImmediate(
              context: context,
              playerName: pantin.name,
              achievementId: "pantin_clutch",
              checkData: {'pantin_clutch_triggered': true},
            );
          }
        }
      } catch (e) {}
    }

    if (isVote && realTarget.hasScapegoatPower) {
      realTarget.hasScapegoatPower = false;
      debugPrint("🐏 LOG [Archevêque] : Bouc émissaire utilisé.");
      return realTarget;
    }

    if (roleLower == "voyageur" && realTarget.isInTravel) {
      realTarget.isInTravel = false;
      realTarget.canTravelAgain = false;
      debugPrint("✈️ LOG [Voyageur] : Forcé au retour du voyage.");
      return realTarget;
    }

    Player victim = realTarget;

    // --- LOGIQUE MAISON (PROTECTION) ---
    if (realTarget.isInHouse && !reason.contains("Malédiction")) {
      Player? houseOwner;
      try {
        houseOwner = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "maison" && p.isAlive && !p.isHouseDestroyed);
      } catch (e) { houseOwner = null; }

      if (houseOwner != null) {
        if (houseOwner.isFanOfRonAldo) {
          victim = realTarget;
        } else {
          victim = houseOwner;
          houseOwner.isHouseDestroyed = true;
          for (var p in allPlayers) { p.isInHouse = false; }
          victim.isAlive = false;
          AchievementLogic.checkHouseCollapse(houseOwner);
          debugPrint("🏠 LOG [Maison] : Effondrement ! Le propriétaire meurt à la place de ${realTarget.name}");
          return victim;
        }
      }
    }
    else if (roleLower == "ron-aldo") {
      List<Player> allFans = allPlayers.where((p) => p.isFanOfRonAldo && p.isAlive).toList();
      allFans.sort((a, b) => a.fanJoinOrder.compareTo(b.fanJoinOrder));

      if (allFans.isNotEmpty) {
        Player firstFan = allFans.first;
        victim = firstFan;
        debugPrint("🛡️ LOG [Ron-Aldo] : Le Premier Fan (${victim.name}) se sacrifie !");
        AchievementLogic.checkFanSacrifice(context, victim, realTarget);
      }
    }

    if (isVote && nightChamanTarget != null && victim.name == nightChamanTarget!.name) {
      chamanSniperAchieved = true;
    }

    victim.isAlive = false;
    debugPrint("💀 LOG [Mort] : ${victim.name} (${victim.role}) a quitté la partie.");

    // --- VENGEANCE POKÉMON ---
    if ((victim.role?.toLowerCase() == "pokémon" || victim.role?.toLowerCase() == "pokemon") &&
        victim.pokemonRevengeTarget != null) {
      try {
        Player revengeTarget = allPlayers.firstWhere((p) => p.name == victim.pokemonRevengeTarget!.name);
        if (revengeTarget.isAlive) {
          debugPrint("⚡ LOG [Pokémon] : MORT ! Il emporte ${revengeTarget.name}.");
          eliminatePlayer(context, allPlayers, revengeTarget, isVote: false);
        }
      } catch (e) {}
    }

    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      firstDeadPlayerName = victim.name;
      AchievementLogic.checkFirstBlood(victim);
    }

    if (roleLower == "pokémon" && globalTurnNumber == 1 && !isDayTime) {
      pokemonDiedTour1 = true;
    }

    AchievementLogic.checkDeathAchievements(context, victim, allPlayers);

    return victim;
  }

  // ==========================================================
  // 5. INITIALISATION DE PARTIE
  // ==========================================================
  static void assignRoles(List<Player> players) {
    debugPrint("--------------------------------------------------");
    debugPrint("🎭 LOG [Setup] : Distribution des rôles en cours...");
    RoleDistributionLogic.distribute(players);
    _finalizeTeams(players);
    debugPrint("--------------------------------------------------");
  }

  static void _finalizeTeams(List<Player> players) {
    for (var p in players) {
      _initializePlayerState(p);
      p.team = getTeamForRole(p.role ?? "");
      debugPrint("👤 LOG [Setup] : ${p.name} -> ${p.role} (${p.team})");
    }
  }

  static void _initializePlayerState(Player p) {
    p.isAlive = true;
    p.votes = 0;
    p.pantinCurseTimer = null;
    p.pantinClutchTriggered = false;
    p.roleChangesCount = 0;
    p.killsThisGame = 0;
    p.mutedPlayersCount = 0;
    p.hasHeardWolfSecrets = false;
    p.wasRevivedInThisGame = false;
    p.hasUsedRevive = false;
    p.hasBetrayedRonAldo = false;
    p.travelerBullets = 0;
    p.somnifereUses = (p.role?.toLowerCase() == "somnifère") ? 1 : 0;
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
    p.zookeeperEffectReady = false;
    p.isEffectivelyAsleep = false;
    p.powerActiveThisTurn = false;
    p.lastDresseurAction = null;
    p.pokemonRevengeTarget = null;
    p.hasBakedQuiche = false;
    p.isVillageProtected = false;
    p.archivisteActionsUsed = [];
    p.canacleanPresent = false;
    p.isHouseDestroyed = false;
    p.hasSurvivedVote = false;
    p.isAwayAsMJ = false;

    if (globalTurnNumber == 1) {
      AchievementLogic.resetFullGameData();
    }
  }

  // ==========================================================
  // 6. CONDITIONS DE VICTOIRE
  // ==========================================================
  static String? checkWinner(List<Player> players) {
    // --- CORRECTION : VICTOIRE IMMÉDIATE DE L'EXORCISTE ---
    if (exorcistWin) {
      debugPrint("✝️ LOG [Fin] : L'EXORCISTE A RÉUSSI ! VICTOIRE DU VILLAGE.");
      return "EXORCISTE";
    }

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

    if (activeFactions.length > 1) {
      debugPrint("⚔️ LOG [Fin] : Factions restantes : $activeFactions");
      return null;
    }

    final winner = activeFactions.length == 1 ? activeFactions.first : null;
    if (winner != null) debugPrint("🏆 LOG [Fin] : VICTOIRE DE LA FACTION : $winner");

    return winner;
  }
}