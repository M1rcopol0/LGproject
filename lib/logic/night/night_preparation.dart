import 'package:flutter/material.dart';
import '../../../../models/player.dart';
import '../../../../globals.dart';
import '../../../../achievement_logic.dart';

class NightPreparation {
  static void run(List<Player> players) {
    debugPrint("--------------------------------------------------");
    debugPrint("🌙 LOG [Logic] : Préparation de la Nuit $globalTurnNumber");

    for (var p in players) {
      // --- LOGIQUE BOMBE TARDOS ---
      if (p.hasPlacedBomb && p.tardosTarget != null && p.bombTimer > 0) {
        p.bombTimer--;
        debugPrint("💣 LOG [Tardos] : La bombe de ${p.name} tic-tac... (T-Minus: ${p.bombTimer})");
      }

      // --- LOGIQUE BOMBE MANUELLE ---
      if (p.isBombed && p.attachedBombTimer > 0) {
        // Double sécurité pour éviter conflit avec Tardos
        bool targetedByTardos = players.any((attacker) =>
        attacker.role?.toLowerCase() == "tardos" &&
            attacker.hasPlacedBomb &&
            attacker.tardosTarget == p);

        if (!targetedByTardos) {
          p.attachedBombTimer--;
          debugPrint("🧨 LOG [MJ] : Bombe manuelle sur ${p.name} tic-tac... (T-Minus: ${p.attachedBombTimer})");
        }
      }

      // --- LOGIQUE VOYAGEUR ---
      if (p.role?.toLowerCase() == "voyageur" && p.isInTravel) {
        AchievementLogic.updateVoyageur(p);
      }

      if (!p.isAlive) continue;

      // --- LOGIQUE ZOOKEEPER ---
      if (p.hasBeenHitByDart) {
        if (p.zookeeperEffectReady) {
          p.isEffectivelyAsleep = true;
          p.zookeeperEffectReady = false;
          p.powerActiveThisTurn = true;
          debugPrint("💉 LOG [Zookeeper] : ${p.name} succombe au venin. Sommeil activé.");
        } else if (p.isEffectivelyAsleep && !p.powerActiveThisTurn) {
          p.isEffectivelyAsleep = false;
          p.hasBeenHitByDart = false;
          debugPrint("🌅 LOG [Zookeeper] : ${p.name} se réveille du venin.");
        }
      }

      // --- LOGIQUE PANTIN ---
      if (p.pantinCurseTimer != null && p.pantinCurseTimer! > 0) {
        p.pantinCurseTimer = p.pantinCurseTimer! - 1;
        debugPrint("🎭 LOG [Pantin] : Malédiction sur ${p.name} (Timer: ${p.pantinCurseTimer})");
      }
    }
    debugPrint("--------------------------------------------------");
  }
}