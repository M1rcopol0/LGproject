import 'package:flutter/material.dart';
import 'models/player.dart';
import 'trophy_service.dart';
import 'globals.dart';

class AchievementLogic {
  /// Traqueur de trahison : Noms des fans ayant voté contre Ron-Aldo ce tour-ci.
  static List<String> _traitorsThisTurn = [];

  /// Traqueur d'électrocutions : Map<NomDeLaCible, NombreDeFoisChoquée>
  static final Map<String, int> _shockTracker = {};

  // ==========================================================
  // 1. ÉVÉNEMENTS DE FIN DE PARTIE (VICTOIRE)
  // ==========================================================

  /// Vérifie les succès liés à la victoire (appelé à l'écran de fin)
  static void checkEndGameAchievements(List<Player> winners, List<Player> allPlayers) {
    if (winners.isEmpty) return;

    for (var p in winners) {
      // Succès basiques
      TrophyService.unlockAchievement(p.name, "first_win");

      if (p.team == "village") TrophyService.unlockAchievement(p.name, "village_hero");
      if (p.team == "loups") TrophyService.unlockAchievement(p.name, "wolf_pack");
      if (p.team == "solo") TrophyService.unlockAchievement(p.name, "lone_wolf");

      // --- MAÎTRE SANS POKÉMON ---
      // Le Dresseur gagne ALORS QUE son Pokémon est mort
      if (p.role?.toLowerCase() == "dresseur") {
        try {
          var pokemon = allPlayers.firstWhere(
                  (pl) => pl.role?.toLowerCase() == "pokémon" || pl.role?.toLowerCase() == "pokemon",
              orElse: () => Player(name: "Unknown", isAlive: true)
          );
          if (pokemon.name != "Unknown" && !pokemon.isAlive) {
            debugPrint("💔 LOG [Achievement] : Maître sans Pokémon validé pour ${p.name}.");
            TrophyService.unlockAchievement(p.name, "master_no_pokemon");
          }
        } catch (e) {
          debugPrint("⚠️ Erreur check Maître sans Pokémon : $e");
        }
      }

      // --- UN TIR DU PARKING (Validation finale) ---
      // Le Dingo doit gagner ET avoir réussi son tir légendaire
      // On utilise le flag global car p.parkingShotUnlocked n'est pas forcément persistant sur la copie 'winners'
      if (p.role?.toLowerCase() == "dingo" && (p.parkingShotUnlocked || parkingShotUnlocked)) {
        debugPrint("🎯 LOG [Achievement] : Tir du Parking confirmé par la victoire !");
        TrophyService.unlockAchievement(p.name, "parking_shot");
      }
    }
  }

  // ==========================================================
  // 2. ÉVÉNEMENTS DE MORT ET RÉSILIENCE
  // ==========================================================

  /// Vérifie les succès liés à la mort d'un joueur (appelé par eliminatePlayer)
  static void checkDeathAchievements(Player victim, List<Player> allPlayers) {
    final roleLower = victim.role?.toLowerCase() ?? "";

    // --- CORRECTION "PAS TRÈS EFFICACE" ---
    // Vérification robuste (avec ou sans accent)
    if (roleLower == "pokémon" || roleLower == "pokemon") {
      debugPrint("📢 LOG [Achievement] : Pokémon mort détecté. Tentative déblocage 'not_very_effective'.");
      TrophyService.unlockAchievement(victim.name, "not_very_effective");
    }

    // Martyr (Mort au tour 1)
    if (globalTurnNumber == 1) {
      TrophyService.unlockAchievement(victim.name, "martyr");
    }

    checkFirstBlood(victim);
  }

  /// Gère la première mort de la partie
  static void checkFirstBlood(Player victim) {
    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      debugPrint("🩸 LOG [Achievement] : First Blood par ${victim.name} !");
      TrophyService.unlockAchievement(victim.name, "first_blood");
    }
  }

  /// CORRECTION : UN TIR DU PARKING (Condition de tir)
  /// Vérifie si le tir tue le dernier ennemi. Ne débloque pas encore le succès (attente victoire).
  static void checkParkingShot(Player dingo, Player victim, List<Player> allPlayers) {
    if (dingo.role?.toLowerCase() != "dingo") return;

    bool isEnemy = (victim.team == "loups" || victim.team == "solo");

    if (isEnemy) {
      // On vérifie s'il reste d'autres ennemis vivants
      bool otherEnemiesAlive = allPlayers.any((p) =>
      p.isAlive &&
          p.name != victim.name && // On ne compte pas la victime actuelle
          p.name != dingo.name && // On ne compte pas le Dingo (si jamais il est solo)
          (p.team == "loups" || p.team == "solo")
      );

      if (!otherEnemiesAlive) {
        debugPrint("🎯 LOG [Achievement] : Condition Tir du Parking remplie (Dernier ennemi abattu). Attente victoire...");
        dingo.parkingShotUnlocked = true;
        parkingShotUnlocked = true; // Global flag pour persistance
      }
    }
  }

  /// Vérifie simplement si le tir est possible (Debug/Interface)
  static void checkParkingShotCondition(Player dingo, Player victim, List<Player> allPlayers) {
    // Redirection vers la vraie méthode
    checkParkingShot(dingo, victim, allPlayers);
  }

  /// Gère le sacrifice d'un Fan (mort à la place de Ron-Aldo)
  static void checkFanSacrifice(Player deadFan, Player ronAldo) {
    if (deadFan.isFanOfRonAldo) {
      if (ronAldo.isAlive) {
        debugPrint("🛡️ LOG [Achievement] : Sacrifice de fan détecté (${deadFan.name}).");
        fanSacrificeAchieved = true;
        // Succès : Sacrifice de Fan (Le fan meurt pour sauver Ron-Aldo)
        TrophyService.unlockAchievement(deadFan.name, "fan_sacrifice");

        // Succès : Sacrifice Ultime (Le fan meurt alors qu'il a voté contre Ron-Aldo, ET Ron-Aldo aussi ?)
        // Si les deux ciblent Ron-Aldo
        if (ronAldo.targetVote == ronAldo && deadFan.targetVote == ronAldo) {
          debugPrint("👑 LOG [Achievement] : SACRIFICE ULTIME débloqué pour ${deadFan.name} !");
          ultimateFanAchieved = true;
          TrophyService.unlockAchievement(deadFan.name, "ultimate_fan");
        }
      }
    }
  }

  /// Vérifie le succès Fringale Nocturne lors du vote du village
  static void checkEvolvedHunger(Player votedPlayer) {
    if (nightWolvesTarget != null &&
        votedPlayer.name == nightWolvesTarget!.name &&
        nightWolvesTargetSurvived) {
      debugPrint("🥩 LOG [Achievement] : Fringale Nocturne validée sur ${votedPlayer.name}.");
      evolvedHungerAchieved = true;
    }
  }

  /// Gère la mort par destruction de Maison
  static void checkHouseCollapse(Player houseOwner) {
    debugPrint("🏚️ LOG [Achievement] : House Collapse pour ${houseOwner.name}.");
    TrophyService.unlockAchievement(houseOwner.name, "house_collapse");
  }

  /// Marque un Pokémon comme ressuscité pour le succès "Phénix Électrique"
  static void recordRevive(Player revivedPlayer) {
    if (revivedPlayer.role?.toLowerCase() == "pokémon" || revivedPlayer.role?.toLowerCase() == "pokemon") {
      debugPrint("🐦 LOG [Achievement] : Phénix Électrique en cours pour ${revivedPlayer.name}.");
      revivedPlayer.wasRevivedInThisGame = true;
    }
  }

  // ==========================================================
  // 3. ACTIONS DE JEU ET POUVOIRS (LOGIQUE MÉTIER)
  // ==========================================================

  /// CORRECTION : APOLLO 13
  static void checkApollo13(Player houston, Player p1, Player p2) {
    bool teamsAreDifferent = (p1.team != p2.team);

    if (teamsAreDifferent) {
      bool p1NotVillage = p1.team != "village";
      bool p2NotVillage = p2.team != "village";

      if (p1NotVillage && p2NotVillage) {
        debugPrint("🚀 LOG [Achievement] : APOLLO 13 validé pour ${houston.name} !");
        TrophyService.unlockAchievement(houston.name, "apollo_13");
        houston.houstonApollo13Triggered = true;
      }
    }
  }

  /// GESTION VOYAGEUR : Gain de munitions
  static void updateVoyageur(Player voyageur) {
    if (voyageur.isInTravel) {
      voyageur.travelNightsCount++;
      if (voyageur.travelNightsCount % 2 == 0) {
        voyageur.travelerBullets++;
        debugPrint("✈️ LOG [Voyageur] : ${voyageur.name} gagne une munition ! (Total: ${voyageur.travelerBullets})");
      } else {
        debugPrint("✈️ LOG [Voyageur] : ${voyageur.name} voyage depuis ${voyageur.travelNightsCount} nuits.");
      }
    }
  }

  /// CORRECTION CANACLEAN : Même équipe et vivants
  static void checkCanacleanCondition(List<Player> players) {
    const requiredNames = ["Clara", "Gabriel", "Jean", "Marc"];

    for (var p in players.where((p) => p.isAlive)) {
      List<Player> mates = players.where((target) =>
          requiredNames.contains(target.name)
      ).toList();

      if (mates.length == 4) {
        bool allSameTeamAndAlive = mates.every((m) => m.team == p.team && m.isAlive);
        if (allSameTeamAndAlive) {
          debugPrint("🧴 LOG [Achievement] : Condition CANACLEAN remplie pour ${p.name}.");
          p.canacleanPresent = true;
        }
      }
    }
  }

  /// Vérifie le nombre de personnes maudites pour le succès "Effet Domino"
  static void checkPantinCurses(List<Player> players) {
    int cursedCount = players.where((p) => p.isAlive && p.pantinCurseTimer != null).length;
    for (var p in players) {
      if (p.role?.toLowerCase() == "pantin" && cursedCount >= 4) {
        if (cursedCount > p.maxSimultaneousCurses) {
          debugPrint("🎭 LOG [Achievement] : Effet Domino progress : $cursedCount maudits.");
          p.maxSimultaneousCurses = cursedCount;
        }
      }
    }
  }

  /// Enregistre une électrocution du Pokémon
  static void recordShock(Player dresseurOuPokemon, Player target) {
    _shockTracker[target.name] = (_shockTracker[target.name] ?? 0) + 1;
    debugPrint("⚡ LOG [Achievement] : ${target.name} a reçu ${_shockTracker[target.name]} chocs.");

    if (_shockTracker[target.name]! >= 2) {
      debugPrint("⚡ LOG [Achievement] : Double Shock débloqué !");
      TrophyService.unlockAchievement(dresseurOuPokemon.name, "double_shock");
    }
  }

  /// Gère la trahison d'un Fan lors du vote
  static void checkTraitorFan(Player voter, Player target) {
    final targetRole = target.role?.toUpperCase().trim() ?? "";
    if (voter.isFanOfRonAldo && (targetRole == "RON-ALDO" || targetRole == "RON ALDO")) {
      if (!_traitorsThisTurn.contains(voter.name)) {
        debugPrint("🐍 LOG [Achievement] : Fan Traître détecté -> ${voter.name}");
        _traitorsThisTurn.add(voter.name);
        TrophyService.unlockAchievement(voter.name, "traitor");
      }
    }
  }

  /// Appelé par le Devin
  static void checkDevinAchievements(Player devin) {
    if (devin.hasRevealedSamePlayerTwice) {
      TrophyService.unlockAchievement(devin.name, "double_check");
    }
  }

  /// Appelé par l'Enculateur du Bled
  static void checkBledAchievements(Player bled) {
    if (bled.protectedPlayersHistory.length >= 5) {
      TrophyService.unlockAchievement(bled.name, "sortez_couvert");
    }
  }

  /// Appelé lors d'un silence (Chuchoteur / Archiviste)
  static void recordMute(Player silencer, Player victim) {
    silencer.mutedPlayersCount++;
    if (silencer.role?.toUpperCase() == "CHUCHOTEUR" && victim.isWolf) {
      debugPrint("🎧 LOG [Achievement] : Secret de loup entendu par ${silencer.name}.");
      silencer.hasHeardWolfSecrets = true;
      TrophyService.unlockAchievement(silencer.name, "chuchoteur_wolf_ear");
    }
  }

  /// Appelé si Phyl change de rôle
  static void recordPhylChange(Player phyl) {
    phyl.roleChangesCount++;
    debugPrint("🧬 LOG [Achievement] : Phyl a changé de rôle (${phyl.roleChangesCount} fois).");
  }

  // ==========================================================
  // 4. LOGIQUE DE TRANSITION ET RESET
  // ==========================================================

  /// Nettoie les données volatiles à chaque fin de tour
  static void clearTurnData() {
    debugPrint("🧹 LOG [Achievement] : Nettoyage des données de tour.");
    _traitorsThisTurn.clear();
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
  }

  /// Reset complet pour une nouvelle partie
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