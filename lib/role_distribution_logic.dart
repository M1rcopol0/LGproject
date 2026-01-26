import 'dart:math';
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
    if (players.length < 3) return;

    List<Player> playersToAssign = players.where((p) => !p.isRoleLocked).toList();
    if (playersToAssign.isEmpty) return;

    // Préparation des pools
    List<String> poolSolo = List.from(globalPickBan["solo"] ?? []);
    List<String> poolLoups = List.from(globalPickBan["loups"] ?? []);
    List<String> poolVillage = List.from(globalPickBan["village"] ?? []);

    int manualSoloCount = 0;
    int manualWolfCount = 0;

    for (var p in players.where((p) => p.isRoleLocked)) {
      String r = p.role ?? "";
      if (_soloRoles.contains(r)) { manualSoloCount++; poolSolo.remove(r); }
      else if (_wolfRoles.contains(r)) { manualWolfCount++; if (r != "Loup-garou évolué") poolLoups.remove(r); }
      if (r != "Villageois") poolVillage.remove(r);
    }

    int totalPlayers = players.length;
    int assignedIndex = 0;
    playersToAssign.shuffle();

    // =========================================================
    // CAS A : 4 À 6 JOUEURS (MAX 1 HOSTILE)
    // =========================================================
    if (totalPlayers >= 4 && totalPlayers <= 6) {
      if (manualSoloCount + manualWolfCount == 0) {
        // Interdire le duo Dresseur/Pokémon à moins de 7 joueurs car ils prennent 2 slots
        List<String> possibleHostiles = [
          ...poolSolo.where((r) => r != "Dresseur" && r != "Pokémon"),
          ...poolLoups.where((r) => r != "Loup-garou chaman")
        ];

        if (possibleHostiles.isNotEmpty) {
          playersToAssign[assignedIndex].role = possibleHostiles[Random().nextInt(possibleHostiles.length)];
          assignedIndex++;
        }
      }
    }
    // =========================================================
    // CAS B : 7 JOUEURS ET PLUS
    // =========================================================
    else if (totalPlayers >= 7) {
      int targetHostileCount = (totalPlayers * 0.35).round();

      // ÉTAPE 1 : Tirage du rôle SOLO (obligatoire si aucun manuel)
      if (manualSoloCount == 0 && assignedIndex < playersToAssign.length && poolSolo.isNotEmpty) {
        // --- CORRECTIF : On retire "Pokémon" du tirage aléatoire, il viendra avec le Dresseur ---
        List<String> selectableSolo = poolSolo.where((r) => r != "Pokémon").toList();
        selectableSolo.shuffle();

        String selectedSolo = selectableSolo.first;

        if (selectedSolo == "Dresseur") {
          // On vérifie si on a assez de place pour le duo ET si on n'explose pas trop le quota
          if ((playersToAssign.length - assignedIndex) >= 2) {
            playersToAssign[assignedIndex].role = "Dresseur";
            playersToAssign[assignedIndex + 1].role = "Pokémon";
            assignedIndex += 2;
            targetHostileCount -= 2; // Le duo compte pour 2 hostiles
          } else {
            // Pas assez de place pour le duo, on prend un autre solo si possible
            selectableSolo.remove("Dresseur");
            if(selectableSolo.isNotEmpty) {
              playersToAssign[assignedIndex].role = selectableSolo.first;
              assignedIndex++;
              targetHostileCount -= 1;
            }
          }
        } else {
          playersToAssign[assignedIndex].role = selectedSolo;
          assignedIndex++;
          targetHostileCount -= 1;
        }
      } else {
        targetHostileCount -= manualSoloCount;
      }

      // ÉTAPE 2 : Tirage des LOUPS restants pour compléter le quota
      int wolvesNeeded = targetHostileCount - manualWolfCount;

      while (assignedIndex < playersToAssign.length && wolvesNeeded > 0) {
        if (poolLoups.isNotEmpty) {
          poolLoups.shuffle();
          String selectedWolf = poolLoups.first;
          playersToAssign[assignedIndex].role = selectedWolf;
          if (selectedWolf != "Loup-garou évolué") poolLoups.remove(selectedWolf);
          assignedIndex++;
          wolvesNeeded--;
        } else {
          playersToAssign[assignedIndex].role = "Loup-garou évolué";
          assignedIndex++;
          wolvesNeeded--;
        }
      }
    }

    // =========================================================
    // REMPLISSAGE FINAL : VILLAGE
    // =========================================================
    while (assignedIndex < playersToAssign.length) {
      if (poolVillage.isNotEmpty) {
        poolVillage.shuffle();
        String selectedVillage = poolVillage.first;
        playersToAssign[assignedIndex].role = selectedVillage;
        if (selectedVillage != "Villageois") poolVillage.remove(selectedVillage);
      } else {
        playersToAssign[assignedIndex].role = "Villageois";
      }
      assignedIndex++;
    }
  }
}