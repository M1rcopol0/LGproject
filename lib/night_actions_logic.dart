import 'dart:math';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'logic.dart';
import 'globals.dart';

class NightResult {
  final List<Player> deadPlayers;
  final Map<String, String> deathReasons;
  final bool villageWasProtected;
  final String? revealedRoleMessage;
  final bool villageIsNarcoleptic;

  NightResult({
    required this.deadPlayers,
    required this.deathReasons,
    required this.villageWasProtected,
    this.revealedRoleMessage,
    this.villageIsNarcoleptic = false,
  });
}

class NightActionsLogic {
  // =========================================================
  // 1. PRÉ-RÉSOLUTION (Appelée dans initState du NightActionsScreen)
  // Gère les réveils et couchers programmés (Zookeeper, Timers)
  // =========================================================
  static void prepareNightStates(List<Player> players) {
    debugPrint("🌙 Préparation de la Nuit $globalTurnNumber");

    for (var p in players) {
      if (!p.isAlive) continue;

      // --- LOGIQUE ZOOKEEPER (CIBLE) ---
      // --- LOGIQUE ZOOKEEPER (CYCLE DIFFÉRÉ) ---
      if (p.hasBeenHitByDart) {
        if (p.zookeeperEffectReady) {
          // Le venin est prêt (tiré la nuit précédente) : on l'endort
          p.isEffectivelyAsleep = true;
          p.zookeeperEffectReady = false; // Effet consommé
          p.powerActiveThisTurn = true;   // Verrou pour qu'il dorme TOUTE la nuit
          debugPrint("💉 ${p.name} : Le venin du Zookeeper agit enfin. Dodo.");
        }
        else if (p.isEffectivelyAsleep && !p.powerActiveThisTurn) {
          // Il a dormi toute la nuit, il se réveille au matin
          p.isEffectivelyAsleep = false;
          p.hasBeenHitByDart = false;
          debugPrint("🌅 ${p.name} : Réveil après une nuit de sommeil Zookeeper.");
        }
      }



      // --- LOGIQUE PANTIN (Timer) ---
      if (p.pantinCurseTimer != null) {
        p.pantinCurseTimer = p.pantinCurseTimer! - 1;
      }
    }
  }

  // =========================================================
  // 2. RÉSOLUTION FINALE (Appelée au bouton "VOIR LE VILLAGE")
  // Calcule les morts et prépare les effets du lendemain
  // =========================================================
  static NightResult resolveNight(
      BuildContext context,
      List<Player> players,
      Map<Player, String> pendingDeathsMap,
      {bool somnifereActive = false}) {

    Map<String, String> finalDeathReasons = {};
    String? revealedInfo;

    // --- ÉVALUATION DE LA PROTECTION QUICHE ---
    // La quiche active (isVillageProtected) protège contre les attaques de CETTE nuit.
    // Elle ne fonctionne pas en Nuit 1 (car pas de Nuit 0).
    bool quicheIsActive = false;
    if (globalTurnNumber > 1) {
      quicheIsActive = players.any((p) =>
      p.role?.toLowerCase() == "grand-mère" &&
          p.isAlive &&
          p.isVillageProtected &&
          !p.isEffectivelyAsleep);
    }

    final List<Player> aliveBefore = players.where((p) => p.isAlive).toList();

    // --- RÉSOLUTION DES MORTS ---
    pendingDeathsMap.forEach((target, reason) {
      if (!target.isAlive) return;

      // Protection Quiche (sauf accidents/bombes)
      if (quicheIsActive && !reason.contains("accidentelle") && !reason.contains("Bombe")) {
        quicheSavedThisNight++;
        debugPrint("🥧 ${target.name} sauvé par la quiche.");
        return;
      }

      // Protection Pokémon (Individuelle)
      if (target.isProtectedByPokemon) return;

      bool targetWasInHouse = target.isInHouse;
      Player finalVictim = GameLogic.eliminatePlayer(context, players, target, isVote: false);

      if (!finalVictim.isAlive) {
        // Enregistrement de la raison spécifique pour la Maison
        if (targetWasInHouse && finalVictim.role?.toLowerCase() == "maison" && finalVictim != target) {
          finalDeathReasons[finalVictim.name] = "Protection de ${target.name} ($reason)";
        } else {
          finalDeathReasons[finalVictim.name] = reason;
        }

        if (reason.contains("Morsure")) wolvesNightKills++;
      }
    });

    // --- CLEANUP ET PRÉPARATION DU LENDEMAIN ---
    for (var p in players) {
      // Logique Grand-mère : Activation différée
      if (p.role?.toLowerCase() == "grand-mère") {
        if (p.hasBakedQuiche) {
          // La quiche mise au four cette nuit (N) sera active pour la nuit suivante (N+1)
          p.isVillageProtected = true;
          p.hasBakedQuiche = false;
          p.powerActiveThisTurn = true;
        } else if (p.isVillageProtected && !p.powerActiveThisTurn) {
          // La protection expire après avoir duré tout le cycle
          p.isVillageProtected = false;
        }
      }

      // On relâche les verrous au matin
      p.powerActiveThisTurn = false;
      p.isProtectedByPokemon = false;

      // Réveil forcé (sauf pour les cibles du Zookeeper qui dorment encore demain)
      if (!p.hasBeenHitByDart) {
        p.isEffectivelyAsleep = false;
      }

      // Mort différée Pantin
      if (p.isAlive && p.pantinCurseTimer == 0) {
        p.isAlive = false;
        finalDeathReasons[p.name] = "Malédiction du Pantin";
      }
    }

    return NightResult(
      deadPlayers: aliveBefore.where((p) => !p.isAlive).toList(),
      deathReasons: finalDeathReasons,
      villageWasProtected: quicheIsActive,
      revealedRoleMessage: revealedInfo,
      villageIsNarcoleptic: somnifereActive,
    );
  }
}