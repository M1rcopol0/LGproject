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
    // AchievementLogic.checkPantinCurses(allPlayers); // RETIRÉ (Succès supprimé)

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
      // On reset isVoteCancelled ici pour le jour suivant
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
      }
    }
  }

  // ==========================================================
  // 3. GESTION DES VOTES
  // ==========================================================
  static void processVillageVote(BuildContext context, List<Player> allPlayers) {
    debugPrint("🗳️ LOG [Vote] : Calcul du résultat du vote.");

    hasVotedThisTurn = true;

    // 1. Reset des compteurs (CRITIQUE POUR ÉVITER LE CUMUL)
    for (var p in allPlayers) {
      p.votes = 0;
    }

    // 2. Identification du bloc Ron-Aldo
    Player? ronAldo;
    int fanCount = 0;

    try {
      ronAldo = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "ron-aldo" && p.isAlive);
      // On compte les fans vivants pour le bonus
      fanCount = allPlayers.where((p) => p.isFanOfRonAldo && p.isAlive).length;
      debugPrint("⚽ LOG [Ron-Aldo] : Fans actifs détectés : $fanCount");
    } catch (_) {
      debugPrint("⚽ LOG [Ron-Aldo] : Pas de Ron-Aldo vivant.");
    }

    // 3. Application des votes
    // CORRECTION : On exclut les Archivistes absents du traitement des votants
    for (var voter in allPlayers.where((p) => p.isAlive && !p.isAwayAsMJ)) {

      // CORRECTION MAJEURE : Si le vote est annulé (Archiviste), on passe direct
      if (voter.isVoteCancelled) {
        debugPrint("🚫 LOG [Vote] : Le vote de ${voter.name} a été annulé par l'Archiviste.");
        continue;
      }

      // CAS SPÉCIAL : FAN DE RON-ALDO
      // Si Ron-Aldo est vivant, le fan NE VOTE PAS individuellement.
      if (ronAldo != null && voter.isFanOfRonAldo) {
        continue;
      }

      if (voter.targetVote != null) {
        // --- SUIVI SUCCÈS "UN CHOIX CORNÉLIEN" ---
        AchievementLogic.trackVote(voter, voter.targetVote!);

        // Poids de base
        int weight = 1;

        // Bonus Pantin (x2)
        if (voter.role?.toLowerCase() == "pantin") {
          weight = 2;
        }

        // Bonus Ron-Aldo (Lui-même [1] + ses fans [fanCount])
        if (voter.role?.toLowerCase() == "ron-aldo") {
          weight += fanCount;
          debugPrint("⚽ LOG [Ron-Aldo] : Vote avec un poids de $weight (dont $fanCount fans).");
        }

        // Application du vote
        try {
          var target = allPlayers.firstWhere((p) => p.name == voter.targetVote!.name);
          target.votes += weight;
          debugPrint("🗳️ LOG [Vote] : ${voter.name} (+${weight}) -> ${target.name} (Total: ${target.votes})");
        } catch (e) {
          debugPrint("⚠️ Vote ignoré : Cible introuvable.");
        }
      }
    }

    validateVoteStats(context, allPlayers);

    // ... (Le reste : Tri, Dingo, etc.) ...

    // CORRECTION : On exclut les Archivistes absents de la liste des éliminables
    List<Player> votablePlayers =
    allPlayers.where((p) => p.isAlive && !p.isImmunizedFromVote && !p.isAwayAsMJ).toList();

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
          // CORRECTION : Appel avec context pour le pop-up
          AchievementLogic.checkHouseCollapse(context, houseOwner);
          debugPrint("🏠 LOG [Maison] : Effondrement ! Le propriétaire meurt à la place de ${realTarget.name}");
          return victim;
        }
      }
    }
    // --- CORRECTION RON-ALDO (Sacrifice UNIQUE) ---
    else if (roleLower == "ron-aldo") {
      try {
        // On cherche spécifiquement le Fan n°1 (Order = 1)
        Player firstFan = allPlayers.firstWhere(
              (p) => p.isFanOfRonAldo && p.fanJoinOrder == 1,
          orElse: () => Player(name: "None"),
        );

        // Seul lui peut se sacrifier, s'il est vivant.
        if (firstFan.name != "None" && firstFan.isAlive) {
          victim = firstFan;
          debugPrint("🛡️ LOG [Ron-Aldo] : Le Premier Fan (${victim.name}) se sacrifie !");
          AchievementLogic.checkFanSacrifice(context, victim, realTarget);
        } else {
          debugPrint("🛡️ LOG [Ron-Aldo] : Le Premier Fan est mort. Pas de sacrifice possible.");
        }
      } catch (e) {
        debugPrint("⚠️ Erreur logique Ron-Aldo : $e");
      }
    }

    if (isVote && nightChamanTarget != null && victim.name == nightChamanTarget!.name) {
      chamanSniperAchieved = true;
    }

    victim.isAlive = false;
    debugPrint("💀 LOG [Mort] : ${victim.name} (${victim.role}) a quitté la partie.");

    // --- SUCCÈS : LOUIS CROIX V BÂTON ---
    if (isVote && victim.isVillageChief && victim.isRoi) {
      TrophyService.checkAndUnlockImmediate(
          context: context,
          playerName: victim.name,
          achievementId: "louis_croix_v",
          checkData: {'louis_croix_v_triggered': true}
      );
    }

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
      // CORRECTION : Appel avec context pour le pop-up
      AchievementLogic.checkFirstBlood(context, victim);
    }

    if (roleLower == "pokémon" && globalTurnNumber == 1 && !isDayTime) {
      pokemonDiedTour1 = true;
    }

    AchievementLogic.checkDeathAchievements(context, victim, allPlayers);

    // --- CORRECTION FRINGALE NOCTURNE ---
    // Si c'est un vote, que la victime meurt et qu'elle avait survécu à une morsure
    if (isVote && victim.hasSurvivedWolfBite) {
      // On lance le scan global pour attribuer le succès aux loups
      AchievementLogic.checkEvolvedHunger(context, victim, allPlayers);
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
    // p.maxSimultaneousCurses = 0; // RETIRÉ
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
    // --- VICTOIRE IMMÉDIATE DE L'EXORCISTE ---
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