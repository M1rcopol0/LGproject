import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class RoleDistributionLogic {

  // --- 1. NOTATION DES RÔLES (/20) ---
  static final Map<String, int> roleValues = {
    // 🟢 VILLAGE
    "Villageois": 2,
    "Kung-Fu Panda": 2,
    "Cupidon": 4,
    "Chasseur": 6,
    "Enculateur du bled": 7,
    "Zookeeper": 7,
    "Houston": 7,
    "Devin": 8,
    "Tardos": 8,
    "Maison": 8,
    "Archiviste": 9,
    "Grand-mère": 9,
    "Exorciste": 10,
    "Saltimbanque": 10,
    "Voyageur": 10,
    "Voyante": 11,
    "Sorcière": 14,

    // 🔴 LOUPS
    "Loup-garou évolué": 12,
    "Loup-garou chaman": 16,
    "Somnifère": 16,

    // 🟣 SOLO
    "Phyl": 9,
    "Chuchoteur": 11,
    "Maître du temps": 14,
    "Dresseur": 16,
    "Ron-Aldo": 18,
    "Pantin": 18,
  };

  static void distribute(List<Player> players) {
    if (players.length < 3) return;

    final random = Random();
    int totalPlayers = players.length;
    List<String> assignedRoles = [];

    // --- A. Préparation des Pools ---
    List<String> poolSolo = List.from(globalPickBan["solo"] ?? []);
    List<String> poolLoups = List.from(globalPickBan["loups"] ?? []);
    List<String> poolVillage = List.from(globalPickBan["village"] ?? []);

    // Nettoyage
    poolSolo.remove("Pokémon");

    // Sécurités Overflow
    // On force un Loup de base si aucun loup n'est sélectionné
    if (!poolLoups.contains("Loup-garou évolué")) poolLoups.add("Loup-garou évolué");

    // CORRECTION : On NE force PAS l'ajout du Villageois ici.
    // Il sera utilisé uniquement comme valeur par défaut ("bestRole = 'Villageois'")
    // si le poolVillage est vide ou s'épuise.

    // --- B. Gestion des rôles verrouillés (Locked) ---
    int lockedHostileScore = 0;
    int lockedVillageScore = 0;
    int lockedPlayersCount = 0;
    bool dresseurLocked = false;

    for (var p in players.where((p) => p.isRoleLocked)) {
      String r = p.role ?? "Villageois";
      assignedRoles.add(r);
      lockedPlayersCount++;

      int score = roleValues[r] ?? 2;

      if (["Loup-garou évolué", "Loup-garou chaman", "Somnifère"].contains(r)) {
        lockedHostileScore += score;
        if (r != "Loup-garou évolué") poolLoups.remove(r);
      }
      else if (["Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Ron-Aldo"].contains(r)) {
        lockedHostileScore += score;
        poolSolo.remove(r);
        if (r == "Dresseur") dresseurLocked = true;
      }
      else {
        if (r != "Pokémon") lockedVillageScore += score;
        if (r != "Villageois") poolVillage.remove(r);
      }
    }

    // --- C. Détermination des quotas Hostiles ---
    // Environ 1/3 de joueurs hostiles
    int targetHostileSlots = max(1, (totalPlayers / 3).floor());

    List<String> rolesToAdd = [];

    // --- ÉTAPE 1 : Loup garanti (au moins 1 dans chaque partie) ---
    {
      String wolf = "Loup-garou évolué";
      if (poolLoups.isNotEmpty) {
        poolLoups.shuffle();
        wolf = poolLoups.first;
        if (wolf != "Loup-garou évolué") poolLoups.remove(wolf);
      }
      rolesToAdd.add(wolf);
      targetHostileSlots--;
    }

    // --- ÉTAPE 2 : Slots restants (50/50 Solo/Loup) ---
    String? selectedSolo;
    bool hasDresseur = dresseurLocked;

    while (targetHostileSlots > 0) {
      bool canPickSolo = (selectedSolo == null)
          && poolSolo.isNotEmpty
          && (lockedHostileScore == 0);

      if (canPickSolo && random.nextBool()) {
        String candidate = poolSolo[random.nextInt(poolSolo.length)];
        int slotsNeeded = (candidate == "Dresseur") ? 2 : 1;

        if (slotsNeeded <= targetHostileSlots) {
          selectedSolo = candidate;
          rolesToAdd.add(selectedSolo);
          targetHostileSlots--;

          if (candidate == "Dresseur") {
            hasDresseur = true;
            if (!assignedRoles.contains("Pokémon")) {
              rolesToAdd.add("Pokémon");
            }
            targetHostileSlots = max(0, targetHostileSlots - 1);
          }
          continue;
        }
      }

      // Sinon : Loup
      String wolf = "Loup-garou évolué";
      if (poolLoups.isNotEmpty) {
        poolLoups.shuffle();
        wolf = poolLoups.first;
        if (wolf != "Loup-garou évolué") poolLoups.remove(wolf);
      }
      rolesToAdd.add(wolf);
      targetHostileSlots--;
    }

    // --- D. Calcul du Score Hostile Total ---
    int totalHostileScore = lockedHostileScore;
    for (var r in rolesToAdd) {
      // On additionne les scores des rôles hostiles générés (hors Villageois/Pokémon)
      if (!poolVillage.contains(r) && r != "Pokémon" && r != "Villageois") {
        totalHostileScore += (roleValues[r] ?? 0);
      }
    }

    debugPrint("⚖️ BALANCE : Score Hostile Cible = $totalHostileScore");

    // --- ÉTAPE 3 : Remplissage du Village (Équilibrage) ---
    int villageSlotsToFill = totalPlayers - (lockedPlayersCount + rolesToAdd.length);
    int currentVillageScore = lockedVillageScore;

    for (int i = 0; i < villageSlotsToFill; i++) {
      int slotsLeft = villageSlotsToFill - i;
      int scoreDeficit = totalHostileScore - currentVillageScore;
      double neededPerSlot = (slotsLeft > 0) ? (scoreDeficit / slotsLeft) : 2.0;

      // Par défaut, le fallback est "Villageois" (Overflow)
      String bestRole = "Villageois";
      int minDiff = 999;

      poolVillage.shuffle();

      // Si le pool contient des rôles, on cherche le meilleur match
      if (poolVillage.isNotEmpty) {
        for (var r in poolVillage) {
          int val = roleValues[r] ?? 2;
          int diff = (val - neededPerSlot).abs().ceil();

          if (diff < minDiff) {
            minDiff = diff;
            bestRole = r;
          }
        }
      }
      // SINON : poolVillage est vide, bestRole reste "Villageois".
      // C'est ici que l'overflow s'active uniquement si nécessaire.

      rolesToAdd.add(bestRole);
      currentVillageScore += (roleValues[bestRole] ?? 2);

      // On retire le rôle choisi s'il est unique
      if (bestRole != "Villageois" && bestRole != "Kung-Fu Panda") {
        poolVillage.remove(bestRole);
      }
    }

    debugPrint("⚖️ BALANCE : Score Village Final = $currentVillageScore vs Hostile $totalHostileScore");

    // --- E. Attribution Finale ---
    rolesToAdd.shuffle();

    int addIndex = 0;
    for (var p in players) {
      if (!p.isRoleLocked) {
        p.resetFullState();

        if (addIndex < rolesToAdd.length) {
          p.role = rolesToAdd[addIndex];
          addIndex++;
        } else {
          p.role = "Villageois";
        }
      }

      // Assignation de l'équipe
      String r = p.role ?? "";
      if (["Loup-garou évolué", "Loup-garou chaman", "Somnifère"].contains(r)) {
        p.team = "loups";
      } else if (["Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Ron-Aldo"].contains(r)) {
        p.team = "solo";
      } else {
        p.team = "village";
      }
    }

    for (var p in players) {
      debugPrint("🎭 [Result] ${p.name} -> ${p.role} (${p.team})");
    }
  }
}