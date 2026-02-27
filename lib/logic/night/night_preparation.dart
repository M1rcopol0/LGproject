import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/globals.dart';
import 'package:fluffer/logic/achievement_logic.dart';

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

      // --- LOGIQUE BOMBE (Tardos ou manuelle) ---
      if (p.isBombed && p.attachedBombTimer > 0) {
        p.attachedBombTimer--;
        debugPrint("💣 LOG [Bombe] : Compte à rebours sur ${p.name} : T-${p.attachedBombTimer}");
      }

      // --- RESET DES POUVOIRS NOCTURNES DE L'ARCHIVISTE (réutilisables chaque nuit) ---
      if (p.role?.toLowerCase() == "archiviste") {
        // S'assurer que la liste est mutable (peut être const [] si jamais modifiée)
        p.archivisteActionsUsed = List<String>.from(p.archivisteActionsUsed)
          ..remove("cancel_vote")
          ..remove("mute");
        debugPrint("📖 LOG [Archiviste] : Pouvoirs nocturnes (mute, cancel_vote) réinitialisés pour ${p.name}.");
      }

      if (!p.isAlive) continue;

      // --- LOGIQUE VOYAGEUR ---
      if (p.role?.toLowerCase() == "voyageur" && p.isInTravel) {
        AchievementLogic.updateVoyageur(p);
      }

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