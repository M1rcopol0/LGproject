import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/logic/achievement_logic.dart';
import 'package:fluffer/services/trophy_service.dart';
import 'package:fluffer/globals.dart';

class NightInfoGenerator {

  static void processSpecialRoles(BuildContext context, List<Player> players, Map<Player, String> pendingDeathsMap) {
    // --- 1. MAÎTRE DU TEMPS ---
    for (var p in players) {
      if (p.role?.toLowerCase() == "maître du temps" && p.isAlive && p.timeMasterTargets.isNotEmpty) {
        debugPrint("⏳ LOG [TimeMaster] : Exécution des cibles : ${p.timeMasterTargets}");
        List<Player> killedByTime = [];
        for (var targetName in p.timeMasterTargets) {
          try {
            Player target = players.firstWhere((t) => t.name == targetName);
            if (target.isAlive) {
              debugPrint("⏳ CAPTEUR [Action] : TimeMaster efface ${target.name} (${target.role}) du temps.");
              pendingDeathsMap[target] = "Effacé du temps (Maître du Temps)";
              killedByTime.add(target);
            }
          } catch (_) {}
        }
        if (killedByTime.length >= 2) {
          Set<String> teams = killedByTime.map((kp) => kp.team).toSet();
          if (teams.length >= 2) {
            debugPrint("⏳ CAPTEUR [Action] : PARADOXE TEMPOREL détecté ! Équipes: $teams");
            paradoxAchieved = true;
            TrophyService.checkAndUnlockImmediate(context: context, playerName: p.name, achievementId: "time_paradox", checkData: {'player_role': 'Maître du temps', 'paradox_achieved': true});
          }
        }
        p.timeMasterTargets.clear();
      }
    }

    // --- 2. MAISON (EPSTEIN & RON-ALDO) ---
    try {
      Player? maison;
      try {
        maison = players.firstWhere((p) => (p.role?.toLowerCase() == "maison" || p.previousRole?.toLowerCase() == "maison") && p.isAlive);
      } catch (_) {}

      if (maison != null) {
        maison.hostedEnemiesCount = 0;
        maison.hostedRonAldoThisTurn = false;
        List<Player> invites = players.where((p) => p.isInHouse).toList();
        debugPrint("🏠 CAPTEUR [Action] : Maison (${maison.name}) a ${invites.length} invité(s): ${invites.map((i) => '${i.name}(${i.team})').join(', ')}");
        for (var invite in invites) {
          if (invite.team != "village") {
            debugPrint("🏠 CAPTEUR [Action] : Invité ennemi détecté: ${invite.name} (${invite.team})");
            maison.hostedEnemiesCount++;
          }
          if (invite.role?.toLowerCase() == "ron-aldo") {
            debugPrint("🏠 CAPTEUR [Action] : Ron-Aldo hébergé dans la Maison.");
            maison.hostedRonAldoThisTurn = true;
            invite.hostedRonAldoThisTurn = true;
          }
        }
        if (maison.hostedEnemiesCount >= 2) {
          TrophyService.checkAndUnlockImmediate(context: context, playerName: maison.name, achievementId: "epstein_house", checkData: {'player_role': 'maison', 'hosted_enemies_count': maison.hostedEnemiesCount});
        }
      }
    } catch (_) {}
  }

  static List<String> generateAnnouncements(
      BuildContext context,
      List<Player> players,
      List<String> playersToReveal,
      Map<Player, String> pendingDeathsMap
      ) {
    List<String> announcements = [];

    // --- VOYAGEUR ---
    for (var p in players) {
      if (p.role?.toLowerCase() == "voyageur") {
        // 1. Retour Volontaire
        if (p.hasReturnedThisTurn) {
          debugPrint("🌍 CAPTEUR [Action] : Voyageur retour volontaire au village.");
          announcements.add("🌍 Le Voyageur est de retour au village !");
        }
        // 2. Interception (Retour Forcé) - SEULEMENT SI CIBLÉ CETTE NUIT
        else if (p.isAlive) {
          // On vérifie s'il est ciblé par une attaque alors qu'il est en voyage
          // C'est ce qui provoque l'interception.
          // Si on vérifie juste !canTravelAgain, le message restera à jamais.

          bool targetedWhileTraveling = p.isInTravel && pendingDeathsMap.containsKey(p);

          if (targetedWhileTraveling) {
            debugPrint("🌍 CAPTEUR [Action] : Voyageur intercepté (ciblé en voyage).");
            String msg = "🚫 Le Voyageur a été intercepté et forcé de rentrer !";
            if (!announcements.contains(msg)) announcements.add(msg);

            // BUG 11 FIX : Ne PAS modifier isInTravel ici.
            // eliminatePlayer vérifie isInTravel pour protéger le Voyageur.
            // Si on le met à false ici, la protection est bypassée.
          }
        }
      }
    }

    // --- HOUSTON ---
    try {
      Player houston = players.firstWhere((p) => p.role?.toLowerCase() == "houston" && p.isAlive);
      if (houston.houstonTargets.length == 2) {
        Player p1 = houston.houstonTargets[0];
        Player p2 = houston.houstonTargets[1];
        debugPrint("🛰️ CAPTEUR [Action] : Houston analyse ${p1.name} (${p1.team}) et ${p2.name} (${p2.team}). Même équipe: ${p1.team == p2.team}");
        String phrase = (p1.team == p2.team) ? "QUI VOILÀ-JE !" : "HOUSTON, ON A UN PROBLÈME !";
        announcements.add("🛰️ HOUSTON : $phrase\n(Analyse de ${p1.name} & ${p2.name})");
        AchievementLogic.checkApollo13(context, houston, p1, p2);
        houston.houstonTargets = [];
      }
    } catch (_) {}

    // --- DEVIN ---
    try {
      Player devin = players.firstWhere((p) => p.role?.toLowerCase() == "devin" && p.isAlive);
      if (devin.concentrationTargetName != null && devin.concentrationNights >= 2) {
        debugPrint("👁️ CAPTEUR [Action] : Devin révélation prête. Cible: ${devin.concentrationTargetName}, nuits: ${devin.concentrationNights}.");
        Player? target = players.firstWhere((p) => p.name == devin.concentrationTargetName, orElse: () => Player(name: "Inconnu"));
        if (target.name != "Inconnu") {
          debugPrint("👁️ CAPTEUR [Action] : Devin révèle ${target.name} = ${target.role}.");
          announcements.add("👁️ DEVIN : ${target.name} est ${target.role?.toUpperCase()}");
          playersToReveal.add(target.name);
          devin.devinRevealsCount++;
          if (devin.revealedPlayersHistory.contains(target.name)) {
            debugPrint("👁️ CAPTEUR [Action] : Devin double check détecté pour ${target.name}.");
            devin.hasRevealedSamePlayerTwice = true;
            AchievementLogic.checkDevinAchievements(context, devin);
          }
          devin.revealedPlayersHistory.add(target.name);
          devin.concentrationTargetName = null;
          devin.concentrationNights = 0;
        }
      } else if (devin.concentrationTargetName != null) {
        debugPrint("👁️ CAPTEUR [Action] : Devin concentration en cours sur ${devin.concentrationTargetName}. Nuits: ${devin.concentrationNights}/2.");
      }
    } catch (_) {}

    return announcements;
  }
}