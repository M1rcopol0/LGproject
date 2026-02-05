import 'package:flutter/material.dart';
import 'models/player.dart';
import 'logic.dart';
import 'globals.dart';
import 'achievement_logic.dart';
import 'trophy_service.dart'; // Import nécessaire pour les succès immédiats

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
  // 1. PRÉ-RÉSOLUTION (Appelée au début de la nuit)
  // =========================================================
  static void prepareNightStates(List<Player> players) {
    debugPrint("--------------------------------------------------");
    debugPrint("🌙 LOG [Logic] : Préparation de la Nuit $globalTurnNumber");

    for (var p in players) {
      // --- LOGIQUE BOMBE TARDOS (PROJECTILE AUTONOME - VIA RÔLE) ---
      if (p.hasPlacedBomb && p.tardosTarget != null && p.bombTimer > 0) {
        p.bombTimer--;
        debugPrint("💣 LOG [Tardos] : La bombe de ${p.name} tic-tac... (T-Minus: ${p.bombTimer})");
      }

      // --- LOGIQUE BOMBE MANUELLE (VIA MENU MJ) ---
      if (p.isBombed && p.attachedBombTimer > 0) {
        // Double sécurité : si un Tardos vise ce joueur, on ignore le timer manuel pour éviter les conflits
        bool targetedByTardos = players.any((attacker) =>
        attacker.role?.toLowerCase() == "tardos" &&
            attacker.hasPlacedBomb &&
            attacker.tardosTarget == p
        );

        if (!targetedByTardos) {
          p.attachedBombTimer--;
          debugPrint("🧨 LOG [MJ] : Bombe manuelle sur ${p.name} tic-tac... (T-Minus: ${p.attachedBombTimer})");
        }
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

    // --- 0. INTÉGRATION ACTIONS MAÎTRE DU TEMPS ---
    for (var p in players) {
      if (p.role?.toLowerCase() == "maître du temps" && p.isAlive && p.timeMasterTargets.isNotEmpty) {
        debugPrint("⏳ LOG [TimeMaster] : Exécution des cibles : ${p.timeMasterTargets}");

        List<Player> killedByTime = [];

        for (var targetName in p.timeMasterTargets) {
          try {
            Player target = players.firstWhere((t) => t.name == targetName);
            if (target.isAlive) {
              pendingDeathsMap[target] = "Effacé du temps (Maître du Temps)";
              killedByTime.add(target);
            }
          } catch (e) {
            debugPrint("⚠️ Erreur cible Time Master: $targetName introuvable.");
          }
        }

        // Vérification du succès Paradoxe
        if (killedByTime.length >= 2) {
          Set<String> teams = killedByTime.map((kp) => kp.team).toSet();
          if (teams.length >= 2) {
            debugPrint("⏳ LOG [Succès] : Paradoxe Temporel détecté !");
            paradoxAchieved = true;

            TrophyService.checkAndUnlockImmediate(
              context: context,
              playerName: p.name,
              achievementId: "time_paradox",
              checkData: {
                'player_role': 'Maître du temps',
                'paradox_achieved': true
              },
            );
          }
        }

        p.timeMasterTargets.clear();
      }
    }

    // --- 0.5 ANALYSE MAISON (EPSTEIN & RON-ALDO) ---
    try {
      // CORRECTION CRITIQUE : On cherche la maison, même si elle vient d'être convertie en Fan (previousRole)
      Player? maison;
      try {
        maison = players.firstWhere((p) =>
        (p.role?.toLowerCase() == "maison" || p.previousRole?.toLowerCase() == "maison") &&
            p.isAlive
        );
      } catch (_) {}

      if (maison != null) {
        maison.hostedEnemiesCount = 0;
        maison.hostedRonAldoThisTurn = false;

        for (var invite in players.where((p) => p.isInHouse)) {
          // Epstein House : Compter les ennemis
          if (invite.team != "village") {
            maison.hostedEnemiesCount++;
          }

          // Repérage Ron-Aldo dans la maison (Flag vital pour "Ramenez la coupe")
          if (invite.role?.toLowerCase() == "ron-aldo") {
            maison.hostedRonAldoThisTurn = true;
            invite.hostedRonAldoThisTurn = true;
            debugPrint("🏠 LOG [Maison] : Ron-Aldo détecté chez ${maison.name}. Flag activé.");
          }
        }

        // Succès Epstein House
        if (maison.hostedEnemiesCount >= 2) {
          TrophyService.checkAndUnlockImmediate(
              context: context,
              playerName: maison.name,
              achievementId: "epstein_house",
              checkData: {
                'player_role': 'maison',
                'hosted_enemies_count': maison.hostedEnemiesCount
              }
          );
        }
      }
    } catch (_) {}

    // --- 1. GÉNÉRATION DES ANNONCES (HOUSTON / DEVIN / VOYAGEUR) ---

    // ANNONCE VOYAGEUR
    for (var p in players) {
      if (p.role?.toLowerCase() == "voyageur" && p.hasReturnedThisTurn) {
        morningAnnouncements.add("🌍 Le Voyageur est de retour au village !");
      }
    }

    // HOUSTON
    try {
      Player houston = players.firstWhere((p) => p.role?.toLowerCase() == "houston" && p.isAlive);
      if (houston.houstonTargets.length == 2) {
        Player p1 = houston.houstonTargets[0];
        Player p2 = houston.houstonTargets[1];
        bool sameTeam = (p1.team == p2.team);

        String phrase = sameTeam ? "QUI VOILÀ-JE !" : "HOUSTON, ON A UN PROBLÈME !";
        morningAnnouncements.add("🛰️ HOUSTON : $phrase\n(Analyse de ${p1.name} & ${p2.name})");

        AchievementLogic.checkApollo13(context, houston, p1, p2);
        houston.houstonTargets = [];
      }
    } catch (e) {}

    // DEVIN
    try {
      Player devin = players.firstWhere((p) => p.role?.toLowerCase() == "devin" && p.isAlive);
      if (devin.concentrationTargetName != null && devin.concentrationNights >= 2) {
        Player? target = players.firstWhere((p) => p.name == devin.concentrationTargetName, orElse: () => Player(name: "Inconnu"));
        if (target.name != "Inconnu") {
          morningAnnouncements.add("👁️ DEVIN : ${target.name} est ${target.role?.toUpperCase()}");
          playersToReveal.add(target.name);

          devin.devinRevealsCount++;
          if (devin.revealedPlayersHistory.contains(target.name)) {
            devin.hasRevealedSamePlayerTwice = true;
            AchievementLogic.checkDevinAchievements(context, devin);
          }
          devin.revealedPlayersHistory.add(target.name);

          devin.concentrationTargetName = null;
          devin.concentrationNights = 0;
        }
      }
    } catch (e) {}

    // --- 2. LOGIQUE EXPLOSION BOMBE (TARDOS & MANUELLE) ---

    // A. Bombe Tardos (Liée à l'attaquant via rôle)
    for (var p in players) {
      if (p.hasPlacedBomb && p.bombTimer == 0 && p.tardosTarget != null) {
        _handleExplosion(context, players, p.tardosTarget!, pendingDeathsMap, "Explosion Bombe (Tardos)", p);
        p.tardosTarget = null;
      }
    }

    // B. Bombe Manuelle (Liée à la victime via menu MJ)
    for (var p in players) {
      bool targetedByTardos = players.any((attacker) =>
      attacker.role?.toLowerCase() == "tardos" &&
          attacker.hasPlacedBomb &&
          attacker.tardosTarget == p
      );

      if (p.isBombed && p.attachedBombTimer == 0 && !targetedByTardos) {
        _handleExplosion(context, players, p, pendingDeathsMap, "Explosion Bombe (Manuelle)", null);
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

    Player? dresseur;
    Player? pokemon;
    try {
      dresseur = players.firstWhere((p) => p.role?.toLowerCase() == "dresseur" && p.isAlive);
      pokemon = players.firstWhere((p) => (p.role?.toLowerCase() == "pokémon" || p.role?.toLowerCase() == "pokemon") && p.isAlive);
    } catch (e) {}

    final List<Player> aliveBefore = players.where((p) => p.isAlive).toList();

    // --- 4. RÉSOLUTION DES MORTS ---
    if (somnifereActive) {
      debugPrint("💤 LOG [Somnifère] : Sommeil général. Aucune mort physique n'est appliquée.");
      pendingDeathsMap.clear();
    } else {
      pendingDeathsMap.forEach((target, reason) {
        if (!target.isAlive) return;

        // --- PROTECTION SORCIÈRE (VIE) ---
        // Si le joueur a été sauvé par la potion de vie (flag global), on annule la morsure
        if ((reason.contains("Morsure") || reason.contains("Attaque des Loups")) && nightWolvesTargetSurvived) {
          debugPrint("🧪 LOG [Sorcière] : ${target.name} a été ressuscité par la potion.");
          return; // Annulation de la mort
        }

        if (target.isAwayAsMJ) {
          debugPrint("🛡️ LOG [Archiviste] : Attaque sur Archiviste annulée (Absent).");
          return;
        }

        bool isUnstoppable = reason.contains("accidentelle") || // Suicide Tardos
            reason.contains("Bombe") ||        // Explosion Tardos
            reason.contains("Tardos") ||       // Explosion Tardos
            reason.contains("Maison");         // Effondrement Maison

        if (quicheIsActive && !isUnstoppable) {
          quicheSavedThisNight++;

          if (target.role?.toLowerCase() == "grand-mère") {
            target.hasSavedSelfWithQuiche = true;
            debugPrint("👵 LOG [Succès] : La Grand-mère s'est sauvée elle-même !");

            TrophyService.checkAndUnlockImmediate(
                context: context,
                playerName: target.name,
                achievementId: "self_quiche_save",
                checkData: {'saved_by_own_quiche': true, 'player_role': 'grand-mère'}
            );
          }

          debugPrint("🛡️ LOG [Quiche] : ${target.name} sauvé de : $reason");

          if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
            target.hasSurvivedWolfBite = true;
            nightWolvesTargetSurvived = true;
          }

          return;
        }

        // --- PROTECTION SALTIMBANQUE ---
        if (target.isProtectedBySaltimbanque && !isUnstoppable) {
          debugPrint("🛡️ LOG [Saltimbanque] : ${target.name} protégé cette nuit.");
          if (reason.contains("Morsure")) nightWolvesTargetSurvived = true;
          return;
        }

        // --- SACRIFICE POKÉMON ---
        if (dresseur != null && dresseur.lastDresseurAction != null) {
          if (target == dresseur && dresseur.lastDresseurAction == dresseur) {
            if (pokemon != null && pokemon.isAlive) {
              debugPrint("🦅 LOG [Dresseur] : Dresseur attaqué mais s'est protégé. Le Pokémon meurt à sa place !");
              Player pokemonVictim = GameLogic.eliminatePlayer(context, players, pokemon, isVote: false);
              if (!pokemonVictim.isAlive) {
                finalDeathReasons[pokemonVictim.name] = "Sacrifice pour le Dresseur ($reason)";
                AchievementLogic.checkDeathAchievements(context, pokemonVictim, players);
                if (pokemonVictim.pokemonRevengeTarget != null && pokemonVictim.pokemonRevengeTarget!.isAlive) {
                  Player revenge = pokemonVictim.pokemonRevengeTarget!;
                  debugPrint("⚡ LOG [Pokémon] : MORT (Sacrifice)! Il emporte ${revenge.name} (${revenge.role}).");
                  morningAnnouncements.add("⚡ Le Pokémon (Sacrifié) emporte ${revenge.name} (${revenge.role}) !");
                  GameLogic.eliminatePlayer(context, players, revenge, isVote: false);
                }
              }
              return;
            }
          }
          if (target == pokemon && dresseur.lastDresseurAction == pokemon) {
            debugPrint("🦅 LOG [Dresseur] : Pokémon attaqué mais protégé par le Dresseur. Il survit !");
            return;
          }
        }

        if (target.isProtectedByPokemon && !reason.contains("Tardos") && !reason.contains("Temps") && !reason.contains("Bombe")) {
          debugPrint("🛡️ LOG [Pokémon] : ${target.name} protégé.");
          if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
            target.hasSurvivedWolfBite = true;
            nightWolvesTargetSurvived = true;
          }
          return;
        }

        bool targetWasInHouse = target.isInHouse;

        // ===========================================================
        // LOGIQUE SACRIFICE RON-ALDO (CORRIGÉE & PRIORISÉE)
        // ===========================================================
        if (target.role?.toLowerCase() == "ron-aldo" && !isUnstoppable) {
          try {
            List<Player> fans = players.where((p) => p.isFanOfRonAldo && p.isAlive).toList();

            Player? priorityFan;
            try {
              priorityFan = fans.firstWhere((p) => p.hostedRonAldoThisTurn);
            } catch (_) {}

            if (priorityFan != null) {
              fans.remove(priorityFan);
              fans.insert(0, priorityFan);
              debugPrint("⚽🏆 LOG [Ron-Aldo] : La Maison convertie (${priorityFan.name}) devient prioritaire pour le sacrifice.");
            } else {
              fans.sort((a, b) => a.fanJoinOrder.compareTo(b.fanJoinOrder));
            }

            if (fans.isNotEmpty) {
              Player fanSacrifice = fans.first;
              debugPrint("🛡️⚽ LOG [Ron-Aldo] : ${fanSacrifice.name} se sacrifie pour sauver Ron-Aldo !");

              Player deadFan = GameLogic.eliminatePlayer(context, players, fanSacrifice, isVote: false, reason: "Sacrifice pour Ron-Aldo");
              finalDeathReasons[deadFan.name] = "Sacrifice pour Ron-Aldo ($reason)";
              AchievementLogic.checkDeathAchievements(context, deadFan, players);
              AchievementLogic.checkFanSacrifice(context, deadFan, target);

              if (deadFan.hostedRonAldoThisTurn) {
                TrophyService.checkAndUnlockImmediate(
                    context: context,
                    playerName: deadFan.name,
                    achievementId: "coupe_maison",
                    checkData: {'ramenez_la_coupe': true}
                );
                TrophyService.checkAndUnlockImmediate(
                    context: context,
                    playerName: target.name,
                    achievementId: "coupe_maison",
                    checkData: {'ramenez_la_coupe': true}
                );
              }

              return; // Ron-Aldo est sauvé
            }
          } catch(e) {
            debugPrint("⚠️ Erreur sacrifice Ron-Aldo: $e");
          }
        }

        // --- MORT NORMALE ---
        Player finalVictim = GameLogic.eliminatePlayer(context, players, target, isVote: false);

        if (!finalVictim.isAlive) {
          AchievementLogic.checkDeathAchievements(context, finalVictim, players);

          if (reason.contains("Tir du Voyageur")) {
            try {
              Player voyageur = players.firstWhere((p) => p.role?.toLowerCase() == "voyageur");
              if (finalVictim.team == "loups") voyageur.travelerKilledWolf = true;
            } catch (_) {}
          }

          if (reason.contains("Tir du Dingo")) {
            try {
              Player dingo = players.firstWhere((p) => p.role?.toLowerCase() == "dingo");
              AchievementLogic.checkParkingShot(context, dingo, finalVictim, players);
            } catch (e) {}
          }

          if ((finalVictim.role?.toLowerCase() == "pokémon" || finalVictim.role?.toLowerCase() == "pokemon") &&
              finalVictim.pokemonRevengeTarget != null) {

            Player revengeTarget = finalVictim.pokemonRevengeTarget!;
            if (revengeTarget.isAlive) {
              debugPrint("⚡ LOG [Pokémon] : MORT ! Il emporte ${revengeTarget.name} dans la tombe (Vengeance).");
              morningAnnouncements.add("⚡ Le Pokémon emporte ${revengeTarget.name} (${revengeTarget.role}) dans sa chute !");

              Player revengeVictim = GameLogic.eliminatePlayer(context, players, revengeTarget, isVote: false);
              if (!revengeVictim.isAlive) {
                AchievementLogic.checkDeathAchievements(context, revengeVictim, players);
                finalDeathReasons[revengeVictim.name] = "Vengeance du Pokémon";
              }
            }
          }

          if (targetWasInHouse &&
              finalVictim.role?.toLowerCase() == "maison" &&
              finalVictim != target &&
              !reason.contains("Tardos") && !reason.contains("Temps") && !reason.contains("Bombe")) {
            debugPrint("🏠 LOG [Maison] : Effondrement protecteur pour ${target.name}.");
            finalDeathReasons[finalVictim.name] = "Protection de ${target.name} ($reason)";

            TrophyService.checkAndUnlockImmediate(
                context: context,
                playerName: target.name,
                achievementId: "assurance_habitation",
                checkData: {'assurance_habitation_triggered': true}
            );

            if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
              target.hasSurvivedWolfBite = true;
            }

          } else {
            debugPrint("💀 LOG [Mort] : ${finalVictim.name} succombe ($reason).");
            finalDeathReasons[finalVictim.name] = reason;
          }
          if (reason.contains("Morsure")) wolvesNightKills++;

          // --- GESTION CUPIDON (MORTS LIÉES) ---
          if (finalVictim.isLinkedByCupidon && finalVictim.lover != null) {
            Player lover = finalVictim.lover!;
            // Si l'amant est mort (via récursivité dans eliminatePlayer) et qu'on ne l'a pas encore noté
            if (!lover.isAlive && !finalDeathReasons.containsKey(lover.name)) {
              finalDeathReasons[lover.name] = "Chagrin d'amour (Lié à ${finalVictim.name})";
            }
          }

        } else {
          // Survie (ex: Pantin Immunisé, Voyageur)
          if (reason.contains("Attaque des Loups") || reason.contains("Morsure")) {
            target.hasSurvivedWolfBite = true;
            nightWolvesTargetSurvived = true;
          }
        }
      });
    }

    // --- 5. MORTS DIFFÉRÉES ET CLEANUP ---
    for (var p in players) {
      if (p.isAlive && p.pantinCurseTimer == 0) {
        if (quicheIsActive) {
          debugPrint("🥧 LOG [Pantin] : ${p.name} survit à la malédiction grâce à la Quiche (Report +1 jour).");
          p.pantinCurseTimer = 1;
          quicheSavedThisNight++;
        } else {
          debugPrint("🎭 LOG [Pantin] : Mort de la malédiction : ${p.name}");

          p.isAlive = false;
          AchievementLogic.checkDeathAchievements(context, p, players);
          finalDeathReasons[p.name] = "Malédiction du Pantin";

          if ((p.role?.toLowerCase() == "pokémon" || p.role?.toLowerCase() == "pokemon") && p.pokemonRevengeTarget != null) {
            Player rev = p.pokemonRevengeTarget!;
            if (rev.isAlive) {
              rev.isAlive = false;
              finalDeathReasons[rev.name] = "Vengeance du Pokémon";
              morningAnnouncements.add("⚡ Le Pokémon emporte ${rev.name} (${rev.role}) dans sa chute !");
            }
          }
        }
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
      p.hasReturnedThisTurn = false;
      p.hostedRonAldoThisTurn = false;
      p.isProtectedBySaltimbanque = false; // Reset Saltimbanque

      if (!p.hasBeenHitByDart) p.isEffectivelyAsleep = false;
    }

    // Liste finale des morts (comparaison avant/après)
    List<Player> deadNow = players.where((p) => !p.isAlive && finalDeathReasons.containsKey(p.name)).toList();

    debugPrint("🏁 LOG [Logic] : Résolution terminée.");
    return NightResult(
      deadPlayers: deadNow,
      deathReasons: finalDeathReasons,
      villageWasProtected: quicheIsActive,
      announcements: morningAnnouncements,
      villageIsNarcoleptic: somnifereActive,
      revealedPlayerNames: playersToReveal,
    );
  }

  // --- HELPER EXPLOSION ---
  static void _handleExplosion(BuildContext context, List<Player> players, Player target, Map<Player, String> pendingDeathsMap, String reason, Player? attacker) {
    debugPrint("💥 LOG [Explosion] : BOUM sur ${target.name} !");

    if (attacker != null && target == attacker) {
      attacker.tardosSuicide = true;
      AchievementLogic.checkTardosOups(context, attacker);
    }

    if (target.role?.toLowerCase() == "maison" || target.isInHouse) {
      debugPrint("🏠💥 LOG [Explosion] : Dégâts collatéraux (Maison).");
      Player? houseOwner;
      try {
        houseOwner = players.firstWhere((h) => h.role?.toLowerCase() == "maison");
        pendingDeathsMap[houseOwner] = reason;
      } catch(e) { }

      var occupants = players.where((o) => o.isInHouse).toList();
      for (var occupant in occupants) {
        pendingDeathsMap[occupant] = "Effondrement Maison (Explosion)";
      }

      // --- SUCCÈS : 11 SEPTEMBRE & SELF-DESTRUCT ---
      if (houseOwner != null && occupants.isNotEmpty) {
        bool houseDead = pendingDeathsMap.containsKey(houseOwner);
        bool allOccupantsDead = occupants.every((o) => pendingDeathsMap.containsKey(o));

        if (houseDead && allOccupantsDead) {
          if (attacker != null && attacker.role?.toLowerCase() == "tardos") {
            TrophyService.checkAndUnlockImmediate(
                context: context,
                playerName: attacker.name,
                achievementId: "11_septembre",
                checkData: {'11_septembre_triggered': true}
            );

            if (pendingDeathsMap.containsKey(attacker)) {
              TrophyService.checkAndUnlockImmediate(
                  context: context,
                  playerName: attacker.name,
                  achievementId: "self_destruct",
                  checkData: {'self_destruct_triggered': true}
              );
            }
          }
        }
      }
    }
    else if (target.isAlive) {
      pendingDeathsMap[target] = reason;
    }

    target.isBombed = false;
    target.attachedBombTimer = 0;
  }
}