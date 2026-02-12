import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/logic/logic.dart';
import 'package:fluffer/globals.dart';
import 'package:fluffer/logic/achievement_logic.dart';
import 'package:fluffer/services/trophy_service.dart';

class NightDeathResolver {
  static void resolve({
    required BuildContext context,
    required List<Player> players,
    required Map<Player, String> pendingDeathsMap,
    required Map<String, String> finalDeathReasons,
    required List<String> morningAnnouncements,
    required bool quicheIsActive,
  }) {
    Player? dresseur;
    Player? pokemon;
    try {
      dresseur = players.firstWhere((p) => p.role?.toLowerCase() == "dresseur" && p.isAlive);
      pokemon = players.firstWhere((p) => (p.role?.toLowerCase() == "pokémon" || p.role?.toLowerCase() == "pokemon") && p.isAlive);
    } catch (_) {}

    debugPrint("💀 CAPTEUR [Mort] : Début résolution des morts. ${pendingDeathsMap.length} cible(s) en attente.");
    pendingDeathsMap.forEach((target, reason) {
      debugPrint("💀 CAPTEUR [Mort] : Traitement cible: ${target.name} (${target.role}), raison: $reason");
      if (!target.isAlive) {
        debugPrint("💀 CAPTEUR [Mort] : SKIP: ${target.name} déjà mort.");
        return;
      }

      // Protection Sorciere
      if ((reason.contains("Morsure") || reason.contains("Attaque des Loups")) && nightWolvesTargetSurvived) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Sorcière a sauvé la cible des loups) -> ${target.name} survit.");
        return;
      }
      // Protection Archiviste
      if (target.isAwayAsMJ) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Archiviste absent MJ) -> ${target.name} survit.");
        return;
      }

      bool isUnstoppable = reason.contains("accidentelle") || reason.contains("Bombe") || reason.contains("Tardos") || reason.contains("Maison");

      // Protection Quiche
      if (quicheIsActive && !isUnstoppable) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Quiche active) -> cible ${target.name} survit.");
        quicheSavedThisNight++;
        if (target.role?.toLowerCase() == "grand-mère") {
          debugPrint("🛡️ CAPTEUR [Protection] : Grand-mère se sauve elle-même avec sa Quiche.");
          target.hasSavedSelfWithQuiche = true;
          TrophyService.checkAndUnlockImmediate(context: context, playerName: target.name, achievementId: "self_quiche_save", checkData: {'saved_by_own_quiche': true, 'player_role': 'grand-mère'});
        }
        if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
          target.hasSurvivedWolfBite = true;
          nightWolvesTargetSurvived = true;
        }
        return;
      }

      // Protection Saltimbanque
      if (target.isProtectedBySaltimbanque && !isUnstoppable) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Saltimbanque) -> ${target.name} survit.");
        if (reason.contains("Morsure")) nightWolvesTargetSurvived = true;
        return;
      }

      // Protection Dresseur
      if (dresseur != null && dresseur.lastDresseurAction != null) {
        if (target == dresseur && dresseur.lastDresseurAction == dresseur) {
          debugPrint("🛡️ CAPTEUR [Protection] : Dresseur autoprotection via Pokémon.");
          if (pokemon != null && pokemon.isAlive) {
            Player pokemonVictim = GameLogic.eliminatePlayer(context, players, pokemon, isVote: false);
            if (!pokemonVictim.isAlive) {
              finalDeathReasons[pokemonVictim.name] = "Sacrifice pour le Dresseur ($reason)";
              AchievementLogic.checkDeathAchievements(context, pokemonVictim, players);
              if (pokemonVictim.pokemonRevengeTarget != null && pokemonVictim.pokemonRevengeTarget!.isAlive) {
                Player revenge = pokemonVictim.pokemonRevengeTarget!;
                morningAnnouncements.add("⚡ Le Pokémon (Sacrifié) emporte ${revenge.name} (${revenge.role}) !");
                GameLogic.eliminatePlayer(context, players, revenge, isVote: false);
              }
            }
            return;
          }
        }
        if (target == pokemon && dresseur.lastDresseurAction == pokemon) {
          debugPrint("🛡️ CAPTEUR [Protection] : Dresseur protège son Pokémon -> ${pokemon?.name} survit.");
          return;
        }
      }

      // Protection Pokemon
      if (target.isProtectedByPokemon && !isUnstoppable) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Pokémon) -> ${target.name} survit.");
        if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
          target.hasSurvivedWolfBite = true;
          nightWolvesTargetSurvived = true;
        }
        return;
      }

      bool targetWasInHouse = target.isInHouse;

      // Sacrifice Ron-Aldo
      if (target.role?.toLowerCase() == "ron-aldo" && !isUnstoppable) {
        List<Player> fans = players.where((p) => p.isFanOfRonAldo && p.isAlive).toList();
        debugPrint("🛡️ CAPTEUR [Protection] : Ron-Aldo attaqué. ${fans.length} fan(s) disponible(s).");
        Player? priorityFan;
        try { priorityFan = fans.firstWhere((p) => p.hostedRonAldoThisTurn); } catch (_) {}
        if (priorityFan != null) {
          debugPrint("🛡️ CAPTEUR [Protection] : Fan prioritaire (hébergé): ${priorityFan.name}");
          fans.remove(priorityFan); fans.insert(0, priorityFan);
        }
        else { fans.sort((a, b) => a.fanJoinOrder.compareTo(b.fanJoinOrder)); }

        if (fans.isNotEmpty) {
          Player fanSacrifice = fans.first;
          debugPrint("🛡️ CAPTEUR [Protection] : Fan ${fanSacrifice.name} (ordre ${fanSacrifice.fanJoinOrder}) se sacrifie pour Ron-Aldo.");
          Player deadFan = GameLogic.eliminatePlayer(context, players, fanSacrifice, isVote: false, reason: "Sacrifice pour Ron-Aldo");
          finalDeathReasons[deadFan.name] = "Sacrifice pour Ron-Aldo ($reason)";
          AchievementLogic.checkDeathAchievements(context, deadFan, players);
          AchievementLogic.checkFanSacrifice(context, deadFan, target);
          if (deadFan.hostedRonAldoThisTurn) {
            TrophyService.checkAndUnlockImmediate(context: context, playerName: deadFan.name, achievementId: "coupe_maison", checkData: {'ramenez_la_coupe': true});
            TrophyService.checkAndUnlockImmediate(context: context, playerName: target.name, achievementId: "coupe_maison", checkData: {'ramenez_la_coupe': true});
          }
          return;
        }
      }

      // MORT EFFECTIVE
      Player finalVictim = GameLogic.eliminatePlayer(context, players, target, isVote: false);

      if (!finalVictim.isAlive) {
        debugPrint("💀 CAPTEUR [Mort] : MORT CONFIRMÉE: ${finalVictim.name} (${finalVictim.role}) par raison: $reason");
        AchievementLogic.checkDeathAchievements(context, finalVictim, players);

        if (finalVictim.role?.toLowerCase() == "voyageur") {
          morningAnnouncements.remove("🚫 Le Voyageur a été intercepté et forcé de rentrer !");
        }

        if (reason.contains("Tir du Voyageur")) {
          try { players.firstWhere((p) => p.role?.toLowerCase() == "voyageur").travelerKilledWolf = (finalVictim.team == "loups"); } catch (_) {}
        }
        if (reason.contains("Tir du Dingo")) {
          try { AchievementLogic.checkParkingShot(context, players.firstWhere((p) => p.role?.toLowerCase() == "dingo"), finalVictim, players); } catch (_) {}
        }

        // Vengeance Pokemon
        if (finalVictim.role?.toLowerCase().contains("pok") == true && finalVictim.pokemonRevengeTarget != null) {
          Player revengeTarget = finalVictim.pokemonRevengeTarget!;
          debugPrint("💀 CAPTEUR [Mort] : Pokémon vengeance -> cible ${revengeTarget.name} (vivant: ${revengeTarget.isAlive})");
          if (revengeTarget.isAlive) {
            morningAnnouncements.add("⚡ Le Pokémon emporte ${revengeTarget.name} (${revengeTarget.role}) !");
            Player revengeVictim = GameLogic.eliminatePlayer(context, players, revengeTarget, isVote: false);
            if (!revengeVictim.isAlive) {
              AchievementLogic.checkDeathAchievements(context, revengeVictim, players);
              finalDeathReasons[revengeVictim.name] = "Vengeance du Pokémon";
            }
          }
        }

        // Protection Maison (Effondrement)
        if (targetWasInHouse && finalVictim.role?.toLowerCase() == "maison" && finalVictim != target && !isUnstoppable) {
          debugPrint("💀 CAPTEUR [Mort] : Maison effondrée -> propriétaire ${finalVictim.name} meurt pour ${target.name}.");
          finalDeathReasons[finalVictim.name] = "Protection de ${target.name} ($reason)";
          TrophyService.checkAndUnlockImmediate(context: context, playerName: target.name, achievementId: "assurance_habitation", checkData: {'assurance_habitation_triggered': true});
          if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) target.hasSurvivedWolfBite = true;
        } else {
          finalDeathReasons[finalVictim.name] = reason;
        }
        if (reason.contains("Morsure")) wolvesNightKills++;

        // Cupidon (Morts liees)
        if (finalVictim.isLinkedByCupidon && finalVictim.lover != null) {
          Player lover = finalVictim.lover!;
          debugPrint("💀 CAPTEUR [Mort] : Cupidon lien détecté: ${finalVictim.name} lié à ${lover.name} (vivant: ${lover.isAlive})");
          if (lover.isAlive) {
            if (lover.role?.toLowerCase() == "pantin") {
              debugPrint("💀 CAPTEUR [Mort] : Chagrin d'amour différé (Pantin): ${lover.name} -> malédiction activée.");
              lover.pantinCurseTimer = 2;
              finalDeathReasons[lover.name] = "Chagrin d'amour différé (Lié à ${finalVictim.name})";
            } else {
              debugPrint("💀 CAPTEUR [Mort] : Chagrin d'amour: ${lover.name} meurt (lié à ${finalVictim.name}).");
              lover.isAlive = false;
              AchievementLogic.checkDeathAchievements(context, lover, players);
              finalDeathReasons[lover.name] = "Chagrin d'amour (Lié à ${finalVictim.name})";

              if (lover.role?.toLowerCase().contains("pok") == true &&
                  lover.pokemonRevengeTarget != null &&
                  lover.pokemonRevengeTarget!.isAlive) {
                Player revengeTarget = lover.pokemonRevengeTarget!;
                morningAnnouncements.add("⚡ Le Pokémon (Chagrin) emporte ${revengeTarget.name} (${revengeTarget.role}) !");
                Player revengeVictim = GameLogic.eliminatePlayer(context, players, revengeTarget, isVote: false);
                if (!revengeVictim.isAlive) {
                  AchievementLogic.checkDeathAchievements(context, revengeVictim, players);
                  finalDeathReasons[revengeVictim.name] = "Vengeance du Pokémon";
                }
              }
            }
          } else if (!finalDeathReasons.containsKey(lover.name)) {
            finalDeathReasons[lover.name] = "Chagrin d'amour (Lié à ${finalVictim.name})";
          }
        }
      } else {
        // Survie (Pantin, Voyageur...)
        debugPrint("🛡️ CAPTEUR [Protection] : ${target.name} survit à l'attaque (raison: Pantin/Voyageur).");
        if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
          target.hasSurvivedWolfBite = true;
          nightWolvesTargetSurvived = true;
        }
      }
    });
  }
}
