import 'dart:math';
import 'package:flutter/material.dart';
import 'models/player.dart';
import 'globals.dart';

class RoleDistributionLogic {
  static const List<String> _wolfRoles = [
    "Loup-garou chaman", "Loup-garou évolué", "Somnifère"
  ];

  static const List<String> _soloRoles = [
    "Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Pokémon", "Ron-Aldo"
  ];

  static void distribute(List<Player> players) {
    debugPrint("--------------------------------------------------");
    debugPrint("🎲 LOG [Distribution] : Début du tirage des rôles");

    if (players.length < 3) {
      debugPrint("⚠️ LOG [Distribution] : Pas assez de joueurs (minimum 3).");
      return;
    }

    // Extraction des joueurs sans rôle forcé
    List<Player> playersToAssign = players.where((p) => !p.isRoleLocked).toList();
    debugPrint("👥 LOG [Distribution] : Joueurs à assigner : ${playersToAssign.length} / ${players.length}");

    if (playersToAssign.isEmpty) {
      debugPrint("✅ LOG [Distribution] : Tous les rôles étaient déjà verrouillés.");
      return;
    }

    // Préparation des pools depuis les réglages globaux
    List<String> poolSolo = List.from(globalPickBan["solo"] ?? []);
    List<String> poolLoups = List.from(globalPickBan["loups"] ?? []);
    List<String> poolVillage = List.from(globalPickBan["village"] ?? []);

    int manualSoloCount = 0;
    int manualWolfCount = 0;

    // Analyse des rôles déjà verrouillés pour ajuster les quotas
    for (var p in players.where((p) => p.isRoleLocked)) {
      String r = p.role ?? "";
      debugPrint("🔒 LOG [Distribution] : Rôle verrouillé détecté : ${p.name} -> $r");

      if (_soloRoles.contains(r)) {
        manualSoloCount++;
        poolSolo.remove(r);
      }
      else if (_wolfRoles.contains(r)) {
        manualWolfCount++;
        if (r != "Loup-garou évolué") poolLoups.remove(r);
      }
      if (r != "Villageois") poolVillage.remove(r);
    }

    int totalPlayers = players.length;
    int assignedIndex = 0;
    playersToAssign.shuffle(); // Mélange aléatoire des joueurs pour l'attribution

    // =========================================================
    // CAS A : PETIT COMITÉ (4 À 6 JOUEURS) - MAX 1 HOSTILE
    // =========================================================
    if (totalPlayers >= 4 && totalPlayers <= 6) {
      debugPrint("📏 LOG [Distribution] : Mode 'Petit Comité' détecté.");
      if (manualSoloCount + manualWolfCount == 0) {
        List<String> possibleHostiles = [
          ...poolSolo.where((r) => r != "Dresseur" && r != "Pokémon"),
          ...poolLoups.where((r) => r != "Loup-garou chaman")
        ];

        if (possibleHostiles.isNotEmpty) {
          String r = possibleHostiles[Random().nextInt(possibleHostiles.length)];
          playersToAssign[assignedIndex].role = r;
          debugPrint("🎭 LOG [Distribution] : Attribution hostile unique : ${playersToAssign[assignedIndex].name} -> $r");
          assignedIndex++;
        }
      }
    }
    // =========================================================
    // CAS B : GRAND COMITÉ (7 JOUEURS ET PLUS)
    // =========================================================
    else if (totalPlayers >= 7) {
      int targetHostileCount = (totalPlayers * 0.35).round();
      debugPrint("📏 LOG [Distribution] : Mode 'Standard'. Quota hostiles visé : $targetHostileCount");

      // ÉTAPE 1 : Tirage du rôle SOLO (Prioritaire)
      if (manualSoloCount == 0 && assignedIndex < playersToAssign.length && poolSolo.isNotEmpty) {
        List<String> selectableSolo = poolSolo.where((r) => r != "Pokémon").toList();
        selectableSolo.shuffle();

        String selectedSolo = selectableSolo.first;

        if (selectedSolo == "Dresseur") {
          if ((playersToAssign.length - assignedIndex) >= 2) {
            playersToAssign[assignedIndex].role = "Dresseur";
            playersToAssign[assignedIndex + 1].role = "Pokémon";
            debugPrint("🐾 LOG [Distribution] : Tirage du DUO Dresseur/Pokémon pour ${playersToAssign[assignedIndex].name} et ${playersToAssign[assignedIndex+1].name}");
            assignedIndex += 2;
            targetHostileCount -= 2;
          } else {
            selectableSolo.remove("Dresseur");
            if(selectableSolo.isNotEmpty) {
              playersToAssign[assignedIndex].role = selectableSolo.first;
              debugPrint("🎭 LOG [Distribution] : Place insuffisante pour duo. Autre Solo : ${playersToAssign[assignedIndex].name} -> ${selectableSolo.first}");
              assignedIndex++;
              targetHostileCount -= 1;
            }
          }
        } else {
          playersToAssign[assignedIndex].role = selectedSolo;
          debugPrint("🎭 LOG [Distribution] : Tirage Solo : ${playersToAssign[assignedIndex].name} -> $selectedSolo");
          assignedIndex++;
          targetHostileCount -= 1;
        }
      } else {
        targetHostileCount -= manualSoloCount;
        debugPrint("ℹ️ LOG [Distribution] : Solo déjà présent (manuel), ajustement quota.");
      }

      // ÉTAPE 2 : Tirage des LOUPS pour compléter le quota
      int wolvesNeeded = targetHostileCount - manualWolfCount;
      debugPrint("🐺 LOG [Distribution] : Loups supplémentaires requis : $wolvesNeeded");

      while (assignedIndex < playersToAssign.length && wolvesNeeded > 0) {
        if (poolLoups.isNotEmpty) {
          poolLoups.shuffle();
          String selectedWolf = poolLoups.first;
          playersToAssign[assignedIndex].role = selectedWolf;
          debugPrint("🐺 LOG [Distribution] : Tirage Loup : ${playersToAssign[assignedIndex].name} -> $selectedWolf");
          if (selectedWolf != "Loup-garou évolué") poolLoups.remove(selectedWolf);
          assignedIndex++;
          wolvesNeeded--;
        } else {
          playersToAssign[assignedIndex].role = "Loup-garou évolué";
          debugPrint("🐺 LOG [Distribution] : Pool Loups vide. Remplissage : ${playersToAssign[assignedIndex].name} -> Loup-garou évolué");
          assignedIndex++;
          wolvesNeeded--;
        }
      }
    }

    // =========================================================
    // REMPLISSAGE FINAL : VILLAGE
    // =========================================================
    debugPrint("🏡 LOG [Distribution] : Remplissage des rôles villageois restants...");
    while (assignedIndex < playersToAssign.length) {
      if (poolVillage.isNotEmpty) {
        poolVillage.shuffle();
        String selectedVillage = poolVillage.first;
        playersToAssign[assignedIndex].role = selectedVillage;
        debugPrint("🏡 LOG [Distribution] : ${playersToAssign[assignedIndex].name} -> $selectedVillage");
        if (selectedVillage != "Villageois") poolVillage.remove(selectedVillage);
      } else {
        playersToAssign[assignedIndex].role = "Villageois";
        debugPrint("🏡 LOG [Distribution] : ${playersToAssign[assignedIndex].name} -> Villageois (standard)");
      }
      assignedIndex++;
    }

    debugPrint("✅ LOG [Distribution] : Tirage terminé avec succès.");
    debugPrint("--------------------------------------------------");
  }
}