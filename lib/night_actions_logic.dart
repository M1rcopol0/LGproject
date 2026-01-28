import 'package:flutter/material.dart';
import 'models/player.dart';
import 'logic.dart';
import 'globals.dart';
import 'achievement_logic.dart';

class NightResult {
  final List<Player> deadPlayers;
  final Map<String, String> deathReasons;
  final bool villageWasProtected;
  final List<String> announcements;
  final bool villageIsNarcoleptic;
  final bool exorcistVictory;

  // NOUVEAU : Liste des joueurs dont le rôle est officiellement révélé ce matin
  final List<String> revealedPlayerNames;

  NightResult({
    required this.deadPlayers,
    required this.deathReasons,
    required this.villageWasProtected,
    this.announcements = const [],
    this.villageIsNarcoleptic = false,
    this.exorcistVictory = false,
    this.revealedPlayerNames = const [], // Initialisation par défaut
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
      if (p.hasPlacedBomb && p.tardosTarget != null && p.bombTimer > 0) {
        p.bombTimer--;
        debugPrint("💣 LOG [Tardos] : La bombe posée par ${p.name} tic-tac... (T-Minus: ${p.bombTimer})");
      }

      // --- LOGIQUE VOYAGEUR (Munitions & Stats) ---
      if (p.role?.toLowerCase() == "voyageur" && p.isInTravel) {
        AchievementLogic.updateVoyageur(p);
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
    List<String> morningAnnouncements = [];

    // Liste temporaire pour stocker les révélations du Devin avant de les passer à l'UI
    List<String> playersToReveal = [];

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

    // --- 1. GÉNÉRATION DES ANNONCES (HOUSTON / DEVIN) ---

    // HOUSTON
    try {
      Player houston = players.firstWhere((p) => p.role?.toLowerCase() == "houston" && p.isAlive);
      if (houston.houstonTargets.length == 2) {
        Player p1 = houston.houstonTargets[0];
        Player p2 = houston.houstonTargets[1];
        bool sameTeam = (p1.team == p2.team);

        String phrase = sameTeam ? "QUI VOILÀ-JE !" : "HOUSTON, ON A UN PROBLÈME !";
        morningAnnouncements.add("🛰️ HOUSTON : $phrase\n(Analyse de ${p1.name} & ${p2.name})");

        // --- DÉTECTION SUCCÈS APOLLO 13 ---
        bool oneWolf = (p1.team == "loups" || p2.team == "loups");
        bool oneSolo = (p1.team == "solo" || p2.team == "solo");
        if (oneWolf && oneSolo) {
          houston.houstonApollo13Triggered = true;
          debugPrint("🛰️ LOG [Succès] : Apollo 13 détecté !");
        }

        houston.houstonTargets = [];
      }
    } catch (e) {}

    // DEVIN
    try {
      Player devin = players.firstWhere((p) => p.role?.toLowerCase() == "devin" && p.isAlive);
      // Si le Devin a une cible et que le compteur indique que la nuit est validée (>= 2)
      if (devin.concentrationTargetName != null && devin.concentrationNights >= 2) {
        Player? target = players.firstWhere((p) => p.name == devin.concentrationTargetName, orElse: () => Player(name: "Inconnu"));
        if (target.name != "Inconnu") {
          // 1. On prépare l'annonce
          morningAnnouncements.add("👁️ DEVIN : ${target.name} est ${target.role?.toUpperCase()}");

          // 2. On ajoute à la liste des révélations pour l'UI (Icone Œil)
          playersToReveal.add(target.name);

          // 3. Stats & Reset
          devin.devinRevealsCount++;
          if (devin.revealedPlayersHistory.contains(target.name)) {
            devin.hasRevealedSamePlayerTwice = true;
            // --- CORRECTION : APPEL DU SUCCÈS ---
            AchievementLogic.checkDevinAchievements(devin);
          }
          devin.revealedPlayersHistory.add(target.name);

          devin.concentrationTargetName = null;
          devin.concentrationNights = 0;
        }
      }
    } catch (e) {}

    // --- 2. LOGIQUE EXPLOSION BOMBE TARDOS (PRIORITAIRE) ---
    for (var p in players) {
      if (p.hasPlacedBomb && p.bombTimer == 0 && p.tardosTarget != null) {
        Player target = p.tardosTarget!;
        debugPrint("💥 LOG [Explosion] : La bombe de ${p.name} EXPLOSE sur ${target.name} !");

        if (target.role?.toLowerCase() == "maison" || target.isInHouse) {
          debugPrint("🏠💥 LOG [Tardos] : La bombe détruit la Maison et ses occupants !");
          try {
            Player houseOwner = players.firstWhere((h) => h.role?.toLowerCase() == "maison");
            pendingDeathsMap[houseOwner] = "Explosion Maison (Tardos)";
          } catch(e) { }

          for (var occupant in players.where((o) => o.isInHouse)) {
            pendingDeathsMap[occupant] = "Effondrement Maison (Tardos)";
          }
        }
        else if (target.isAlive) {
          pendingDeathsMap[target] = "Explosion Bombe (Tardos)";
        } else {
          debugPrint("🌬️ LOG [Tardos] : La bombe explose sur un cadavre.");
        }

        // Nettoyage visuel et logique
        target.isBombed = false;
        p.tardosTarget = null;
        // Note: p.hasPlacedBomb reste true pour bloquer l'interface Tardos
      }
    }

    // --- 3. ÉVALUATION DE LA PROTECTION QUICHE ---
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

    // --- 4. RÉSOLUTION DES MORTS (Morsures, Tirs, Bombes) ---
    if (somnifereActive) {
      debugPrint("💤 LOG [Somnifère] : Sommeil général. Aucune mort physique n'est appliquée.");
      pendingDeathsMap.clear();
    } else {
      pendingDeathsMap.forEach((target, reason) {
        if (!target.isAlive) return;

        bool isUnstoppable = reason.contains("accidentelle") ||
            reason.contains("Bombe") ||
            reason.contains("Tardos") ||
            reason.contains("Maison");

        if (quicheIsActive && !isUnstoppable) {
          quicheSavedThisNight++;
          if (target.role?.toLowerCase() == "grand-mère") {
            target.hasSavedSelfWithQuiche = true;
            debugPrint("👵 LOG [Succès] : La Grand-mère s'est sauvée elle-même !");
          }
          debugPrint("🛡️ LOG [Quiche] : ${target.name} sauvé de : $reason");
          return;
        }

        if (target.isProtectedByPokemon && !reason.contains("Tardos")) {
          debugPrint("🛡️ LOG [Pokémon] : ${target.name} protégé.");
          return;
        }

        bool targetWasInHouse = target.isInHouse;
        Player finalVictim = GameLogic.eliminatePlayer(context, players, target, isVote: false);

        if (!finalVictim.isAlive) {
          // --- SUCCÈS DINGO : UN TIR DU PARKING ---
          if (reason.contains("Tir du Dingo")) {
            try {
              Player dingo = players.firstWhere((p) => p.role?.toLowerCase() == "dingo");
              AchievementLogic.checkParkingShot(dingo, finalVictim, players);
            } catch (e) {
              debugPrint("⚠️ Erreur succès Dingo : $e");
            }
          }

          if (targetWasInHouse &&
              finalVictim.role?.toLowerCase() == "maison" &&
              finalVictim != target &&
              !reason.contains("Tardos")) {
            debugPrint("🏠 LOG [Maison] : Effondrement protecteur pour ${target.name}.");
            finalDeathReasons[finalVictim.name] = "Protection de ${target.name} ($reason)";
          } else {
            debugPrint("💀 LOG [Mort] : ${finalVictim.name} succombe ($reason).");
            finalDeathReasons[finalVictim.name] = reason;
          }
          if (reason.contains("Morsure")) wolvesNightKills++;
        }
      });
    }

    // --- 5. MORTS DIFFÉRÉES ET CLEANUP ---
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
          p.hasSavedSelfWithQuiche = false;
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
      announcements: morningAnnouncements,
      villageIsNarcoleptic: somnifereActive,
      revealedPlayerNames: playersToReveal, // Transmission de la liste à l'UI
    );
  }
}