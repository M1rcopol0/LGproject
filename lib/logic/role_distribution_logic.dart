import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class RoleDistributionLogic {

  // --- 1. NOTATION DES RÔLES (/20) ---
  static final Map<String, int> roleValues = {
    // 🟢 VILLAGE
    "Villageois": 1,
    "Kung-Fu Panda": 1,
    "Cupidon": 2,
    "Chasseur": 3,
    "Enculateur du bled": 6,
    "Zookeeper": 6,
    "Houston": 6,
    "Devin": 5,
    "Dingo": 5,
    "Tardos": 4,
    "Maison": 5,
    "Archiviste": 6,
    "Grand-mère": 6,
    "Exorciste": 7,
    "Saltimbanque": 7,
    "Voyageur": 8,
    "Voyante": 9,
    "Sorcière": 12,

    // 🔴 LOUPS
    "Loup-garou évolué": 12,
    "Loup-garou chaman": 16,
    "Somnifère": 16,

    // 🟣 SOLO
    "Phyl": 9,
    "Chuchoteur": 11,
    "Maître du temps": 14,
    "Dresseur": 15,
    "Pokémon": 17,
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
  static String _weightedPick(List<String> pool, Random random, Map<String, int> memory) {
    List<double> weights = pool.map((r) =>
      1.0 / (1 + (memory[r] ?? 0))
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

  /// Calcule la fraction village projetée si on ajoute 1 hostile de plus.
  /// Retourne projVillage / projTotal — l'ajout est acceptable si ≥ 0.35
  /// (village conserve au moins 35% du score total).
  static double _projectedRatio({
    required int currentHostileScore,
    required int nextHostileScore,
    required int villageSlotsAfter,
    required double avgVillageScore,
    required int lockedVillageScore,
  }) {
    int projHostile = currentHostileScore + nextHostileScore;
    int projVillage = lockedVillageScore + (villageSlotsAfter * avgVillageScore).round();
    int total = projHostile + projVillage;
    if (total == 0) return 0.5;
    return projVillage / total;
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

    // --- A bis. Clé de configuration + lookup mémoire ---
    List<String> allConfigRoles = [
      ...poolSolo, ...poolLoups, ...poolVillage,
    ]..sort();
    String configKey = "${totalPlayers}_${allConfigRoles.join(',')}";
    Map<String, int> memory = distributionMemory.putIfAbsent(configKey, () => {});

    // --- B. Gestion des rôles verrouillés (Locked) ---
    int lockedHostileScore = 0;
    int lockedVillageScore = 0;
    int lockedPlayersCount = 0;

    for (var p in players.where((p) => p.isRoleLocked)) {
      String r = p.role ?? "Villageois";
      assignedRoles.add(r);
      lockedPlayersCount++;

      int score = roleValues[r] ?? 2;

      if (_wolfRoles.contains(r)) {
        lockedHostileScore += score;
        poolLoups.remove(r);
      }
      else if (_soloRoles.contains(r)) {
        lockedHostileScore += score;
        poolSolo.remove(r);
      }
      else {
        lockedVillageScore += score;
        poolVillage.remove(r);
      }
    }

    // --- C. Slots hostiles déterminés dynamiquement (greedy balance, pas de verrou N/3) ---

    // --- Pré-distribution : 10 lancers par batch, garder le plus équilibré ---
    const int rollsPerBatch = 10;
    const int maxBatches = 10;
    List<String> rolesToAdd = [];

    for (int batch = 1; batch <= maxBatches; batch++) {
      // Stocker les résultats des 5 lancers
      List<List<String>> batchResults = [];
      List<double> batchRatios = [];
      List<int> batchHostileScores = [];
      List<int> batchVillageScores = [];

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

        // --- D. Remplissage hostile — greedy balance (équilibre dynamique par score) ---
        // Précalcul score moyen village pour le lookahead
        double avgVillageScore = trialVillage.isNotEmpty
            ? trialVillage.map((r) => (roleValues[r] ?? 2).toDouble()).reduce((a, b) => a + b) / trialVillage.length
            : 4.0;

        int totalUnlockedSlots = totalPlayers - lockedPlayersCount;

        // Cible aléatoire du nombre total d'hostiles pour ce lancer
        // (variabilité inter-lancers ; la limite de balance reste active)
        int prefilledCount = hostileRoles.length; // pré-remplis (Dresseur/Pokémon locked)
        int maxAdditional = min(
            trialLoups.length + trialSolo.length,
            totalUnlockedSlots - prefilledCount - 1, // -1 pour ≥ 1 slot village
        );
        int minTotal = max(1, prefilledCount);
        int maxTotal = prefilledCount + (maxAdditional > 0 ? maxAdditional : 0);
        int targetHostileCount = minTotal +
            (maxTotal > minTotal ? random.nextInt(maxTotal - minTotal + 1) : 0);

        // Greedy : ajouter hostiles tant que le village garderait ≥ 35% du score total
        while (true) {
          // Stop si la cible aléatoire est atteinte
          if (hostileRoles.length >= targetHostileCount) break;
          if (trialLoups.isEmpty && trialSolo.isEmpty) break;

          int villageSlotsAfter = totalUnlockedSlots - hostileRoles.length - 1;
          if (villageSlotsAfter < 0) break;

          int curHostileScore = lockedHostileScore
              + hostileRoles.fold(0, (s, r) => s + (roleValues[r] ?? 0));

          List<String> candidatePool = [...trialLoups, ...trialSolo];
          int avgNextHostile = (candidatePool
              .map((r) => roleValues[r] ?? 12)
              .reduce((a, b) => a + b) / candidatePool.length).round();

          double proj = _projectedRatio(
            currentHostileScore: curHostileScore,
            nextHostileScore: avgNextHostile,
            villageSlotsAfter: villageSlotsAfter,
            avgVillageScore: avgVillageScore,
            lockedVillageScore: lockedVillageScore,
          );
          if (proj < 0.35) break; // Village serait trop affaibli → stop greedy (seuil 15%)

          // Ajouter 1 hostile (logique 50/50 solo/loup inchangée)
          int slotsLeft = totalUnlockedSlots - hostileRoles.length;

          if (!soloChosen && trialSolo.isNotEmpty) {
            // Poids par camp = somme des poids individuels (memory-weighted)
            double wSolo = trialSolo.fold(0.0, (sum, r) => sum + 1.0 / (1 + (memory[r] ?? 0)));
            double wLoup = trialLoups.isEmpty ? 0.0
                : trialLoups.fold(0.0, (sum, r) => sum + 1.0 / (1 + (memory[r] ?? 0)));
            double totalW = wSolo + wLoup;
            bool pickSolo = totalW > 0 && random.nextDouble() < (wSolo / totalW);

            if (pickSolo) {
              // === SOLO ===
              String candidate = _weightedPick(trialSolo, random, memory);

              if (candidate == "Dresseur" || candidate == "Pokémon") {
                bool bothAvailable = trialSolo.contains("Dresseur")
                    && trialSolo.contains("Pokémon");
                if (bothAvailable && slotsLeft >= 2) {
                  hostileRoles.addAll(["Dresseur", "Pokémon"]);
                  trialSolo.remove("Dresseur");
                  trialSolo.remove("Pokémon");
                  soloChosen = true;
                } else {
                  List<String> otherSolos = trialSolo
                      .where((s) => s != "Dresseur" && s != "Pokémon")
                      .toList();
                  if (otherSolos.isNotEmpty) {
                    String picked = _weightedPick(otherSolos, random, memory);
                    hostileRoles.add(picked);
                    trialSolo.remove(picked);
                    soloChosen = true;
                  } else if (trialLoups.isNotEmpty) {
                    String picked = _weightedPick(trialLoups, random, memory);
                    hostileRoles.add(picked);
                    trialLoups.remove(picked);
                  } else {
                    hostileRoles.add("Loup-garou évolué");
                  }
                }
              } else {
                hostileRoles.add(candidate);
                trialSolo.remove(candidate);
                soloChosen = true;
              }
            } else {
              // === LOUP ===
              if (trialLoups.isNotEmpty) {
                String picked = _weightedPick(trialLoups, random, memory);
                hostileRoles.add(picked);
                trialLoups.remove(picked);
              } else {
                hostileRoles.add("Loup-garou évolué");
              }
            }
          }
          else {
            if (trialLoups.isNotEmpty) {
              String picked = _weightedPick(trialLoups, random, memory);
              hostileRoles.add(picked);
              trialLoups.remove(picked);
            } else {
              hostileRoles.add("Loup-garou évolué");
            }
          }
        }

        // Règle : le Loup-garou chaman ne peut pas être le seul loup de la partie
        int totalWolvesInDist = assignedRoles.where((r) => _wolfRoles.contains(r)).length
            + hostileRoles.where((r) => _wolfRoles.contains(r)).length;
        if (totalWolvesInDist == 1) {
          int idx = hostileRoles.indexOf("Loup-garou chaman");
          if (idx >= 0) {
            List<String> otherLoups = trialLoups.where((r) => r != "Loup-garou chaman").toList();
            String replacement = otherLoups.isNotEmpty
                ? _weightedPick(otherLoups, random, memory)
                : "Loup-garou évolué";
            hostileRoles[idx] = replacement;
            trialLoups.remove(replacement);
          }
        }

        // --- E. Remplissage village (score matching) ---
        int totalHostileScore = lockedHostileScore;
        for (var r in hostileRoles) {
          final int base = roleValues[r] ?? 0;
          final int count = memory[r] ?? 0;
          totalHostileScore += base * (1 + count);
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
            // 1er passage : trouver le diff minimum
            for (var r in trialVillage) {
              int val = roleValues[r] ?? 2;
              int freqPenalty = (memory[r] ?? 0).clamp(0, 3);
              int diff = (val - neededPerSlot).abs().ceil() + freqPenalty;
              if (diff < minDiff) minDiff = diff;
            }
            // 2ème passage : prendre le 1er candidat (ordre aléatoire) dans la bande de tolérance
            const int kTolerance = 2;
            for (var r in trialVillage) {
              int val = roleValues[r] ?? 2;
              int freqPenalty = (memory[r] ?? 0).clamp(0, 3);
              int diff = (val - neededPerSlot).abs().ceil() + freqPenalty;
              if (diff <= minDiff + kTolerance) {
                bestRole = r;
                break;
              }
            }
          }

          villageRoles.add(bestRole);
          final int vBase = roleValues[bestRole] ?? 2;
          final int vCount = memory[bestRole] ?? 0;
          currentVillageScore += vBase * (1 + vCount);

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
        batchHostileScores.add(totalHostileScore);
        batchVillageScores.add(currentVillageScore);
      }

      // --- F. Sélection aléatoire parmi les lancers acceptables (ratio ≥ 0.35) ---
      List<int> acceptableIndices = [];
      for (int i = 0; i < rollsPerBatch; i++) {
        if (batchRatios[i] >= 0.35) acceptableIndices.add(i);
      }

      // Fallback : index du lancer le plus proche de 50%
      int fallbackIndex = 0;
      double bestDistance = (batchRatios[0] - 0.5).abs();
      for (int i = 1; i < rollsPerBatch; i++) {
        double dist = (batchRatios[i] - 0.5).abs();
        if (dist < bestDistance) {
          bestDistance = dist;
          fallbackIndex = i;
        }
      }

      // Log chaque lancer du batch
      for (int i = 0; i < rollsPerBatch; i++) {
        String status = batchRatios[i] >= 0.35 ? "✅" : "❌";
        List<String> roles = batchResults[i];
        int hostileCount = roles.where((r) => _wolfRoles.contains(r) || _soloRoles.contains(r)).length;

        // Rôles groupés par faction et triés alphabétiquement
        List<String> soloInRoll = roles.where((r) => _soloRoles.contains(r)).toList()..sort();
        List<String> loupsInRoll = roles.where((r) => _wolfRoles.contains(r)).toList()..sort();
        List<String> villageInRoll = roles.where((r) => !_wolfRoles.contains(r) && !_soloRoles.contains(r)).toList()..sort();

        String fmt(List<String> lst) =>
            lst.map((r) {
              final int base = roleValues[r] ?? 2;
              final int count = memory[r] ?? 0;
              if (count == 0) return "$r($base)";
              return "$r($base→${base * (1 + count)})";
            }).join(', ');

        debugPrint("🎲 Batch $batch lancer ${i + 1} : "
            "ratio=${(batchRatios[i] * 100).toStringAsFixed(1)}% $status | "
            "$hostileCount hostiles | "
            "hostile=${batchHostileScores[i]} vs village=${batchVillageScores[i]}"
            "\n    solo=[${fmt(soloInRoll)}]"
            "\n    loups=[${fmt(loupsInRoll)}]"
            "\n    village=[${fmt(villageInRoll)}]");
      }

      if (acceptableIndices.length >= 1) {
        int pickedIndex = acceptableIndices[random.nextInt(acceptableIndices.length)];
        rolesToAdd = batchResults[pickedIndex];
        int acceptableCount = acceptableIndices.length;
        debugPrint("🎯 RETENU pour la partie : batch $batch / lancer ${pickedIndex + 1} "
            "— ratio=${(batchRatios[pickedIndex] * 100).toStringAsFixed(1)}% "
            "($acceptableCount/$rollsPerBatch acceptables)");
        break;
      } else {
        debugPrint("⚠️ Batch $batch rejeté (${acceptableIndices.length}/$rollsPerBatch acceptables, minimum 1 requis)");
        if (batch == maxBatches) {
          rolesToAdd = batchResults[fallbackIndex];
          debugPrint("⚠️ Max batches atteint, distribution forcée "
              "(meilleur ratio=${(batchRatios[fallbackIndex] * 100).toStringAsFixed(1)}%)");
        }
      }
    }

    // --- G. Attribution Finale ---
    rolesToAdd.shuffle(random);

    // Garantir au moins 1 loup dans la distribution finale,
    // seulement si l'utilisateur a sélectionné au moins un rôle loup.
    // Si aucun loup n'est dans le pick&ban, la partie solo-only est valide.
    bool userWantsWolves = (globalPickBan["loups"] ?? []).isNotEmpty;
    bool hasWolf = rolesToAdd.any((r) => _wolfRoles.contains(r))
                || assignedRoles.any((r) => _wolfRoles.contains(r));
    if (userWantsWolves && !hasWolf && rolesToAdd.isNotEmpty) {
      int soloIndex = rolesToAdd.indexWhere((r) => _soloRoles.contains(r));
      if (soloIndex >= 0) {
        debugPrint("⚠️ BALANCE [Fix] : Pas de loup → remplacement solo par Loup-garou évolué");
        rolesToAdd[soloIndex] = "Loup-garou évolué";
      } else {
        rolesToAdd[0] = "Loup-garou évolué";
      }
    }

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
      } else if (["Chuchoteur", "Maître du temps", "Pantin", "Phyl", "Dresseur", "Ron-Aldo", "Pokémon"].contains(r)) {
        p.team = "solo";
      } else {
        p.team = "village";
      }
    }

    // --- H. Enregistrement mémoire de session ---
    for (var p in players) {
      String role = p.role ?? "";
      if (role.isNotEmpty) {
        memory[role] = (memory[role] ?? 0) + 1;
      }
    }
    debugPrint("📝 Mémoire [$configKey] : $memory");

    for (var p in players) {
      debugPrint("🎭 [Result] ${p.name} -> ${p.role} (${p.team})");
    }
  }

  /// Affiche dans les logs l'état complet de la mémoire de distribution :
  /// pour chaque config active, montre combien de fois chaque rôle a été tiré,
  /// son poids actuel et son pourcentage de débuff.
  static void logMemoryState() {
    if (distributionMemory.isEmpty) {
      debugPrint("📊 [Mémoire Distribution] : Aucun tirage dans cette session.");
      return;
    }

    for (var configEntry in distributionMemory.entries) {
      final String configKey = configEntry.key;
      final Map<String, int> mem = configEntry.value;
      if (mem.isEmpty) continue;

      final int totalDraws = mem.values.fold(0, (a, b) => a + b);
      debugPrint("📊 [Mémoire Distribution] Config: $configKey | Total tirages: $totalDraws");

      // Rôles triés par nombre de tirages décroissant
      final sorted = mem.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      for (var entry in sorted) {
        final String role = entry.key;
        final int count = entry.value;
        final double weight = 1.0 / (1 + count);
        final int debuffPct = ((1.0 - weight) * 100).round();
        final double sharePct = totalDraws > 0 ? (count / totalDraws) * 100 : 0.0;
        debugPrint("  • $role : $count tirage(s) [${sharePct.toStringAsFixed(0)}% du pool] "
            "→ poids=${weight.toStringAsFixed(3)} | débuff=-$debuffPct%");
      }
    }
  }
}
