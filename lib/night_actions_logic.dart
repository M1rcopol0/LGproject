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
  final bool exorcistVictory;

  NightResult({
    required this.deadPlayers,
    required this.deathReasons,
    required this.villageWasProtected,
    this.revealedRoleMessage,
    this.villageIsNarcoleptic = false,
    this.exorcistVictory = false,
  });
}

class NightActionsLogic {
  // =========================================================
  // 1. PRÉ-RÉSOLUTION (Appelée au début de la nuit)
  // =========================================================
  static void prepareNightStates(List<Player> players) {
    debugPrint("--------------------------------------------------");
    debugPrint("🌙 LOG [Logic] : Préparation de la Nuit $globalTurnNumber");

    for (var p in players) {
      // --- LOGIQUE BOMBE TARDOS (PROJECTILE AUTONOME) ---
      // On décompte même si le poseur 'p' est mort.
      if (p.hasPlacedBomb && p.bombTimer > 0) {
        p.bombTimer--;
        debugPrint("💣 LOG [Tardos] : La bombe posée par ${p.name} tic-tac... (T-Minus: ${p.bombTimer})");
      }

      if (!p.isAlive) continue;

      // --- LOGIQUE ZOOKEEPER (Cycle de venin) ---
      if (p.hasBeenHitByDart) {
        if (p.zookeeperEffectReady) {
          p.isEffectivelyAsleep = true;
          p.zookeeperEffectReady = false;
          p.powerActiveThisTurn = true;
          debugPrint("💉 LOG [Zookeeper] : ${p.name} succombe au venin. Sommeil activé.");
        }
        else if (p.isEffectivelyAsleep && !p.powerActiveThisTurn) {
          p.isEffectivelyAsleep = false;
          p.hasBeenHitByDart = false;
          debugPrint("🌅 LOG [Zookeeper] : ${p.name} se réveille du venin.");
        }
      }

      // --- LOGIQUE PANTIN (Décompte du Timer) ---
      if (p.pantinCurseTimer != null && p.pantinCurseTimer! > 0) {
        p.pantinCurseTimer = p.pantinCurseTimer! - 1;
        debugPrint("🎭 LOG [Pantin] : Malédiction sur ${p.name} (Timer: ${p.pantinCurseTimer})");
      }
    }
    debugPrint("--------------------------------------------------");
  }

  // =========================================================
  // 2. RÉSOLUTION FINALE (Bouton "VOIR LE VILLAGE")
  // =========================================================
  static NightResult resolveNight(
      BuildContext context,
      List<Player> players,
      Map<Player, String> pendingDeathsMap,
      {bool somnifereActive = false,
        bool exorcistSuccess = false}) {

    debugPrint("🏁 LOG [Logic] : Début de la résolution finale.");
    Map<String, String> finalDeathReasons = {};

    // --- VICTOIRE IMMÉDIATE EXORCISTE ---
    if (exorcistSuccess) {
      debugPrint("🏆 LOG [Exorciste] : VICTOIRE IMMÉDIATE DÉTECTÉE.");
      return NightResult(
        deadPlayers: [],
        deathReasons: {},
        villageWasProtected: false,
        exorcistVictory: true,
      );
    }

    // --- LOGIQUE EXPLOSION BOMBE TARDOS (AVANT TOUT LE RESTE) ---
    // On doit ajouter ces morts à la map pendingDeathsMap pour qu'elles soient traitées
    for (var p in players) {
      if (p.hasPlacedBomb && p.bombTimer == 0 && p.tardosTarget != null) {
        Player target = p.tardosTarget!;
        debugPrint("💥 LOG [Explosion] : La bombe de ${p.name} EXPLOSE sur ${target.name} !");

        // Cas Spécial : La bombe est DANS la maison ou SUR la Maison
        if (target.role?.toLowerCase() == "maison" || target.isInHouse) {
          debugPrint("🏠💥 LOG [Tardos] : La bombe détruit la Maison et ses occupants !");

          // 1. Trouver le proprio
          try {
            Player houseOwner = players.firstWhere((h) => h.role?.toLowerCase() == "maison");
            pendingDeathsMap[houseOwner] = "Explosion Maison (Tardos)";
          } catch(e) { /* Pas de maison en vie */ }

          // 2. Trouver tous les occupants
          for (var occupant in players.where((o) => o.isInHouse)) {
            pendingDeathsMap[occupant] = "Effondrement Maison (Tardos)";
          }
        }
        // Cas Standard
        else if (target.isAlive) {
          pendingDeathsMap[target] = "Explosion Bombe (Tardos)";
        } else {
          debugPrint("🌬️ LOG [Tardos] : La bombe explose sur un cadavre.");
        }

        // Désactivation de la bombe
        p.hasPlacedBomb = false;
        p.tardosTarget = null;
      }
    }

    // --- ÉVALUATION DE LA PROTECTION QUICHE ---
    bool quicheIsActive = false;
    if (globalTurnNumber > 1) {
      quicheIsActive = players.any((p) =>
      p.role?.toLowerCase() == "grand-mère" &&
          p.isAlive &&
          p.isVillageProtected &&
          !p.isEffectivelyAsleep
      );
    }
    debugPrint("🥧 LOG [Quiche] : Protection active : $quicheIsActive");

    final List<Player> aliveBefore = players.where((p) => p.isAlive).toList();

    // --- RÉSOLUTION DES MORTS (Morsures, Tirs, Bombes) ---
    pendingDeathsMap.forEach((target, reason) {
      if (!target.isAlive) return;

      // Protection Quiche
      // Elle ne protège PAS si la raison contient "Tardos", "Explosion", "Maison" (effondrement) ou "accidentelle"
      bool isUnstoppable = reason.contains("accidentelle") ||
          reason.contains("Bombe") ||
          reason.contains("Tardos") ||
          reason.contains("Maison");

      if (quicheIsActive && !isUnstoppable) {
        quicheSavedThisNight++;

        // Logique Succès Grand-Mère (S'est sauvée elle-même)
        if (target.role?.toLowerCase() == "grand-mère") {
          target.hasSavedSelfWithQuiche = true;
        }

        debugPrint("🛡️ LOG [Quiche] : ${target.name} sauvé de : $reason");
        return;
      }

      // Protection Pokémon (Individuelle)
      // Ne protège pas non plus des explosions nucléaires du Tardos
      if (target.isProtectedByPokemon && !reason.contains("Tardos")) {
        debugPrint("🛡️ LOG [Pokémon] : ${target.name} protégé.");
        return;
      }

      // Traitement du décès
      bool targetWasInHouse = target.isInHouse;
      Player finalVictim = GameLogic.eliminatePlayer(context, players, target, isVote: false);

      if (!finalVictim.isAlive) {
        // Logique Maison Standard (Ricochet) vs Explosion Tardos
        // Si c'est le Tardos, tout le monde meurt (géré par l'ajout multiple dans pendingDeathsMap plus haut)
        // Si c'est une morsure normale sur un occupant, la maison prend le coup.

        if (targetWasInHouse &&
            finalVictim.role?.toLowerCase() == "maison" &&
            finalVictim != target &&
            !reason.contains("Tardos")) { // La maison ne tanke pas pour le Tardos, elle meurt AVEC lui

          debugPrint("🏠 LOG [Maison] : Effondrement protecteur pour ${target.name}.");
          finalDeathReasons[finalVictim.name] = "Protection de ${target.name} ($reason)";

        } else {
          debugPrint("💀 LOG [Mort] : ${finalVictim.name} succombe ($reason).");
          finalDeathReasons[finalVictim.name] = reason;
        }

        if (reason.contains("Morsure")) wolvesNightKills++;
      }
    });

    // --- MORTS DIFFÉRÉES ET CLEANUP ---
    for (var p in players) {
      if (p.isAlive && p.pantinCurseTimer == 0) {
        debugPrint("🎭 LOG [Pantin] : Mort de la malédiction : ${p.name}");
        p.isAlive = false;
        p.pantinCurseTimer = null;
        finalDeathReasons[p.name] = "Malédiction du Pantin";
      }

      if (p.role?.toLowerCase() == "grand-mère" && p.isAlive) {
        if (p.hasBakedQuiche) {
          p.isVillageProtected = true;
          p.hasBakedQuiche = false;
          p.powerActiveThisTurn = true;
          debugPrint("🥧 LOG [Grand-mère] : Quiche prête pour la Nuit ${globalTurnNumber + 1}.");
        } else if (p.isVillageProtected && !p.powerActiveThisTurn) {
          p.isVillageProtected = false;
          p.hasSavedSelfWithQuiche = false; // Reset du flag de succès
          debugPrint("🥧 LOG [Grand-mère] : Fin de protection.");
        }
      }

      p.powerActiveThisTurn = false;
      p.isProtectedByPokemon = false;
      if (!p.hasBeenHitByDart) p.isEffectivelyAsleep = false;
    }

    debugPrint("🏁 LOG [Logic] : Résolution terminée.");
    return NightResult(
      deadPlayers: aliveBefore.where((p) => !p.isAlive).toList(),
      deathReasons: finalDeathReasons,
      villageWasProtected: quicheIsActive,
      revealedRoleMessage: null,
      villageIsNarcoleptic: somnifereActive,
    );
  }
}