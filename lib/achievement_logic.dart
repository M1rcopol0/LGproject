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

  /// Gère le sacrifice d'un Fan (mort à la place de Ron-Aldo)
  static void checkFanSacrifice(Player deadFan, Player ronAldo) {
    // SEUL un fan peut débloquer ces succès, pas Ron-Aldo lui-même
    if (deadFan.isFanOfRonAldo) {
      // Succès : Garde du Corps (Simple sacrifice)
      fanSacrificeAchieved = true;
      TrophyService.unlockAchievement(deadFan.name, "fan_sacrifice");

      // Succès : Fan Ultime
      // Conditions : Le fan a voté contre Ron-Aldo ce tour-ci
      // ET Ron-Aldo a voté contre lui-même.
      if (_traitorsThisTurn.contains(deadFan.name) && ronAldo.targetVote == ronAldo) {
        ultimateFanAchieved = true;
        TrophyService.unlockAchievement(deadFan.name, "ultimate_fan");
      }
    }
  }

  /// Vérifie le succès Fringale Nocturne lors du vote du village
  static void checkEvolvedHunger(Player votedPlayer) {
    // Si la cible des loups de cette nuit (qui a survécu) est celle qui meurt au vote
    if (nightWolvesTarget != null &&
        votedPlayer.name == nightWolvesTarget!.name &&
        nightWolvesTargetSurvived) {
      evolvedHungerAchieved = true;
      // Le succès sera attribué aux loups dans l'écran de fin
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

  /// Nettoie les données volatiles à chaque fin de tour (après le vote)
  static void clearTurnData() {
    _traitorsThisTurn.clear();
    // On reset le tracking de la cible des loups pour le prochain tour
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
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
  }
}