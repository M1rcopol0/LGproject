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
      TrophyService.unlockAchievement(victim.name, "first_blood");
    }
  }

  /// CORRECTION DINGO : Un tir du parking
  /// Vérifie si le tir élimine le dernier ennemi du village.
  static void checkParkingShot(Player dingo, Player victim, List<Player> allPlayers) {
    if (dingo.role?.toLowerCase() != "dingo") return;

    // On vérifie s'il reste des ennemis hostiles au village (Loups ou Solo)
    // On exclut la victime qui est en train de mourir (pas encore isAlive = false)
    bool noMoreEnemies = !allPlayers.any((p) =>
    p.isAlive &&
        p.name != victim.name &&
        (p.team == "loups" || p.team == "solo")
    );

    // Si la cible était hostile et que c'était le dernier rempart ennemi
    if (noMoreEnemies && (victim.team == "loups" || victim.team == "solo")) {
      parkingShotUnlocked = true; // Flag global utilisé dans fin.dart
      TrophyService.unlockAchievement(dingo.name, "parking_shot");
    }
  }

  /// Gère le sacrifice d'un Fan (mort à la place de Ron-Aldo)
  static void checkFanSacrifice(Player deadFan, Player ronAldo) {
    if (deadFan.isFanOfRonAldo) {
      fanSacrificeAchieved = true;
      TrophyService.unlockAchievement(deadFan.name, "fan_sacrifice");

      if (_traitorsThisTurn.contains(deadFan.name) && ronAldo.targetVote == ronAldo) {
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
      evolvedHungerAchieved = true;
    }
  }

  /// Gère la mort par destruction de Maison
  static void checkHouseCollapse(Player houseOwner) {
    TrophyService.unlockAchievement(houseOwner.name, "house_collapse");
  }

  /// Marque un Pokémon comme ressuscité pour le succès "Phénix Électrique"
  static void recordRevive(Player revivedPlayer) {
    if (revivedPlayer.role?.toUpperCase() == "POKÉMON") {
      revivedPlayer.wasRevivedInThisGame = true;
    }
  }

  // ==========================================================
  // 2. ACTIONS DE JEU ET POUVOIRS
  // ==========================================================

  /// CORRECTION CANACLEAN : Même équipe et vivants
  /// Vérifie si Clara, Gabriel, Jean, Marc et le joueur sont vivants et ensemble.
  static void checkCanacleanCondition(List<Player> players) {
    const requiredNames = ["Clara", "Gabriel", "Jean", "Marc"];

    for (var p in players.where((p) => p.isAlive)) {
      // On identifie les 4 compères dans la partie
      List<Player> mates = players.where((target) =>
          requiredNames.contains(target.name)
      ).toList();

      // Si les 4 sont présents, vivants et dans la même équipe que le joueur
      if (mates.length == 4) {
        bool allSameTeamAndAlive = mates.every((m) => m.team == p.team && m.isAlive);
        if (allSameTeamAndAlive) {
          p.canacleanPresent = true; // Marqueur pour le succès en fin de partie
        }
      }
    }
  }

  /// Vérifie le nombre de personnes maudites pour le succès "Effet Domino"
  static void checkPantinCurses(List<Player> players) {
    int cursedCount = players.where((p) => p.isAlive && p.pantinCurseTimer != null).length;
    for (var p in players) {
      if (p.role == "Pantin" && cursedCount >= 4) {
        if (cursedCount > p.maxSimultaneousCurses) {
          p.maxSimultaneousCurses = cursedCount;
        }
      }
    }
  }

  /// Enregistre une électrocution du Pokémon
  static void recordShock(Player dresseurOuPokemon, Player target) {
    _shockTracker[target.name] = (_shockTracker[target.name] ?? 0) + 1;
    if (_shockTracker[target.name]! >= 2) {
      TrophyService.unlockAchievement(dresseurOuPokemon.name, "double_shock");
    }
  }

  /// Gère la trahison d'un Fan lors du vote
  static void checkTraitorFan(Player voter, Player target) {
    final targetRole = target.role?.toUpperCase().trim() ?? "";
    if (voter.isFanOfRonAldo && (targetRole == "RON-ALDO" || targetRole == "RON ALDO")) {
      if (!_traitorsThisTurn.contains(voter.name)) {
        _traitorsThisTurn.add(voter.name);
      }
    }
  }

  /// Appelé lors d'un silence (Chuchoteur / Archiviste)
  static void recordMute(Player silencer, Player victim) {
    silencer.mutedPlayersCount++;
    if (silencer.role?.toUpperCase() == "CHUCHOTEUR" && victim.isWolf) {
      silencer.hasHeardWolfSecrets = true;
      TrophyService.unlockAchievement(silencer.name, "chuchoteur_wolf_ear");
    }
  }

  /// Appelé si Phyl change de rôle
  static void recordPhylChange(Player phyl) {
    phyl.roleChangesCount++;
  }

  // ==========================================================
  // 3. LOGIQUE DE TRANSITION ET RESET
  // ==========================================================

  /// Nettoie les données volatiles à chaque fin de tour
  static void clearTurnData() {
    _traitorsThisTurn.clear();
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
  }

  /// Reset complet pour une nouvelle partie
  static void resetFullGameData() {
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
    parkingShotUnlocked = false; // Reset du flag Dingo
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
  }
}