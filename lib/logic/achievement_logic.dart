import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

// Sous-modules
import 'achievement_scanner.dart';
import 'achievement_events.dart';

// Re-exports pour les fichiers qui importent directement les sous-modules
export 'achievement_scanner.dart';
export 'achievement_events.dart';

class AchievementLogic {
  static List<String> _traitorsThisTurn = [];

  // --- Scanner (mid-game + end-game) ---
  static Future<void> checkMidGameAchievements(BuildContext context, List<Player> allPlayers) =>
      AchievementScanner.checkMidGameAchievements(context, allPlayers);

  static Future<void> checkEndGameAchievements(BuildContext context, List<Player> winners, List<Player> allPlayers) =>
      AchievementScanner.checkEndGameAchievements(context, winners, allPlayers);

  // --- Evenements manuels ---
  static void trackVote(Player voter, Player target) =>
      AchievementEvents.trackVote(voter, target);

  static void checkDeathAchievements(BuildContext? context, Player victim, List<Player> allPlayers) =>
      AchievementEvents.checkDeathAchievements(context, victim, allPlayers);

  static void checkHouseCollapse(BuildContext context, Player houseOwner) =>
      AchievementEvents.checkHouseCollapse(context, houseOwner);

  static void checkFirstBlood(BuildContext context, Player victim) =>
      AchievementEvents.checkFirstBlood(context, victim);

  static void recordRevive(Player revivedPlayer) =>
      AchievementEvents.recordRevive(revivedPlayer);

  static void checkApollo13(BuildContext context, Player houston, Player p1, Player p2) =>
      AchievementEvents.checkApollo13(context, houston, p1, p2);

  static void checkParkingShot(BuildContext? context, Player dingo, Player victim, List<Player> allPlayers) =>
      AchievementEvents.checkParkingShot(context, dingo, victim, allPlayers);

  static void checkFanSacrifice(BuildContext context, Player victim, Player savedPlayer) =>
      AchievementEvents.checkFanSacrifice(context, victim, savedPlayer);

  static void checkEvolvedHunger(BuildContext context, Player votedPlayer, List<Player> allPlayers) =>
      AchievementEvents.checkEvolvedHunger(context, votedPlayer, allPlayers);

  static void checkDevinAchievements(BuildContext context, Player devin) =>
      AchievementEvents.checkDevinAchievements(context, devin);

  static void checkBledAchievements(BuildContext context, Player bled, int totalPlayers) =>
      AchievementEvents.checkBledAchievements(context, bled, totalPlayers);

  static void checkCanacleanCondition(BuildContext? context, List<Player> players) =>
      AchievementEvents.checkCanacleanCondition(context, players);

  static void checkWelcomeWolf(BuildContext context, Player maison) =>
      AchievementEvents.checkWelcomeWolf(context, maison);

  static void checkTraitorFan(BuildContext context, Player voter, Player target) {
    AchievementEvents.checkTraitorFan(context, voter, target);
    final targetRole = target.role?.toUpperCase().trim() ?? "";
    if (voter.isFanOfRonAldo && (targetRole == "RON-ALDO" || targetRole == "RON ALDO")) {
      if (!_traitorsThisTurn.contains(voter.name)) {
        _traitorsThisTurn.add(voter.name);
      }
    }
  }

  static void checkTardosOups(BuildContext context, Player tardos) =>
      AchievementEvents.checkTardosOups(context, tardos);

  static void checkClutchManual(BuildContext context, Player pantin) =>
      AchievementEvents.checkClutchManual(context, pantin);

  static Future<void> checkArchivisteEndGame(BuildContext context, Player p) =>
      AchievementEvents.checkArchivisteEndGame(context, p);

  static void updateVoyageur(Player voyageur) =>
      AchievementEvents.updateVoyageur(voyageur);

  static void recordPhylChange(Player phyl) =>
      AchievementEvents.recordPhylChange(phyl);

  // --- Gestion d'etat ---
  static void clearTurnData() {
    _traitorsThisTurn.clear();
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
  }

  static void resetFullGameData() {
    debugPrint("🔄 LOG [Achievement] : RESET COMPLET DES SUCCÈS.");
    _traitorsThisTurn.clear();
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
