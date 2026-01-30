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

    // --- 0. INTÉGRATION ACTIONS MAÎTRE DU TEMPS (CORRECTIF CRUCIAL) ---
    // On vérifie si le Maître du Temps a marqué des cibles dans son profil
    for (var p in players) {
      if (p.role?.toLowerCase() == "maître du temps" && p.isAlive && p.timeMasterTargets.isNotEmpty) {
        debugPrint("⏳ LOG [TimeMaster] : Exécution des cibles : ${p.timeMasterTargets}");
        for (var targetName in p.timeMasterTargets) {
          try {
            Player target = players.firstWhere((t) => t.name == targetName);
            if (target.isAlive) {
              // On ajoute la mort à la liste des morts en attente
              pendingDeathsMap[target] = "Effacé du temps (Maître du Temps)";
            }
          } catch (e) {
            debugPrint("⚠️ Erreur cible Time Master: $targetName introuvable.");
          }
        }
        // On vide la liste pour ne pas les retuer la nuit suivante
        p.timeMasterTargets.clear();
      }
    }

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

    // --- 2. LOGIQUE EXPLOSION BOMBE TARDOS (PRIORITAIRE) ---
    for (var p in players) {
      if (p.hasPlacedBomb && p.bombTimer == 0 && p.tardosTarget != null) {
        Player target = p.tardosTarget!;
        debugPrint("💥 LOG [Explosion] : La bombe de ${p.name} EXPLOSE sur ${target.name} !");

        // Suicide Tardos (Succès Oups)
        if (target == p) {
          p.tardosSuicide = true;
          AchievementLogic.checkTardosOups(context, p);
        }

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

        target.isBombed = false;
        p.tardosTarget = null;
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

    // --- 4. RÉSOLUTION DES MORTS (Morsures, Tirs, Bombes, MAÎTRE DU TEMPS) ---
    if (somnifereActive) {
      debugPrint("💤 LOG [Somnifère] : Sommeil général. Aucune mort physique n'est appliquée.");
      pendingDeathsMap.clear();
    } else {
      pendingDeathsMap.forEach((target, reason) {
        if (!target.isAlive) return;

        if (target.isAwayAsMJ) {
          debugPrint("🛡️ LOG [Archiviste] : Attaque sur Archiviste annulée (Absent).");
          return;
        }

        bool isUnstoppable = reason.contains("accidentelle") ||
            reason.contains("Bombe") ||
            reason.contains("Tardos") ||
            reason.contains("Maison") ||
            reason.contains("Temps"); // Le Maître du Temps est imparable

        if (quicheIsActive && !isUnstoppable) {
          quicheSavedThisNight++;
          if (target.role?.toLowerCase() == "grand-mère") {
            target.hasSavedSelfWithQuiche = true;
            debugPrint("👵 LOG [Succès] : La Grand-mère s'est sauvée elle-même !");
          }
          debugPrint("🛡️ LOG [Quiche] : ${target.name} sauvé de : $reason");
          return;
        }

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

        if (target.isProtectedByPokemon && !reason.contains("Tardos") && !reason.contains("Temps")) {
          debugPrint("🛡️ LOG [Pokémon] : ${target.name} protégé.");
          return;
        }

        bool targetWasInHouse = target.isInHouse;
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
              !reason.contains("Tardos") && !reason.contains("Temps")) {
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
        if (quicheIsActive) {
          debugPrint("🥧 LOG [Pantin] : ${p.name} survit à la malédiction grâce à la Quiche (Report +1 jour).");
          p.pantinCurseTimer = 1;
          quicheSavedThisNight++;
        } else {
          debugPrint("🎭 LOG [Pantin] : Mort de la malédiction : ${p.name}");

          p.isAlive = false;
          AchievementLogic.checkDeathAchievements(context, p, players);
          finalDeathReasons[p.name] = "Malédiction du Pantin";

          // Si c'est le Pokémon qui meurt de malédiction, il se venge quand même
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

      if (!p.hasBeenHitByDart) p.isEffectivelyAsleep = false;
    }

    debugPrint("🏁 LOG [Logic] : Résolution terminée.");
    return NightResult(
      deadPlayers: aliveBefore.where((p) => !p.isAlive).toList(),
      deathReasons: finalDeathReasons,
      villageWasProtected: quicheIsActive,
      announcements: morningAnnouncements,
      villageIsNarcoleptic: somnifereActive,
      revealedPlayerNames: playersToReveal,
    );
  }
}