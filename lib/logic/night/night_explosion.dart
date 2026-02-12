import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/achievement_logic.dart';
import 'package:fluffer/trophy_service.dart';
import 'package:fluffer/logic.dart'; // Pour GameLogic.eliminatePlayer

class NightExplosion {
  static void handle({
    required BuildContext context,
    required List<Player> allPlayers,
    required Player target,
    required Map<Player, String> pendingDeathsMap,
    required String reason,
    required Player? attacker,
    List<String>? announcements,
  }) {
    debugPrint("💥 LOG [Explosion] : BOUM sur ${target.name} !");

    if (announcements != null) {
      announcements.add("💥 UNE BOMBE A EXPLOSÉ SUR ${target.name.toUpperCase()} !");
    }

    if (attacker != null && target == attacker) {
      debugPrint("💥 CAPTEUR [Mort] : Tardos suicide ! ${attacker.name} se bombarde lui-même.");
      attacker.tardosSuicide = true;
      AchievementLogic.checkTardosOups(context, attacker);
    }

    if (target.role?.toLowerCase() == "maison" || target.isInHouse) {
      debugPrint("🏠💥 LOG [Explosion] : Dégâts collatéraux (Maison).");
      if (announcements != null) announcements.add("🏠 La maison a été soufflée par l'explosion !");

      Player? houseOwner;
      try {
        houseOwner = allPlayers.firstWhere((h) => h.role?.toLowerCase() == "maison");
        pendingDeathsMap[houseOwner] = reason;
      } catch (e) {}

      var occupants = allPlayers.where((o) => o.isInHouse).toList();
      debugPrint("💥 CAPTEUR [Mort] : Occupants de la Maison: ${occupants.map((o) => '${o.name}(${o.role})').join(', ')}.");
      for (var occupant in occupants) {
        pendingDeathsMap[occupant] = "Effondrement Maison (Explosion)";
      }

      // --- SUCCÈS ---
      if (houseOwner != null && occupants.isNotEmpty) {
        if (attacker != null && attacker.role?.toLowerCase() == "tardos") {
          TrophyService.checkAndUnlockImmediate(
              context: context,
              playerName: attacker.name,
              achievementId: "11_septembre",
              checkData: {'11_septembre_triggered': true});

          if (pendingDeathsMap.containsKey(attacker)) {
            TrophyService.checkAndUnlockImmediate(
                context: context,
                playerName: attacker.name,
                achievementId: "self_destruct",
                checkData: {'self_destruct_triggered': true});
          }
        }
      }
    } else if (target.isAlive) {
      pendingDeathsMap[target] = reason;
    }

    target.isBombed = false;
    target.attachedBombTimer = 0;
  }
}