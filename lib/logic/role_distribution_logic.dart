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
    "Dingo": 8,
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

  static const _wolfRoles = [
    "Loup-garou évolué", "Loup-garou chaman", "Somnifère"
  ];
  static const _soloRoles = [
    "Chuchoteur", "Maître du temps", "Pantin", "Phyl",
    "Dresseur", "Ron-Aldo", "Pokémon"
  ];

  /// Tirage pondéré : favorise les rôles peu distribués cette session.
  static String _weightedPick(List<String> pool, Random random) {
    List<double> weights = pool.map((r) =>
      1.0 / (1 + (distributionMemory[r] ?? 0))
    ).toList();

    double totalWeight = weights.reduce((a, b) => a + b);
    double roll = random.nextDouble() * totalWeight;
    double cumul = 0;
    for (int i = 0; i < pool.length; i++) {
      cumul += weights[i];
      if (roll < cumul) return pool[i];
    }
    return pool.last;
  }

  static void distribute(List<Player> players) {
    if (players.length < 3) return;

    final random = Random();
    int totalPlayers = players.length;
    List<String> assignedRoles = [];

    // --- A. Préparation des Pools ---
    List<String> poolSolo = List.from(globalPickBan["solo"] ?? []);
    List<String> poolLoups = List.from(globalPickBan["loups"] ?? []);
    List<String> poolVillage = List.from(globalPickBan["village"] ?? []);

    // Pokémon reste dans poolSolo (paire avec Dresseur)
    // Pas de LG évolué forcé — overflow uniquement
    // Villageois dans le pool uniquement si sélectionné — overflow sinon

    // --- B. Gestion des rôles verrouillés (Locked) ---
    int lockedHostileScore = 0;
    int lockedVillageScore = 0;
    int lockedPlayersCount = 0;
    int lockedHostileCount = 0;

    for (var p in players.where((p) => p.isRoleLocked)) {
      String r = p.role ?? "Villageois";
      assignedRoles.add(r);
      lockedPlayersCount++;

      int score = roleValues[r] ?? 2;

      if (_wolfRoles.contains(r)) {
        lockedHostileScore += score;
        lockedHostileCount++;
        poolLoups.remove(r);
      }
      else if (_soloRoles.contains(r)) {
        lockedHostileScore += score;
        lockedHostileCount++;
        poolSolo.remove(r);
      }
      else {
        lockedVillageScore += score;
        poolVillage.remove(r);
      }
    }

    // --- C. Nombre de slots hostiles (heuristique ~1/3) ---
    int hostileSlots = max(1, (totalPlayers / 3).floor());
    int availableHostileSlots = max(0, hostileSlots - lockedHostileCount);

    // --- Pré-distribution : 5 lancers par batch, garder le plus équilibré ---
    const int rollsPerBatch = 5;
    const int maxBatches = 10;
    List<String> rolesToAdd = [];

    for (int batch = 1; batch <= maxBatches; batch++) {
      // Stocker les résultats des 5 lancers
      List<List<String>> batchResults = [];
      List<double> batchRatios = [];

      for (int roll = 0; roll < rollsPerBatch; roll++) {
        List<String> hostileRoles = [];
        List<String> villageRoles = [];

        // Copies des pools pour ce lancer
        List<String> trialLoups = List.from(poolLoups);
        List<String> trialSolo = List.from(poolSolo);
        List<String> trialVillage = List.from(poolVillage);

        // Gestion paire Dresseur/Pokémon pour les locked
        if (assignedRoles.contains("Dresseur") && !assignedRoles.contains("Pokémon")) {
          hostileRoles.add("Pokémon");
          trialSolo.remove("Pokémon");
        }
        if (assignedRoles.contains("Pokémon") && !assignedRoles.contains("Dresseur")) {
          hostileRoles.add("Dresseur");
          trialSolo.remove("Dresseur");
        }

        // Solo déjà choisi si un solo est locked
        bool soloChosen = assignedRoles.any((r) => _soloRoles.contains(r));

        // --- D. Remplissage hostile (50/50 dès le premier slot) ---
        int slotsToFill = max(0, availableHostileSlots - hostileRoles.length);

        int filled = 0;
        while (filled < slotsToFill) {
          int slotsLeft = slotsToFill - filled;

          if (trialLoups.isEmpty && trialSolo.isEmpty) {
            hostileRoles.add("Loup-garou évolué");
            filled++;
          }
          else if (!soloChosen && trialSolo.isNotEmpty) {
            if (random.nextBool()) {
              // === SOLO ===
              String candidate = _weightedPick(trialSolo, random);

              if (candidate == "Dresseur" || candidate == "Pokémon") {
                bool bothAvailable = trialSolo.contains("Dresseur")
                    && trialSolo.contains("Pokémon");
                if (bothAvailable && slotsLeft >= 2) {
                  hostileRoles.addAll(["Dresseur", "Pokémon"]);
                  trialSolo.remove("Dresseur");
                  trialSolo.remove("Pokémon");
                  filled += 2;
                  soloChosen = true;
                } else {
                  List<String> otherSolos = trialSolo
                      .where((s) => s != "Dresseur" && s != "Pokémon")
                      .toList();
                  if (otherSolos.isNotEmpty) {
                    String picked = _weightedPick(otherSolos, random);
                    hostileRoles.add(picked);
                    trialSolo.remove(picked);
                    filled++;
                    soloChosen = true;
                  } else if (trialLoups.isNotEmpty) {
                    String picked = _weightedPick(trialLoups, random);
                    hostileRoles.add(picked);
                    trialLoups.remove(picked);
                    filled++;
                  } else {
                    hostileRoles.add("Loup-garou évolué");
                    filled++;
                  }
                }
              } else {
                hostileRoles.add(candidate);
                trialSolo.remove(candidate);
                filled++;
                soloChosen = true;
              }
            } else {
              // === LOUP ===
              if (trialLoups.isNotEmpty) {
                String picked = _weightedPick(trialLoups, random);
                hostileRoles.add(picked);
                trialLoups.remove(picked);
                filled++;
              } else {
                hostileRoles.add("Loup-garou évolué");
                filled++;
              }
            }
          }
          else {
            if (trialLoups.isNotEmpty) {
              String picked = _weightedPick(trialLoups, random);
              hostileRoles.add(picked);
              trialLoups.remove(picked);
              filled++;
            } else {
              hostileRoles.add("Loup-garou évolué");
              filled++;
            }
          }
        }

        // --- E. Remplissage village (score matching) ---
        int totalHostileScore = lockedHostileScore;
        for (var r in hostileRoles) {
          totalHostileScore += (roleValues[r] ?? 0);
        }

        int villageSlotsToFill = totalPlayers - lockedPlayersCount - hostileRoles.length;
        int currentVillageScore = lockedVillageScore;

        for (int j = 0; j < villageSlotsToFill; j++) {
          int slotsLeft = villageSlotsToFill - j;
          int scoreDeficit = totalHostileScore - currentVillageScore;
          double neededPerSlot = (slotsLeft > 0) ? (scoreDeficit / slotsLeft) : 2.0;

          String bestRole = "Villageois";
          int minDiff = 999;

          trialVillage.shuffle(random);

          if (trialVillage.isNotEmpty) {
            for (var r in trialVillage) {
              int val = roleValues[r] ?? 2;
              int freqPenalty = distributionMemory[r] ?? 0;
              int diff = (val - neededPerSlot).abs().ceil() + freqPenalty;
              if (diff < minDiff) {
                minDiff = diff;
                bestRole = r;
              }
            }
          }

          villageRoles.add(bestRole);
          currentVillageScore += (roleValues[bestRole] ?? 2);

          if (trialVillage.contains(bestRole)) {
            trialVillage.remove(bestRole);
          }
        }

        // Calculer le ratio de ce lancer
        int totalScore = totalHostileScore + currentVillageScore;
        double ratio = (totalScore > 0)
            ? min(totalHostileScore, currentVillageScore) / totalScore
            : 0.5;

        batchResults.add([...hostileRoles, ...villageRoles]);
        batchRatios.add(ratio);
      }

      // --- F. Sélection du meilleur lancer du batch ---
      int acceptableCount = batchRatios.where((r) => r >= 0.40).length;

      // Trouver le lancer le plus proche de 50%
      int bestIndex = 0;
      double bestDistance = (batchRatios[0] - 0.5).abs();
      for (int i = 1; i < rollsPerBatch; i++) {
        double dist = (batchRatios[i] - 0.5).abs();
        if (dist < bestDistance) {
          bestDistance = dist;
          bestIndex = i;
        }
      }

      // Log chaque lancer du batch
      for (int i = 0; i < rollsPerBatch; i++) {
        String status = batchRatios[i] >= 0.40 ? "✅" : "❌";
        debugPrint("🎲 Batch $batch lancer ${i + 1} : "
            "ratio=${(batchRatios[i] * 100).toStringAsFixed(1)}% $status");
      }

      if (acceptableCount >= 2) {
        rolesToAdd = batchResults[bestIndex];
        debugPrint("⚖️ BALANCE : meilleur lancer=${bestIndex + 1} "
            "ratio=${(batchRatios[bestIndex] * 100).toStringAsFixed(1)}% "
            "($acceptableCount/5 acceptables, batch $batch)");
        break;
      } else {
        debugPrint("⚠️ Batch $batch rejeté ($acceptableCount/5 acceptables, minimum 2 requis)");
        if (batch == maxBatches) {
          rolesToAdd = batchResults[bestIndex];
          debugPrint("⚠️ Max batches atteint, distribution forcée "
              "(meilleur ratio=${(batchRatios[bestIndex] * 100).toStringAsFixed(1)}%)");
        }
      }
    }

    // --- G. Attribution Finale ---
    rolesToAdd.shuffle(random);

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
      if (_wolfRoles.contains(r)) {
        p.team = "loups";
      } else if (["Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Ron-Aldo"].contains(r)) {
        p.team = "solo";
      } else {
        p.team = "village";
      }
    }

    // --- H. Enregistrement mémoire de session ---
    for (var p in players) {
      String role = p.role ?? "";
      if (role.isNotEmpty) {
        distributionMemory[role] = (distributionMemory[role] ?? 0) + 1;
      }
    }
    debugPrint("📝 Mémoire de session : $distributionMemory");

    for (var p in players) {
      debugPrint("🎭 [Result] ${p.name} -> ${p.role} (${p.team})");
    }
  }
}
