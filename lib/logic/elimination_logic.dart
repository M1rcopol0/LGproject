import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';
import '../achievement_logic.dart';
import '../trophy_service.dart';

class EliminationLogic {
  static Player eliminatePlayer(BuildContext context, List<Player> allPlayers, Player target,
      {bool isVote = false, String reason = ""}) {

    Player realTarget = allPlayers.firstWhere((p) => p.name == target.name, orElse: () => target);

    if (!realTarget.isAlive) return realTarget;

    final String roleLower = realTarget.role?.toLowerCase() ?? "";

    if (realTarget.isAwayAsMJ) {
      debugPrint("🛡️ LOG [Archiviste] : Cible absente (Switch MJ). Immunité totale.");
      return realTarget;
    }

    // --- LOGIQUE PANTIN ---
    if (roleLower == "pantin") {
      bool isManualKill = reason.contains("Manuel") || reason.contains("MJ");

      if (!isVote && !isManualKill) {
        debugPrint("🛡️ LOG [Pantin] : Survit à l'attaque nocturne.");
        return realTarget;
      } else if (isVote) {
        if (!realTarget.hasSurvivedVote) {
          try {
            List<Player> survivors = allPlayers.where((p) => p.isAlive).toList();
            survivors.sort((a, b) => b.votes.compareTo(a.votes));
            Player competitor = survivors.firstWhere((p) => p.name != realTarget.name, orElse: () => realTarget);
            int diff = (competitor.votes - realTarget.votes).abs();

            if (diff <= 1 && realTarget.targetVote?.name == competitor.name) {
              realTarget.pantinClutchTriggered = true;
              TrophyService.checkAndUnlockImmediate(
                context: context,
                playerName: realTarget.name,
                achievementId: "pantin_clutch",
                checkData: {'pantin_clutch_triggered': true},
              );
            }
          } catch(e) {}

          realTarget.hasSurvivedVote = true;
          debugPrint("🎭 LOG [Pantin] : Le Pantin survit à son premier vote.");
          return realTarget;
        }
      }
    }

    // --- CLUTCH PANTIN ---
    if (isVote && roleLower != "pantin") {
      try {
        Player pantin = allPlayers.firstWhere((p) => p.isAlive && p.role?.toLowerCase() == "pantin");
        List<Player> survivors = allPlayers.where((p) => p.isAlive).toList();
        survivors.sort((a, b) => b.votes.compareTo(a.votes));

        if (realTarget.name == survivors[0].name) {
          int diff = (realTarget.votes - pantin.votes).abs();
          if (diff <= 1 && pantin.targetVote?.name == realTarget.name) {
            pantin.pantinClutchTriggered = true;
            debugPrint("🎭 LOG [Pantin] : CLUTCH DÉTECTÉ pour ${pantin.name} !");

            TrophyService.checkAndUnlockImmediate(
              context: context,
              playerName: pantin.name,
              achievementId: "pantin_clutch",
              checkData: {'pantin_clutch_triggered': true},
            );
          }
        }
      } catch (e) {}
    }

    // --- CORRECTION BOUC ÉMISSAIRE ---
    if (isVote && realTarget.hasScapegoatPower) {
      realTarget.hasScapegoatPower = false;
      debugPrint("🐏 LOG [Archevêque] : Bouc émissaire consommé, mais la sentence est exécutée.");
    }

    if (roleLower == "voyageur" && realTarget.isInTravel) {
      realTarget.isInTravel = false;
      realTarget.canTravelAgain = false;
      debugPrint("✈️ LOG [Voyageur] : Forcé au retour du voyage.");
      return realTarget;
    }

    Player victim = realTarget;

    // --- LOGIQUE MAISON ---
    if (realTarget.isInHouse && !reason.contains("Malédiction")) {
      Player? houseOwner;
      try {
        houseOwner = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "maison" && p.isAlive && !p.isHouseDestroyed);
      } catch (e) { houseOwner = null; }

      if (houseOwner != null) {
        if (houseOwner.isFanOfRonAldo) {
          debugPrint("🏠 CAPTEUR [Mort] : Maison fan de Ron-Aldo -> pas d'effondrement, cible directe: ${realTarget.name}.");
          victim = realTarget;
        } else {
          victim = houseOwner;
          houseOwner.isHouseDestroyed = true;
          for (var p in allPlayers) { p.isInHouse = false; }
          victim.isAlive = false;
          AchievementLogic.checkHouseCollapse(context, houseOwner);
          debugPrint("🏠 LOG [Maison] : Effondrement ! Le propriétaire meurt à la place de ${realTarget.name}");
          return victim;
        }
      }
    }
    // --- RON-ALDO ---
    else if (roleLower == "ron-aldo") {
      try {
        Player firstFan = allPlayers.firstWhere(
              (p) => p.isFanOfRonAldo && p.fanJoinOrder == 1,
          orElse: () => Player(name: "None"),
        );

        if (firstFan.name != "None" && firstFan.isAlive) {
          victim = firstFan;
          debugPrint("🛡️ LOG [Ron-Aldo] : Le Premier Fan (${victim.name}) se sacrifie !");
          AchievementLogic.checkFanSacrifice(context, victim, realTarget);
        } else {
          debugPrint("🛡️ CAPTEUR [Mort] : Ron-Aldo sans fan disponible -> mort directe.");
        }
      } catch (e) {
        debugPrint("⚠️ Erreur logique Ron-Aldo : $e");
      }
    }

    if (isVote && nightChamanTarget != null && victim.name == nightChamanTarget!.name) {
      debugPrint("💀 CAPTEUR [Mort] : Chaman sniper détecté ! Cible du chaman ${nightChamanTarget!.name} éliminée au vote.");
      chamanSniperAchieved = true;
    }

    victim.isAlive = false;
    debugPrint("💀 LOG [Mort] : ${victim.name} (${victim.role}) a quitté la partie.");

    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      firstDeadPlayerName = victim.name;
      AchievementLogic.checkFirstBlood(context, victim);
    }

    if (roleLower == "pokémon" && globalTurnNumber == 1 && !isDayTime) {
      pokemonDiedTour1 = true;
    }

    AchievementLogic.checkDeathAchievements(context, victim, allPlayers);

    if (isVote && victim.hasSurvivedWolfBite) {
      AchievementLogic.checkEvolvedHunger(context, victim, allPlayers);
    }

    return victim;
  }
}
