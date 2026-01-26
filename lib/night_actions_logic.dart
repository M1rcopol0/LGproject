import 'dart:math';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'logic.dart';
import 'globals.dart';
import 'trophy_service.dart';

class NightResult {
  final List<Player> deadPlayers;
  final Map<String, String> deathReasons;
  final bool villageWasProtected;
  final String? revealedRoleMessage;
  final bool exorcismeSuccess;
  final bool villageIsNarcoleptic;
  final String? houstonMessage;
  final String? archivistMessage;

  NightResult({
    required this.deadPlayers,
    required this.deathReasons,
    required this.villageWasProtected,
    this.revealedRoleMessage,
    this.exorcismeSuccess = false,
    this.villageIsNarcoleptic = false,
    this.houstonMessage,
    this.archivistMessage,
  });
}

class NightActionsLogic {
  static NightResult resolveNight(
      BuildContext context,
      List<Player> players,
      Map<Player, String> pendingDeathsMap,
      {String? exorcistChoice,
        bool somnifereActive = false}) {

    Map<String, String> finalDeathReasons = {};
    String? revealedInfo;
    String? houstonResult;
    String? archivistInfo;

    bool exoSuccess = (exorcistChoice == "success");
    bool voyageurReturnedThisNight = false;

    // =========================================================
    // 0. PRÉ-RÉSOLUTION : ÉTATS DIFFÉRÉS & TIMERS (DÉBUT DE NUIT)
    // =========================================================
    for (var p in players) {
      if (!p.isAlive) continue;

      // --- LOGIQUE QUICHE (GRAND-MÈRE) ---
      if (p.role?.toLowerCase() == "grand-mère") {
        // Si elle a cliqué sur cuisiner cette nuit
        if (p.hasBakedQuiche) {
          p.hasBakedQuiche = false; // Sort du four
          p.isVillageProtected = true; // Devient actif pour CETTE nuit (N+1)
          p.powerActiveThisTurn = true; // Empêche le reset au matin
          debugPrint("🥧 LOGIC: Quiche servie pour la Nuit $globalTurnNumber");
        }
        // Si elle protégeait déjà (venant de la nuit d'avant), on reset seulement au matin
        else if (p.isVillageProtected && !p.powerActiveThisTurn) {
          // Ce reset se fera en section 4
        }
      }

      // --- LOGIQUE CIBLE DU ZOOKEEPER (STABILISÉE) ---
      if (p.hasBeenHitByDart) {
        // Si le joueur est déjà endormi (tiré hier), il se RÉVEILLE au début de cette nuit
        if (p.isEffectivelyAsleep && !p.powerActiveThisTurn) {
          p.isEffectivelyAsleep = false;
          p.hasBeenHitByDart = false;
          debugPrint("🌅 LOGIC: ${p.name} se réveille du Zookeeper.");
        }
        // Si il vient d'être touché cette nuit
        else if (!p.isEffectivelyAsleep) {
          p.isEffectivelyAsleep = true;
          p.powerActiveThisTurn = true; // Garde l'état pour demain
          debugPrint("💉 LOGIC: ${p.name} s'endort via Zookeeper.");
        }
      }

      // --- LOGIQUE PANTIN ---
      if (p.pantinCurseTimer != null) {
        p.pantinCurseTimer = p.pantinCurseTimer! - 1;
        if (p.pantinCurseTimer! <= 0) {
          pendingDeathsMap[p] = "Malédiction du Pantin";
          p.pantinCurseTimer = null;
        }
      }
    }

    // =========================================================
    // 1. ÉVALUATION DE LA PROTECTION GLOBALE
    // =========================================================
    bool quicheIsActive = players.any((p) =>
    p.role?.toLowerCase() == "grand-mère" &&
        p.isAlive &&
        p.isVillageProtected &&
        !p.isEffectivelyAsleep);

    final List<Player> aliveBefore = players.where((p) => p.isAlive).toList();

    // =========================================================
    // 2. LOGIQUES INTERNES (BOMBES, ETC.)
    // =========================================================
    for (var tardos in players.where((p) => p.hasPlacedBomb)) {
      if (tardos.tardosTarget != null) {
        if (tardos.bombTimer > 0) tardos.bombTimer--;
        if (tardos.bombTimer == 0) {
          Player target = tardos.tardosTarget!;
          if (target == tardos) {
            pendingDeathsMap[tardos] = "Explosion accidentelle";
          } else if (target.isInHouse) {
            try {
              Player maison = players.firstWhere((p) => p.role?.toLowerCase() == "maison" && p.isAlive);
              pendingDeathsMap[maison] = "Maison soufflée (Bombe)";
            } catch (e) {}
            for (var h in players.where((p) => p.isInHouse)) {
              pendingDeathsMap[h] = "Maison soufflée (Bombe)";
              h.isInHouse = false;
            }
          } else {
            pendingDeathsMap[target] = "Explosion du Tardos";
          }
          tardos.hasPlacedBomb = false;
          tardos.tardosTarget = null;
        }
      }
    }

    // =========================================================
    // 3. RÉSOLUTION FINALE DES MORTS
    // =========================================================
    pendingDeathsMap.forEach((target, reason) {
      if (!target.isAlive) return;

      if (quicheIsActive && !reason.contains("accidentelle")) {
        quicheSavedThisNight++;
        return;
      }

      if (target.isProtectedByPokemon) return;

      bool targetWasInHouse = target.isInHouse;
      Player finalVictim = GameLogic.eliminatePlayer(context, players, target, isVote: false);

      if (!finalVictim.isAlive) {
        // --- RAISON DE MORT MAISON ---
        if (targetWasInHouse && finalVictim.role?.toLowerCase() == "maison" && finalVictim != target) {
          finalDeathReasons[finalVictim.name] = "Protection de ${target.name} ($reason)";
        } else {
          finalDeathReasons[finalVictim.name] = reason;
        }

        if (reason.contains("Morsure")) wolvesNightKills++;
        if (finalVictim.role?.toLowerCase() == "voyageur" && target.isInTravel) voyageurReturnedThisNight = true;
      }
    });

    if (nightWolvesTarget != null) nightWolvesTargetSurvived = nightWolvesTarget!.isAlive;
    List<Player> newlyDead = aliveBefore.where((p) => !p.isAlive).toList();

    // =========================================================
    // 4. CLEANUP MATINAL (PRÉ-RÉVEIL)
    // =========================================================
    if (voyageurReturnedThisNight) {
      revealedInfo = (revealedInfo == null) ? "✈️ Le Voyageur est mort." : "$revealedInfo\n✈️ Le Voyageur est mort.";
    }

    for (var p in players) {
      p.powerActiveThisTurn = false;
      p.isProtectedByPokemon = false;

      // --- RÉVEIL GÉNÉRAL ---
      // On ne réveille PAS les cibles du Zookeeper (hasBeenHitByDart)
      // On ne réveille PAS le Zookeeper lui-même s'il a été victime d'un autre Zookeeper
      // MAIS le Zookeeper peut toujours AGIR (logic gérée dans NightActionsScreen)
      if (!p.hasBeenHitByDart) {
        p.isEffectivelyAsleep = false;
      }
    }

    return NightResult(
      deadPlayers: newlyDead,
      deathReasons: finalDeathReasons,
      villageWasProtected: quicheIsActive,
      revealedRoleMessage: revealedInfo,
      exorcismeSuccess: exoSuccess,
      villageIsNarcoleptic: somnifereActive,
      houstonMessage: houstonResult,
      archivistMessage: archivistInfo,
    );
  }
}