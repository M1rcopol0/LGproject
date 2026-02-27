import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';
import 'achievement_logic.dart';

class TurnLogic {
  static void nextTurn(List<Player> allPlayers) {
    debugPrint("--------------------------------------------------");

    isDayTime = false;

    debugPrint("🔄 LOG [GameLogic] : Nettoyage avant la NUIT (Tour actuel : $globalTurnNumber)...");

    AchievementLogic.checkCanacleanCondition(null, allPlayers);
    AchievementLogic.clearTurnData();
    _enforceMaisonFanPolicy(allPlayers);

    nightChamanTarget = null;
    nightWolvesTarget = null;
    nightWolvesTargetSurvived = false;
    quicheSavedThisNight = 0;

    for (var p in allPlayers) {
      p.votes = 0;
      p.targetVote = null;

      if (!p.isAlive) {
        p.pantinCurseTimer = null;
        p.hasBeenHitByDart = false;
        p.zookeeperEffectReady = false;
        p.hasBakedQuiche = false;
        // isVillageProtected n'est PAS effacé ici : la quiche fait effet
        // même si la grand-mère est morte (elle a cuisiné avant de mourir).
        // La machine d'état dans NightCleanup gère l'expiration.
        continue;
      }

      p.isImmunizedFromVote = false;
      p.isVoteCancelled = false;
      p.isMutedDay = false;
      p.powerActiveThisTurn = false;
      p.resetTemporaryStates();
    }

    debugPrint("🌙 LOG [GameLogic] : Transition terminée.");
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
}
