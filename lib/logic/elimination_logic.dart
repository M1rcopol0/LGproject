import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';
import 'achievement_logic.dart';
import '../services/trophy_service.dart';

class EliminationLogic {

  /// Tue un joueur et gère TOUTES les réactions en chaîne (Amants, Sacrifices, etc.).
  /// Retourne la liste de TOUS les morts (Cible + Amant...).
  static List<Player> eliminatePlayer(BuildContext context, List<Player> allPlayers, Player target,
      {bool isVote = false, String reason = ""}) {

    List<Player> deadPeople = [];

    // 1. Rafraîchissement de la cible pour s'assurer d'avoir l'objet à jour
    Player realTarget = allPlayers.firstWhere(
      (p) => p.name == target.name,
      orElse: () => throw StateError("Player ${target.name} not found in allPlayers")
    );

    if (!realTarget.isAlive) return []; // Déjà mort, on ne fait rien

    final String roleLower = realTarget.role?.toLowerCase() ?? "";

    // =========================================================================
    // VÉRIFICATION DES IMMUNITÉS ET SURVIES
    // =========================================================================

    // --- IMMUNITÉ ARCHIVISTE ---
    if (realTarget.isAwayAsMJ) {
      debugPrint("🛡️ LOG [Archiviste] : Cible absente (Switch MJ). Immunité totale.");
      return [];
    }

    // --- PANTIN (Survie au premier vote) ---
    if (roleLower == "pantin") {
      bool isManualKill = reason.contains("Manuel") || reason.contains("MJ");

      if (!isVote && !isManualKill) {
        if (reason.contains("Chagrin d'amour")) {
          // FIX BUG 10 : Pantin lié par Cupidon → chagrin d'amour DIFFÉRÉ (timer 2 nuits)
          if ((realTarget.pantinCurseTimer ?? 0) == 0) {
            realTarget.pantinCurseTimer = 2;
          }
          debugPrint("💔 LOG [Pantin] : Chagrin d'amour différé → pantinCurseTimer=${realTarget.pantinCurseTimer}.");
        } else {
          // Le Pantin ne meurt pas la nuit s'il est attaqué
          debugPrint("🛡️ LOG [Pantin] : Survit à l'attaque nocturne.");
        }
        return [];
      } else if (isVote) {
        if (!realTarget.hasSurvivedVote) {
          // --- LOGIQUE CLUTCH PANTIN (Succès) ---
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
          return [];
        }
      }
    }

    // --- CLUTCH PANTIN (Si le Pantin n'est pas la cible mais vote contre le mourant) ---
    if (isVote && roleLower != "pantin") {
      try {
        Player? pantin = allPlayers.cast<Player?>().firstWhere(
          (p) => p!.isAlive && p.role?.toLowerCase() == "pantin",
          orElse: () => null
        );

        if (pantin != null) {
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
        }
      } catch (e) {
        debugPrint("⚠️ LOG [Pantin] : Erreur détection clutch - $e");
      }
    }

    // --- BOUC ÉMISSAIRE (Consommation du pouvoir) ---
    if (isVote && realTarget.hasScapegoatPower) {
      realTarget.hasScapegoatPower = false;
      debugPrint("🐏 LOG [Archevêque] : Bouc émissaire consommé, mais la sentence est exécutée.");
    }

    // --- VOYAGEUR (Retour forcé) ---
    if (roleLower == "voyageur" && realTarget.isInTravel) {
      realTarget.isInTravel = false;
      realTarget.canTravelAgain = false;
      debugPrint("✈️ LOG [Voyageur] : Forcé au retour du voyage.");
      // S'il n'est pas voté (donc attaqué de nuit), il revient mais ne meurt pas (selon règles précédentes)
      if (!isVote) return [];
    }

    // =========================================================================
    // GESTION DES SACRIFICES (REDIRECTIONS)
    // =========================================================================

    // --- LOGIQUE MAISON ---
    if (realTarget.isInHouse && !reason.contains("Malédiction")) {
      Player? houseOwner;
      try {
        houseOwner = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "maison" && p.isAlive && !p.isHouseDestroyed);
      } catch (e) { houseOwner = null; }

      if (houseOwner != null) {
        if (houseOwner.isFanOfRonAldo) {
          // La maison est fan, elle ne s'effondre pas, la cible meurt normalement
          debugPrint("🏠 CAPTEUR [Mort] : Maison fan de Ron-Aldo -> pas d'effondrement, cible directe: ${realTarget.name}.");
        } else {
          // La maison s'effondre, le propriétaire meurt A LA PLACE de la cible
          houseOwner.isHouseDestroyed = true;
          for (var p in allPlayers) { p.isInHouse = false; }

          debugPrint("🏠 LOG [Maison] : Effondrement ! Le propriétaire meurt à la place de ${realTarget.name}");
          AchievementLogic.checkHouseCollapse(context, houseOwner);

          // L'invité survit grâce à l'effondrement
          TrophyService.checkAndUnlockImmediate(
            context: context,
            playerName: realTarget.name,
            achievementId: "assurance_habitation",
            checkData: {'assurance_habitation_triggered': true},
          );

          // RÉCURSIVITÉ : On tue le propriétaire à la place
          return eliminatePlayer(context, allPlayers, houseOwner, isVote: isVote, reason: "Effondrement Maison");
        }
      }
    }

    // --- LOGIQUE RON-ALDO ---
    else if (roleLower == "ron-aldo") {
      try {
        Player firstFan = allPlayers.firstWhere(
              (p) => p.isFanOfRonAldo && p.fanJoinOrder == 1 && p.isAlive,
          orElse: () => Player(name: "None"),
        );

        if (firstFan.name != "None") {
          debugPrint("🛡️ LOG [Ron-Aldo] : Le Premier Fan (${firstFan.name}) se sacrifie !");
          AchievementLogic.checkFanSacrifice(context, firstFan, realTarget);

          // RÉCURSIVITÉ : On tue le Fan à la place
          return eliminatePlayer(context, allPlayers, firstFan, isVote: isVote, reason: "Sacrifice pour Ron-Aldo");
        }
      } catch (e) {
        debugPrint("⚠️ Erreur logique Ron-Aldo : $e");
      }
    }

    // =========================================================================
    // APPLICATION DE LA MORT
    // =========================================================================

    // Si on arrive ici, le joueur meurt effectivement.
    realTarget.isAlive = false;
    deadPeople.add(realTarget);
    debugPrint("💀 LOG [Mort] : ${realTarget.name} (${realTarget.role}) a quitté la partie. Raison: $reason");

    // --- LOUIS CROIX V (Roi exécuté par le peuple) ---
    if (isVote && realTarget.isVillageChief && globalGovernanceMode == "ROI") {
      TrophyService.checkAndUnlockImmediate(
        context: context,
        playerName: realTarget.name,
        achievementId: "louis_croix_v",
        checkData: {'louis_croix_v_triggered': true},
      );
    }

    // --- CHAMAN SNIPER ---
    if (isVote && nightChamanTarget != null && realTarget.name == nightChamanTarget!.name) {
      debugPrint("💀 CAPTEUR [Mort] : Chaman sniper détecté ! Cible du chaman ${nightChamanTarget!.name} éliminée au vote.");
      chamanSniperAchieved = true;
    }

    // --- FIRST BLOOD ---
    if (!anybodyDeadYet) {
      anybodyDeadYet = true;
      firstDeadPlayerName = realTarget.name;
      AchievementLogic.checkFirstBlood(context, realTarget);
    }

    // --- POKEMON MORT TÔT (tours 1-2, jour ou nuit) ---
    if ((roleLower == "pokémon" || roleLower == "pokemon") && globalTurnNumber <= 2) {
      pokemonDiedTour1 = true;
    }

    // --- ACHIEVEMENTS GÉNÉRAUX ---
    AchievementLogic.checkDeathAchievements(context, realTarget, allPlayers);

    // --- FAIM DU LOUP (ÉVOLUÉ) ---
    if (isVote && realTarget.hasSurvivedWolfBite) {
      AchievementLogic.checkEvolvedHunger(context, realTarget, allPlayers);
    }

    // =========================================================================
    // RÉACTIONS EN CHAÎNE (LIENS)
    // =========================================================================

    // 1. LIEN AMOUREUX (CUPIDON)
    if (realTarget.isLinked) {
      try {
        // On cherche le partenaire vivant
        Player? lover = allPlayers.cast<Player?>().firstWhere(
          (p) => p!.isLinked && p.name != realTarget.name && p.isAlive,
          orElse: () => null,
        );

        // Protection contre boucle infinie : vérifier que lover n'est pas déjà dans deadPeople
        if (lover != null && !deadPeople.any((p) => p.name == lover!.name)) {
          debugPrint("💔 DRAME : ${realTarget.name} meurt et entraîne son amant ${lover.name} dans la tombe !");

          // RÉCURSIVITÉ : On tue l'amant immédiatement
          List<Player> loverDeaths = eliminatePlayer(context, allPlayers, lover, isVote: isVote, reason: "Chagrin d'amour");
          deadPeople.addAll(loverDeaths);
        }
      } catch (e) {
        debugPrint("⚠️ LOG [Cupidon] : Erreur lien amoureux - $e");
      }
    }

    // 2. LIEN MODÈLE -> ENFANT SAUVAGE (Transformation)
    try {
      Player child = allPlayers.firstWhere(
              (p) => (p.role?.toLowerCase() == "enfant sauvage") && p.isAlive && p.modelPlayer?.name == realTarget.name
      );
      debugPrint("👶 TRANSFORMATION : Le modèle est mort. L'Enfant Sauvage ${child.name} passe chez les LOUPS !");
      child.team = "loups";

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("L'Enfant Sauvage (${child.name}) a rejoint les Loups !"), backgroundColor: Colors.red)
        );
      }
    } catch(e) {}

    // Note : Le lien Dresseur -> Pokémon n'est PAS géré ici car le Pokémon ne meurt pas automatiquement
    // si le Dresseur meurt (sauf sacrifice de nuit spécifique).

    return deadPeople;
  }
}