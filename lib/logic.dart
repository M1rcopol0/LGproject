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

  // --- HELPER PUBLIC ---
  // Permet de récupérer l'équipe automatiquement lors de l'ajout manuel d'un joueur
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
      // RESET CRITIQUE DES VOTES pour éviter les accumulations entre tours
      // et éviter que les morts ne gardent des votes s'ils sont ressuscités.
      p.votes = 0;
      p.targetVote = null; // Reset du vote émis

      if (!p.isAlive) {
        // On ne reset PAS les timers de bombes ici (gérés par NightLogic)
        // On ne reset PAS hasPlacedBomb pour le Tardos mort (la bombe persiste)
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
  // 2. ANALYSE DES VOTES (MÉTHODE CRITIQUE POUR LES SUCCÈS)
  // ==========================================================
  /// Appelé par VoteScreens avant l'affichage du MJ
  static void validateVoteStats(List<Player> allPlayers) {
    debugPrint("📊 LOG [GameLogic] : Analyse statistique des votes...");

    for (var p in allPlayers.where((p) => p.isAlive)) {

      // LOGIQUE DINGO (Check Strict sur le NOM)
      if (p.role?.toLowerCase() == "dingo") {
        // Si le vote est nul (abstention/voyage) OU si le nom de la cible n'est pas son propre nom
        if (p.targetVote == null || p.targetVote!.name != p.name) {
          debugPrint("❌ LOG [Dingo] : ${p.name} a voté pour ${p.targetVote?.name ?? 'Personne'}. Série 'Self Vote' brisée.");
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

      // Note: Le comptage global des votes reçus se fait dans processVillageVote pour être plus sûr
    }
  }

  // ==========================================================
  // 3. GESTION DES VOTES (CALCUL DU RÉSULTAT)
  // ==========================================================
  static void processVillageVote(BuildContext context, List<Player> allPlayers) {
    debugPrint("🗳️ LOG [Vote] : Calcul du résultat du vote.");

    // 1. RECALCUL STRICT DES VOTES REÇUS
    // Pour s'assurer que p.votes correspond exactement aux votes de ce tour
    for (var p in allPlayers) {
      p.votes = 0; // Reset temporaire
    }
    for (var voter in allPlayers.where((p) => p.isAlive)) {
      if (voter.targetVote != null) {
        // On retrouve la cible dans la liste pour être sûr d'incrémenter le bon objet
        try {
          var target = allPlayers.firstWhere((p) => p.name == voter.targetVote!.name);
          target.votes++;
          target.totalVotesReceivedDuringGame++;
        } catch (e) {
          debugPrint("⚠️ Vote ignoré : Cible introuvable.");
        }
      }
    }

    // 2. Validation des succès
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
    debugPrint("💀 LOG [Vote] : Cible désignée -> ${first.name} avec ${first.votes} voix.");

    Player? second = votablePlayers.length > 1 ? votablePlayers[1] : null;

    // Clutch Save Pantin (s'il est 2ème à moins de 2 votes et qu'il a voté le 1er)
    if (second != null && second.role?.toLowerCase() == "pantin") {
      if ((first.votes - second.votes) < 2 && second.targetVote == first) {
        pantinClutchSave = true;
        debugPrint("🎭 LOG [Pantin] : Clutch save activé pour le Pantin !");
      }
    }

    // --- CORRECTION : TIR DU PARKING (JOUR) ---
    // Le succès ne s'active que si le Dingo a effectivement voté pour la victime
    for (var p in allPlayers.where((p) => p.isAlive && p.role?.toLowerCase() == "dingo")) {
      if (p.targetVote == first) {
        AchievementLogic.checkParkingShot(p, first, allPlayers);
      }
    }

    // Check Fringale (Success)
    AchievementLogic.checkEvolvedHunger(first);

    eliminatePlayer(context, allPlayers, first, isVote: true);
  }

  // ==========================================================
  // 4. ÉLIMINATION
  // ==========================================================
  static Player eliminatePlayer(BuildContext context, List<Player> allPlayers, Player target,
      {bool isVote = false}) {
    // Sécurité : On récupère la bonne instance dans la liste principale
    Player realTarget = allPlayers.firstWhere((p) => p.name == target.name, orElse: () => target);

    if (!realTarget.isAlive) return realTarget;

    final String roleLower = realTarget.role?.toLowerCase() ?? "";

    // --- CORRECTION POINT 11 : IMMUNITÉ ARCHIVISTE (SI ABSENT) ---
    // Si l'Archiviste a activé son pouvoir et est parti avec le MJ, il est intouchable.
    if (realTarget.isAwayAsMJ) {
      debugPrint("🛡️ LOG [Archiviste] : Cible absente (Switch MJ). Immunité totale.");
      return realTarget;
    }

    // PROTECTION NOCTURNE PANTIN (Standard)
    if (!isVote && roleLower == "pantin") {
      debugPrint("🛡️ LOG [Pantin] : Survit à l'attaque nocturne grâce à son immortalité.");
      return realTarget;
    }

    // CORRECTION PANTIN : Survie au PREMIER vote
    if (isVote && roleLower == "pantin") {
      if (!realTarget.hasSurvivedVote) {
        realTarget.hasSurvivedVote = true;
        debugPrint("🎭 LOG [Pantin] : Le Pantin survit à son premier vote (Joker utilisé).");
        return realTarget; // Annule l'élimination (retourne le joueur vivant)
      } else {
        debugPrint("🎭 LOG [Pantin] : Le Pantin ne possède plus de Joker. L'élimination procède.");
      }
    }

    // PROTECTION ARCHIVISTE (Bouc Émissaire)
    if (isVote && realTarget.hasScapegoatPower) {
      realTarget.hasScapegoatPower = false;
      debugPrint("🐏 LOG [Archevêque] : Bouc émissaire utilisé pour ${realTarget.name}. L'élimination est annulée.");
      return realTarget;
    }

    // MALÉDICTION DU PANTIN (Mort par vote)
    if (roleLower == "pantin" && isVote && realTarget.pantinCurseTimer == null) {
      realTarget.pantinCurseTimer = 2;
      debugPrint("🎭 LOG [Pantin] : Malédiction lancée sur le village avant de mourir.");
      // Note : Le pantin meurt réellement à la fin de la fonction
    }

    // RETOUR VOYAGEUR (Il ne meurt pas, il rentre)
    if (roleLower == "voyageur" && realTarget.isInTravel) {
      realTarget.isInTravel = false;
      realTarget.canTravelAgain = false;
      debugPrint("✈️ LOG [Voyageur] : Forcé au retour du voyage par une attaque fatale.");
      return realTarget; // Retourne le joueur vivant (mais revenu)
    }

    Player victim = realTarget;

    // LOGIQUE MAISON
    if (realTarget.isInHouse) {
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
          debugPrint("🏟️ LOG [Stade] : Le proprio est fan, il n'ouvre pas. ${realTarget.name} meurt.");
          victim = realTarget;
        } else {
          debugPrint("🏠 LOG [Maison] : Le proprio (${houseOwner.name}) se sacrifie pour ${realTarget.name} !");
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
      // --- CORRECTION POINT 10 : SEUL LE 1ER FAN COMPTE ---
      // On récupère TOUS les fans (même morts) pour déterminer l'ordre absolu
      List<Player> allFans = allPlayers.where((p) => p.isFanOfRonAldo).toList();
      allFans.sort((a, b) => a.fanJoinOrder.compareTo(b.fanJoinOrder));

      if (allFans.isNotEmpty) {
        Player firstFan = allFans.first; // Le tout premier fan de l'histoire

        if (firstFan.isAlive) {
          // Le premier fan est vivant -> Il se sacrifie
          victim = firstFan;
          debugPrint("🛡️ LOG [Ron-Aldo] : Le Premier Fan (${victim.name}) se sacrifie !");
          TrophyService.checkAndUnlockImmediate(
            context: context,
            playerName: victim.name,
            achievementId: "fan_sacrifice",
            checkData: {'is_fan_sacrifice': true},
          );
        } else {
          // Le premier fan est mort -> Personne d'autre ne peut intervenir
          debugPrint("🛡️ LOG [Ron-Aldo] : Le Premier Fan est déjà mort. Les suivants ne peuvent pas intervenir.");
          victim = realTarget; // Ron-Aldo meurt
        }
      }
    }

    // CHECK SUCCÈS CHAMAN (SNIPER)
    // On valide ici car la mort est confirmée.
    if (isVote && nightChamanTarget != null && victim.name == nightChamanTarget!.name) {
      debugPrint("🎯 LOG [Chaman] : Sniper validé (Cible ${victim.name} tuée au vote).");
      chamanSniperAchieved = true;
    }

    victim.isAlive = false;
    debugPrint("💀 LOG [Mort] : ${victim.name} (${victim.role}) a quitté la partie.");

    // --- CORRECTION POKÉMON (Vengeance au Vote) ---
    // Si le Pokémon meurt (peu importe la source), il applique sa vengeance
    if ((victim.role?.toLowerCase() == "pokémon" || victim.role?.toLowerCase() == "pokemon") &&
        victim.pokemonRevengeTarget != null) {

      // On cherche la cible de vengeance
      try {
        Player revengeTarget = allPlayers.firstWhere((p) => p.name == victim.pokemonRevengeTarget!.name);

        if (revengeTarget.isAlive) {
          debugPrint("⚡ LOG [Pokémon] : MORT (Vote/Nuit)! Il emporte ${revengeTarget.name} dans la tombe.");
          // On tue la cible de vengeance immédiatement
          // isVote: false car ce n'est pas un vote, c'est une conséquence
          eliminatePlayer(context, allPlayers, revengeTarget, isVote: false);
        }
      } catch (e) {
        debugPrint("⚠️ Erreur Vengeance Pokémon : Cible introuvable.");
      }
    }
    // ----------------------------------------------

    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      firstDeadPlayerName = victim.name;
    }
    AchievementLogic.checkFirstBlood(victim);

    if (roleLower == "pokémon" && globalTurnNumber == 1 && !isDayTime) {
      pokemonDiedTour1 = true;
    }

    // TRIGGER SUCCÈS MORT (Ce n'est pas très efficace...)
    AchievementLogic.checkDeathAchievements(victim, allPlayers);

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
      p.team = getTeamForRole(p.role ?? ""); // Utilisation du helper
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
    p.pokemonRevengeTarget = null;
    p.hasBakedQuiche = false;
    p.isVillageProtected = false;
    p.archivisteActionsUsed = [];
    p.canacleanPresent = false;
    p.isHouseDestroyed = false;
    p.hasSurvivedVote = false; // Init joker Pantin
    p.isAwayAsMJ = false; // Init immunité Archiviste

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

    if (activeFactions.length > 1) {
      // DEBUG: Afficher pourquoi ça ne finit pas ou pourquoi ça finit mal
      debugPrint("⚔️ LOG [Fin] : Factions restantes : $activeFactions");
      return null;
    }

    final winner = activeFactions.length == 1 ? activeFactions.first : null;
    if (winner != null) debugPrint("🏆 LOG [Fin] : VICTOIRE DE LA FACTION : $winner");

    return winner;
  }
}