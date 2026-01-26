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
  // 1. ÉVÉNEMENTS DE MORT ET RÉSILIENCE
  // ==========================================================

  /// Gère la première mort de la partie
  static void checkFirstBlood(Player victim) {
    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      debugPrint("🩸 LOG [Achievement] : First Blood par ${victim.name} !");
      TrophyService.unlockAchievement(victim.name, "first_blood");
    }
  }

  /// CORRECTION DINGO : Un tir du parking
  /// Vérifie si le tir élimine le dernier ennemi du village.
  static void checkParkingShot(Player dingo, Player victim, List<Player> allPlayers) {
    if (dingo.role?.toLowerCase() != "dingo") return;

    // On vérifie s'il reste des ennemis hostiles au village (Loups ou Solo)
    // On exclut la victime qui est en train de mourir et le Dingo lui-même
    bool enemiesLeft = allPlayers.any((p) =>
    p.isAlive &&
        p.name != victim.name &&
        p.name != dingo.name &&
        (p.team == "loups" || p.team == "solo")
    );

    // Si la cible était hostile et que c'était le dernier rempart ennemi
    if (!enemiesLeft && (victim.team == "loups" || victim.team == "solo")) {
      debugPrint("🎯 LOG [Achievement] : UN TIR DU PARKING ! ${dingo.name} finit la game.");

      // On marque le flag GLOBAL pour les stats de fin de partie
      parkingShotUnlocked = true;

      // IMPORTANT : On marque le joueur DINGO spécifiquement pour qu'il soit le seul à recevoir le succès
      dingo.parkingShotUnlocked = true;

      TrophyService.unlockAchievement(dingo.name, "parking_shot");
    } else {
      debugPrint("🎯 LOG [Dingo] : Tir réussi, mais il reste des ennemis. Pas de Parking Shot.");
    }
  }

  /// Gère le sacrifice d'un Fan (mort à la place de Ron-Aldo)
  static void checkFanSacrifice(Player deadFan, Player ronAldo) {
    if (deadFan.isFanOfRonAldo) {
      debugPrint("🛡️ LOG [Achievement] : Sacrifice de fan détecté (${deadFan.name}).");
      fanSacrificeAchieved = true;
      TrophyService.unlockAchievement(deadFan.name, "fan_sacrifice");

      // Succès "Ultimate Fan" (Sacrifice + Trahison au vote + Ron-Aldo qui vote pour lui-même)
      if (_traitorsThisTurn.contains(deadFan.name) && ronAldo.targetVote == ronAldo) {
        debugPrint("👑 LOG [Achievement] : ULTIMATE FAN débloqué pour ${deadFan.name} !");
        ultimateFanAchieved = true;
        TrophyService.unlockAchievement(deadFan.name, "ultimate_fan");
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
    if (revivedPlayer.role?.toUpperCase() == "POKÉMON") {
      debugPrint("🐦 LOG [Achievement] : Phénix Électrique en cours pour ${revivedPlayer.name}.");
      revivedPlayer.wasRevivedInThisGame = true;
    }
  }

  // ==========================================================
  // 2. ACTIONS DE JEU ET POUVOIRS (LOGIQUE MÉTIER)
  // ==========================================================

  /// GESTION VOYAGEUR : Gain de munitions
  /// Doit être appelé à chaque "prepareNightStates" ou fin de tour
  static void updateVoyageur(Player voyageur) {
    if (voyageur.isInTravel) {
      voyageur.travelNightsCount++;
      // 1 balle tous les 2 jours passés dehors (ex: Nuit 2, Nuit 4...)
      if (voyageur.travelNightsCount % 2 == 0) {
        voyageur.travelerBullets++;
        debugPrint("✈️ LOG [Voyageur] : ${voyageur.name} gagne une munition ! (Total: ${voyageur.travelerBullets})");
      } else {
        debugPrint("✈️ LOG [Voyageur] : ${voyageur.name} voyage depuis ${voyageur.travelNightsCount} nuits.");
      }
    }
  }

  /// CORRECTION CANACLEAN : Même équipe et vivants
  /// Vérifie si Clara, Gabriel, Jean, Marc et le joueur sont vivants et ensemble.
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
      }
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
  // 3. LOGIQUE DE TRANSITION ET RESET
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