import 'package:flutter/material.dart';
import 'models/player.dart';
import 'logic.dart';
import 'globals.dart';
import 'achievement_logic.dart';
import 'trophy_service.dart';

// Imports des modules découpés
import 'logic/night/night_preparation.dart';
import 'logic/night/night_explosion.dart';
import 'logic/night/night_info_generator.dart';

class NightResult {
  final List<Player> deadPlayers;
  final Map<String, String> deathReasons;
  final bool villageWasProtected;
  final List<String> announcements;
  final bool villageIsNarcoleptic;
  final bool exorcistVictory;
  final List<String> revealedPlayerNames;

  NightResult({
    required this.deadPlayers,
    required this.deathReasons,
    required this.villageWasProtected,
    this.announcements = const [],
    this.villageIsNarcoleptic = false,
    this.exorcistVictory = false,
    this.revealedPlayerNames = const [],
  });
}

class NightActionsLogic {

  // =========================================================
  // 1. PRÉ-RÉSOLUTION
  // =========================================================
  static void prepareNightStates(List<Player> players) {
    NightPreparation.run(players);
  }

  // =========================================================
  // 2. RÉSOLUTION FINALE
  // =========================================================
  static NightResult resolveNight(
      BuildContext context,
      List<Player> players,
      Map<Player, String> pendingDeathsMap,
      {bool somnifereActive = false,
        bool exorcistSuccess = false}) {

    debugPrint("🏁 LOG [Logic] : Début de la résolution finale.");
    Map<String, String> finalDeathReasons = {};
    List<String> playersToReveal = [];

    // --- VICTOIRE EXORCISTE ---
    if (exorcistSuccess) {
      debugPrint("🏆 LOG [Exorciste] : VICTOIRE IMMÉDIATE DÉTECTÉE.");
      return NightResult(
        deadPlayers: [],
        deathReasons: {},
        villageWasProtected: false,
        exorcistVictory: true,
      );
    }

    // --- MODULE : GESTION DES RÔLES SPÉCIAUX (Time Master, Maison) ---
    NightInfoGenerator.processSpecialRoles(context, players, pendingDeathsMap);

    // --- MODULE : GÉNÉRATION DES ANNONCES (Voyageur, Houston, Devin) ---
    List<String> morningAnnouncements = NightInfoGenerator.generateAnnouncements(context, players, playersToReveal, pendingDeathsMap);

    // --- SOMNIFÈRE ---
    if (somnifereActive) {
      for (var p in players) p.isEffectivelyAsleep = true;
      morningAnnouncements.add("💤 Le village se réveille engourdi... Le Somnifère a frappé !");
      debugPrint("💤 LOG [Somnifère] : Activé (Mode annonce uniquement).");
    }

    // --- MODULE : EXPLOSIONS ---
    // A. Tardos
    for (var p in players) {
      if (p.hasPlacedBomb && p.bombTimer == 0 && p.tardosTarget != null) {
        NightExplosion.handle(
            context: context,
            allPlayers: players,
            target: p.tardosTarget!,
            pendingDeathsMap: pendingDeathsMap,
            reason: "Explosion Bombe (Tardos)",
            attacker: p,
            announcements: morningAnnouncements
        );
        p.tardosTarget = null;
      }
    }
    // B. Manuelle
    for (var p in players) {
      bool targetedByTardos = players.any((attacker) => attacker.role?.toLowerCase() == "tardos" && attacker.hasPlacedBomb && attacker.tardosTarget == p);
      if (p.isBombed && p.attachedBombTimer == 0 && !targetedByTardos) {
        NightExplosion.handle(
            context: context,
            allPlayers: players,
            target: p,
            pendingDeathsMap: pendingDeathsMap,
            reason: "Explosion Bombe (Manuelle)",
            attacker: null,
            announcements: morningAnnouncements
        );
      }
    }

    // --- PROTECTION QUICHE ---
    bool quicheIsActive = false;
    if (globalTurnNumber > 1) {
      quicheIsActive = players.any((p) => p.role?.toLowerCase() == "grand-mère" && p.isAlive && p.isVillageProtected && !p.isEffectivelyAsleep);
    }

    Player? dresseur;
    Player? pokemon;
    try {
      dresseur = players.firstWhere((p) => p.role?.toLowerCase() == "dresseur" && p.isAlive);
      pokemon = players.firstWhere((p) => (p.role?.toLowerCase() == "pokémon" || p.role?.toLowerCase() == "pokemon") && p.isAlive);
    } catch (_) {}

    // --- RÉSOLUTION DES MORTS (Boucle principale) ---
    pendingDeathsMap.forEach((target, reason) {
      if (!target.isAlive) return;

      // Protection Sorcière
      if ((reason.contains("Morsure") || reason.contains("Attaque des Loups")) && nightWolvesTargetSurvived) {
        return;
      }
      // Protection Archiviste
      if (target.isAwayAsMJ) return;

      bool isUnstoppable = reason.contains("accidentelle") || reason.contains("Bombe") || reason.contains("Tardos") || reason.contains("Maison");

      // Protection Quiche
      if (quicheIsActive && !isUnstoppable) {
        quicheSavedThisNight++;
        if (target.role?.toLowerCase() == "grand-mère") {
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
        if (reason.contains("Morsure")) nightWolvesTargetSurvived = true;
        return;
      }

      // Protection Dresseur
      if (dresseur != null && dresseur.lastDresseurAction != null) {
        if (target == dresseur && dresseur.lastDresseurAction == dresseur) {
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
        if (target == pokemon && dresseur.lastDresseurAction == pokemon) return;
      }

      // Protection Pokémon
      if (target.isProtectedByPokemon && !isUnstoppable) {
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
        Player? priorityFan;
        try { priorityFan = fans.firstWhere((p) => p.hostedRonAldoThisTurn); } catch (_) {}
        if (priorityFan != null) { fans.remove(priorityFan); fans.insert(0, priorityFan); }
        else { fans.sort((a, b) => a.fanJoinOrder.compareTo(b.fanJoinOrder)); }

        if (fans.isNotEmpty) {
          Player fanSacrifice = fans.first;
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
        AchievementLogic.checkDeathAchievements(context, finalVictim, players);

        // Si le voyageur meurt, on retire l'annonce de son retour forcé (car c'est moins pertinent que sa mort)
        if (finalVictim.role?.toLowerCase() == "voyageur") {
          morningAnnouncements.remove("🚫 Le Voyageur a été intercepté et forcé de rentrer !");
        }

        if (reason.contains("Tir du Voyageur")) {
          try { players.firstWhere((p) => p.role?.toLowerCase() == "voyageur").travelerKilledWolf = (finalVictim.team == "loups"); } catch (_) {}
        }
        if (reason.contains("Tir du Dingo")) {
          try { AchievementLogic.checkParkingShot(context, players.firstWhere((p) => p.role?.toLowerCase() == "dingo"), finalVictim, players); } catch (_) {}
        }

        // Vengeance Pokémon
        if (finalVictim.role?.toLowerCase().contains("pok") == true && finalVictim.pokemonRevengeTarget != null) {
          Player revengeTarget = finalVictim.pokemonRevengeTarget!;
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
          finalDeathReasons[finalVictim.name] = "Protection de ${target.name} ($reason)";
          TrophyService.checkAndUnlockImmediate(context: context, playerName: target.name, achievementId: "assurance_habitation", checkData: {'assurance_habitation_triggered': true});
          if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) target.hasSurvivedWolfBite = true;
        } else {
          finalDeathReasons[finalVictim.name] = reason;
        }
        if (reason.contains("Morsure")) wolvesNightKills++;

        // Cupidon (Morts liées)
        if (finalVictim.isLinkedByCupidon && finalVictim.lover != null) {
          Player lover = finalVictim.lover!;
          if (!lover.isAlive && !finalDeathReasons.containsKey(lover.name)) {
            finalDeathReasons[lover.name] = "Chagrin d'amour (Lié à ${finalVictim.name})";
          }
        }
      } else {
        // Survie (Pantin, Voyageur...)
        if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
          target.hasSurvivedWolfBite = true;
          nightWolvesTargetSurvived = true;
        }
      }
    });

    // --- 5. NETTOYAGE ET MORTS DIFFÉRÉES ---
    for (var p in players) {
      if (p.isAlive && p.pantinCurseTimer == 0) {
        if (quicheIsActive) {
          p.pantinCurseTimer = 1;
          quicheSavedThisNight++;
        } else {
          p.isAlive = false;
          AchievementLogic.checkDeathAchievements(context, p, players);
          finalDeathReasons[p.name] = "Malédiction du Pantin";
          // Vengeance Pokémon Pantin ? (Rare mais possible)
          if (p.role?.toLowerCase().contains("pok") == true && p.pokemonRevengeTarget != null && p.pokemonRevengeTarget!.isAlive) {
            Player rev = p.pokemonRevengeTarget!;
            rev.isAlive = false;
            finalDeathReasons[rev.name] = "Vengeance du Pokémon";
            morningAnnouncements.add("⚡ Le Pokémon emporte ${rev.name} !");
          }
        }
      }

      if (p.role?.toLowerCase() == "grand-mère" && p.isAlive) {
        if (p.hasBakedQuiche) {
          p.isVillageProtected = true;
          p.hasBakedQuiche = false;
          p.powerActiveThisTurn = true;
        } else if (p.isVillageProtected && !p.powerActiveThisTurn) {
          p.isVillageProtected = false;
          p.hasSavedSelfWithQuiche = false;
        }
      }

      p.powerActiveThisTurn = false;
      p.isProtectedByPokemon = false;
      p.hasReturnedThisTurn = false;
      p.hostedRonAldoThisTurn = false;
      p.isProtectedBySaltimbanque = false;
      if (!p.hasBeenHitByDart) p.isEffectivelyAsleep = false;
    }

    List<Player> deadNow = players.where((p) => !p.isAlive && finalDeathReasons.containsKey(p.name)).toList();

    debugPrint("🏁 LOG [Logic] : Résolution terminée.");
    return NightResult(
      deadPlayers: deadNow,
      deathReasons: finalDeathReasons,
      villageWasProtected: quicheIsActive,
      announcements: morningAnnouncements,
      villageIsNarcoleptic: false,
      revealedPlayerNames: playersToReveal,
      exorcistVictory: exorcistSuccess,
    );
  }
}