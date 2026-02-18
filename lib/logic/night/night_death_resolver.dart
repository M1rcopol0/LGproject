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

      // --- 1. PROTECTIONS PRIORITAIRES ---

      // Protection Sorcière (via flag global)
      if ((reason.contains("Morsure") || reason.contains("Attaque des Loups")) && nightWolvesTargetSurvived) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Sorcière) -> ${target.name} survit.");
        return;
      }

      // Protection Archiviste (Absent car en MJ)
      if (target.isAwayAsMJ) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Archiviste absent MJ) -> ${target.name} survit.");
        return;
      }

      // Cas des morts inarrêtables (Bombes, Effondrement Maison, etc.)
      bool isUnstoppable = reason.contains("accidentelle") || reason.contains("Bombe") || reason.contains("Tardos") || reason.contains("Maison");

      // Protection Quiche
      if (quicheIsActive && !isUnstoppable) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Quiche active) -> ${target.name} survit.");
        quicheSavedThisNight++;
        if (target.role?.toLowerCase() == "grand-mère") {
          target.hasSavedSelfWithQuiche = true;
          TrophyService.checkAndUnlockImmediate(context: context, playerName: target.name, achievementId: "self_quiche_save", checkData: {'saved_by_own_quiche': true, 'player_role': 'grand-mère'});
        }
        if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
          target.hasSurvivedWolfBite = true;
          target.wolfBiteSurvivedTurn = globalTurnNumber;
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

      // Protection Dresseur / Pokémon (Sacrifice spécifique de nuit)
      if (dresseur != null && target == dresseur && dresseur.lastDresseurAction == dresseur) {
        if (pokemon != null && pokemon.isAlive) {
          debugPrint("🛡️ CAPTEUR [Protection] : Le Pokémon se sacrifie pour le Dresseur !");
          List<Player> deaths = GameLogic.eliminatePlayer(context, players, pokemon, isVote: false, reason: "Sacrifice pour le dresseur");
          for (var p in deaths) {
            finalDeathReasons[p.name] = "Sacrifice pour le Dresseur ($reason)";
            _handleSpecialDeathEffects(context, p, players, finalDeathReasons, morningAnnouncements);
          }
          return;
        }
      }

      // Protection Dresseur → Pokémon (le Dresseur a choisi de protéger le Pokémon)
      if (dresseur != null && target == pokemon && dresseur.lastDresseurAction == pokemon && !isUnstoppable) {
        debugPrint("🛡️ CAPTEUR [Protection] : Dresseur protège le Pokémon → Pokémon survit.");
        return;
      }

      // Protection Pokémon (Ciblage direct d'un allié)
      if (target.isProtectedByPokemon && !isUnstoppable) {
        debugPrint("🛡️ CAPTEUR [Protection] : PROTÉGÉ (Pokémon) -> ${target.name} survit.");
        if (reason.contains("Morsure")) {
          target.hasSurvivedWolfBite = true;
          target.wolfBiteSurvivedTurn = globalTurnNumber;
          nightWolvesTargetSurvived = true;
        }
        return;
      }

      // --- 2. EXÉCUTION DE LA MORT ---

      // eliminatePlayer gère déjà récursivement Cupidon, Maison, Ron-Aldo.
      List<Player> deaths = GameLogic.eliminatePlayer(context, players, target, isVote: false, reason: reason);

      if (deaths.isEmpty) {
        // Cas de survie (Pantin au vote [rare ici], Voyageur en voyage, etc.)
        debugPrint("🛡️ CAPTEUR [Protection] : ${target.name} a survécu à l'élimination (Pantin/Voyageur).");
        if (reason.contains("Morsure")) {
          target.hasSurvivedWolfBite = true;
          target.wolfBiteSurvivedTurn = globalTurnNumber;
          nightWolvesTargetSurvived = true;
        }
      } else {
        for (var deadPlayer in deaths) {
          debugPrint("💀 CAPTEUR [Mort] : MORT CONFIRMÉE: ${deadPlayer.name} (${deadPlayer.role})");

          if (!finalDeathReasons.containsKey(deadPlayer.name)) {
            if (deadPlayer == target) {
              finalDeathReasons[deadPlayer.name] = reason;
            } else if (deadPlayer.isLinked) {
              // Si la référence lover est nulle (déjà éliminé avant nettoyage), on utilise target.name comme fallback
              String loverName = deadPlayer.lover?.name ?? target.name;
              finalDeathReasons[deadPlayer.name] = "Chagrin d'amour ($loverName)";
            } else {
              finalDeathReasons[deadPlayer.name] = "Réaction en chaîne ($reason)";
            }
          }

          if (reason.contains("Morsure")) wolvesNightKills++;

          _handleSpecialDeathEffects(context, deadPlayer, players, finalDeathReasons, morningAnnouncements);
        }

        // Cas Maison effondrée : la cible des loups (target) survit car la Maison a absorbé la mort.
        // deaths est non vide (contient le proprio de la Maison) mais ne contient PAS target.
        if (reason.contains("Morsure") && !deaths.contains(target) && target.isAlive) {
          target.hasSurvivedWolfBite = true;
          target.wolfBiteSurvivedTurn = globalTurnNumber;
          nightWolvesTargetSurvived = true;
          debugPrint("🛡️ CAPTEUR [Fringale] : ${target.name} a survécu par proxy (Maison effondrée) → hasSurvivedWolfBite = true, turn=$globalTurnNumber");
        }
      }
    });

    // NOTE : Le Pantin maudit par chagrin d'amour (pantinCurseTimer=2) n'est PAS annoncé mort ici.
    // Le timer est décrémenté chaque nuit par NightPreparation et la mort est exécutée par NightCleanup
    // quand le timer atteint 0. L'icône de malédiction sur la carte du joueur signale l'état.
  }

  /// Gère les effets secondaires suite à une mort confirmée (Vengeances, Stats, Achievements)
  static void _handleSpecialDeathEffects(
      BuildContext context,
      Player victim,
      List<Player> allPlayers,
      Map<String, String> finalDeathReasons,
      List<String> morningAnnouncements,
      ) {
    AchievementLogic.checkDeathAchievements(context, victim, allPlayers);

    // Vengeance Pokémon
    if ((victim.role?.toLowerCase() == "pokémon" || victim.role?.toLowerCase() == "pokemon") &&
        victim.pokemonRevengeTarget != null &&
        victim.pokemonRevengeTarget!.isAlive) {

      Player revengeTarget = victim.pokemonRevengeTarget!;
      debugPrint("⚡ CAPTEUR [Vengeance] : Le Pokémon foudroie ${revengeTarget.name}");
      morningAnnouncements.add("⚡ Le Pokémon emporte ${revengeTarget.name} dans sa chute !");

      List<Player> revengeDeaths = GameLogic.eliminatePlayer(context, allPlayers, revengeTarget, isVote: false, reason: "Vengeance Pokémon");
      for (var rd in revengeDeaths) {
        finalDeathReasons[rd.name] = "Vengeance du Pokémon";
        AchievementLogic.checkDeathAchievements(context, rd, allPlayers);
      }
    }

    // Cas spécifique Voyageur / Dingo (Logs techniques)
    if (finalDeathReasons[victim.name]?.contains("Tir du Voyageur") ?? false) {
      try {
        allPlayers.firstWhere((p) => p.role?.toLowerCase() == "voyageur").travelerKilledWolf = (victim.team == "loups");
      } catch (_) {}
    }
  }
}