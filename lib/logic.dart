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
    debugPrint("--------------------------------------------------");
    debugPrint("🔄 LOG [GameLogic] : Initialisation du prochain tour...");

    // Vérification des succès d'équipe avant le reset des états
    AchievementLogic.checkCanacleanCondition(allPlayers);

    AchievementLogic.clearTurnData();
    AchievementLogic.checkPantinCurses(allPlayers);

    _enforceMaisonFanPolicy(allPlayers);

    // Reset des cibles de nuit et compteurs temporaires
    nightChamanTarget = null;
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
    quicheSavedThisNight = 0;

    for (var p in allPlayers) {
      if (!p.isAlive) {
        // On ne reset PAS les timers de bombes ici (gérés par NightLogic)
        p.pantinCurseTimer = null;
        p.hasBeenHitByDart = false;
        p.zookeeperEffectReady = false;
        p.hasBakedQuiche = false;
        p.isVillageProtected = false;
        continue;
      }

      p.isImmunizedFromVote = false;
      p.votes = 0;
      p.isVoteCancelled = false;
      p.isMutedDay = false;
      p.powerActiveThisTurn = false;

      // Note : resetTemporaryStates n'écrase pas dingoStrikeCount, travelerBullets, hasPlacedBomb
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
  // 2. ANALYSE DES VOTES (NOUVELLE MÉTHODE CRITIQUE)
  // ==========================================================
  /// Cette méthode doit être appelée par VoteScreens AVANT l'affichage des résultats MJ
  static void validateVoteStats(List<Player> allPlayers) {
    debugPrint("📊 LOG [GameLogic] : Analyse statistique des votes...");

    for (var p in allPlayers.where((p) => p.isAlive)) {

      // LOGIQUE DINGO (Check Strict sur le NOM)
      if (p.role?.toLowerCase() == "dingo") {
        // Si le vote est nul (abstention/voyage) OU si le nom de la cible n'est pas son propre nom
        if (p.targetVote == null || p.targetVote!.name != p.name) {
          debugPrint("❌ LOG [Dingo] : ${p.name} a voté pour ${p.targetVote?.name ?? 'Personne'}. Série brisée.");
          p.dingoSelfVotedOnly = false;
        } else {
          debugPrint("🤪 LOG [Dingo] : ${p.name} vote pour lui-même. Série OK.");
        }
      }

      // LOGIQUE RON-ALDO (Trahison)
      if (p.isFanOfRonAldo && p.targetVote != null) {
        if (p.targetVote!.role?.toLowerCase() == "ron-aldo") {
          p.hasBetrayedRonAldo = true;
          AchievementLogic.checkTraitorFan(p, p.targetVote!);
          debugPrint("🐍 LOG [Trahison] : Le fan ${p.name} a voté contre Ron-Aldo !");
        }
      }

      // STATS GLOBALES (Votes reçus)
      if (p.votes > 0) {
        p.totalVotesReceivedDuringGame += p.votes;
        // Check succès Fringale
        AchievementLogic.checkEvolvedHunger(p);
        // Check succès Chaman
        if (nightChamanTarget != null && p == nightChamanTarget) {
          chamanSniperAchieved = true;
        }
      }
    }
  }

  // ==========================================================
  // 3. GESTION DES VOTES (CALCUL DU RÉSULTAT)
  // ==========================================================
  static void processVillageVote(BuildContext context, List<Player> allPlayers) {
    debugPrint("🗳️ LOG [Vote] : Calcul du résultat du vote.");

    // D'abord, on valide les stats (au cas où ce n'est pas fait par l'UI)
    validateVoteStats(allPlayers);

    List<Player> votablePlayers =
    allPlayers.where((p) => p.isAlive && !p.isImmunizedFromVote).toList();

    if (votablePlayers.isEmpty) {
      debugPrint("🕊️ LOG [Vote] : Personne n'est éliminable aujourd'hui.");
      return;
    }

    // TRI : Votes décroissants, puis Alphabétique croissant
    votablePlayers.sort((a, b) {
      int voteComp = b.votes.compareTo(a.votes);
      if (voteComp != 0) return voteComp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    Player first = votablePlayers[0];
    Player? second = votablePlayers.length > 1 ? votablePlayers[1] : null;

    // Clutch Save Pantin (s'il est 2ème à moins de 2 votes et qu'il a voté le 1er)
    if (second != null && second.role?.toLowerCase() == "pantin") {
      if ((first.votes - second.votes) < 2 && second.targetVote == first) {
        pantinClutchSave = true;
        debugPrint("🎭 LOG [Pantin] : Clutch save activé pour le Pantin !");
      }
    }

    debugPrint("💀 LOG [Élimination] : Le village désigne ${first.name} (${first.votes} votes).");
    eliminatePlayer(context, allPlayers, first, isVote: true);
  }

  // ==========================================================
  // 4. ÉLIMINATION
  // ==========================================================
  static Player eliminatePlayer(BuildContext context, List<Player> allPlayers, Player target,
      {bool isVote = false}) {
    if (!target.isAlive) return target;

    final String roleLower = target.role?.toLowerCase() ?? "";

    // PROTECTION NOCTURNE PANTIN (Standard)
    if (!isVote && roleLower == "pantin") {
      debugPrint("🛡️ LOG [Pantin] : Survit à l'attaque nocturne grâce à son immortalité.");
      return target;
    }

    // CORRECTION PANTIN : Survie au PREMIER vote
    if (isVote && roleLower == "pantin") {
      if (!target.hasSurvivedVote) {
        target.hasSurvivedVote = true;
        debugPrint("🎭 LOG [Pantin] : Le Pantin survit à son premier vote (Joker utilisé).");
        return target; // Annule l'élimination (retourne le joueur vivant)
      } else {
        debugPrint("🎭 LOG [Pantin] : Le Pantin ne possède plus de Joker. L'élimination procède.");
      }
    }

    // PROTECTION ARCHIVISTE (Bouc Émissaire)
    if (isVote && target.hasScapegoatPower) {
      target.hasScapegoatPower = false;
      debugPrint("🐏 LOG [Archevêque] : Bouc émissaire utilisé pour ${target.name}. L'élimination est annulée.");
      return target;
    }

    // MALÉDICTION DU PANTIN (Mort par vote)
    if (roleLower == "pantin" && isVote && target.pantinCurseTimer == null) {
      target.pantinCurseTimer = 2;
      debugPrint("🎭 LOG [Pantin] : Malédiction lancée sur le village avant de mourir.");
      // Note : Le pantin meurt réellement à la fin de la fonction
    }

    // RETOUR VOYAGEUR (Il ne meurt pas, il rentre)
    if (roleLower == "voyageur" && target.isInTravel) {
      target.isInTravel = false;
      target.canTravelAgain = false;
      debugPrint("✈️ LOG [Voyageur] : Forcé au retour du voyage par une attaque fatale.");
      return target; // Retourne le joueur vivant (mais revenu)
    }

    Player victim = target;

    // LOGIQUE MAISON
    if (target.isInHouse) {
      Player? houseOwner;
      try {
        houseOwner = allPlayers.firstWhere((p) =>
        p.role?.toLowerCase() == "maison" &&
            p.isAlive &&
            !p.isHouseDestroyed
        );
      } catch (e) { houseOwner = null; }

      if (houseOwner != null) {
        if (houseOwner.isFanOfRonAldo) {
          debugPrint("🏟️ LOG [Stade] : Le proprio est fan, il n'ouvre pas. ${target.name} meurt.");
          victim = target;
        } else {
          debugPrint("🏠 LOG [Maison] : Le proprio (${houseOwner.name}) se sacrifie pour ${target.name} !");
          victim = houseOwner;
          houseOwner.isHouseDestroyed = true;
          for (var p in allPlayers) { p.isInHouse = false; }
          victim.isAlive = false;
          return victim;
        }
      }
    }
    // LOGIQUE RON-ALDO
    else if (roleLower == "ron-aldo") {
      List<Player> aliveFans =
      allPlayers.where((p) => p.isFanOfRonAldo && p.isAlive).toList();
      aliveFans.sort((a, b) => a.fanJoinOrder.compareTo(b.fanJoinOrder));

      if (aliveFans.isNotEmpty) {
        victim = aliveFans.first;
        debugPrint("🛡️ LOG [Ron-Aldo] : Le fan ${victim.name} se jette devant la balle pour Ron-Aldo !");
        TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: victim.name,
          achievementId: "fan_sacrifice",
          checkData: {'is_fan_sacrifice': true},
        );
      }
    }

    // CHECK SUCCÈS DINGO (Parking Shot)
    for (var p in allPlayers.where((p) => p.isAlive && p.role?.toLowerCase() == "dingo")) {
      AchievementLogic.checkParkingShot(p, victim, allPlayers);
    }

    victim.isAlive = false;
    debugPrint("💀 LOG [Mort] : ${victim.name} (${victim.role}) a quitté la partie.");

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
      final rLower = p.role?.toLowerCase() ?? "";

      if (_wolfRoles.contains(rLower) || rLower.contains("loup")) {
        p.team = "loups";
      } else if (_soloRoles.contains(rLower)) {
        p.team = "solo";
      } else {
        p.team = "village";
      }
      debugPrint("👤 LOG [Setup] : ${p.name} -> ${p.role} (${p.team})");
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
    p.hasUsedRevive = false;
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
    p.zookeeperEffectReady = false;
    p.isEffectivelyAsleep = false;
    p.powerActiveThisTurn = false;
    p.lastDresseurAction = null;
    p.hasBakedQuiche = false;
    p.isVillageProtected = false;
    p.archivisteActionsUsed = [];
    p.canacleanPresent = false;
    p.isHouseDestroyed = false;
    p.hasSurvivedVote = false; // Init joker Pantin

    if (globalTurnNumber == 1) {
      AchievementLogic.resetFullGameData();
    }
  }

  // ==========================================================
  // 6. CONDITIONS DE VICTOIRE
  // ==========================================================
  static String? checkWinner(List<Player> players) {
    final alive = players.where((p) => p.isAlive).toList();
    if (alive.isEmpty && players.isNotEmpty) {
      debugPrint("🔚 LOG [Fin] : ÉGALITÉ SANGUINAIRE. Tout le monde est mort.");
      return "ÉGALITÉ_SANGUINAIRE";
    }
    if (players.isEmpty) return null;

    try {
      Player phyl = alive.firstWhere((p) => p.role?.toLowerCase() == "phyl");
      if (phyl.isVillageChief && phyl.phylTargets.length >= 2) {
        if (phyl.phylTargets.every((t) => !t.isAlive)) {
          debugPrint("🏆 LOG [Fin] : PHYL A GAGNÉ ! Chef et cibles mortes.");
          return "PHYL";
        }
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

    final winner = activeFactions.length == 1 ? activeFactions.first : null;
    if (winner != null) debugPrint("🏆 LOG [Fin] : VICTOIRE DE LA FACTION : $winner");

    return winner;
  }
}