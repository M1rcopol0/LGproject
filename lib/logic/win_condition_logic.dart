import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class WinConditionLogic {

  /// Alias pour la compatibilité avec certains appels du MJResultScreen
  static String? checkWinCondition() {
    return checkWinner(globalPlayers);
  }

  /// Logique principale de détection de victoire
  static String? checkWinner(List<Player> players) {
    if (exorcistWin) {
      debugPrint("✝️ LOG [Fin] : L'EXORCISTE A RÉUSSI ! VICTOIRE DU VILLAGE.");
      return "EXORCISTE";
    }

    final alive = players.where((p) => p.isAlive && !p.isAwayAsMJ).toList();

    debugPrint("⚔️ CAPTEUR [Victoire] : Joueurs vivants: ${alive.length}/${players.length}. Détail: ${alive.map((p) => '${p.name}(${p.role}/${p.team})').join(', ')}");

    if (alive.isEmpty && players.isNotEmpty) {
      debugPrint("⚔️ CAPTEUR [Victoire] : ÉGALITÉ SANGUINAIRE - tout le monde est mort !");
      return "ÉGALITÉ_SANGUINAIRE";
    }

    if (players.isEmpty) return null;

    // --- CONDITION DE VICTOIRE : PHYL ---
    // Phyl gagne s'il est chef du village (Maire/Roi/Dictateur selon le mode) ET que ses cibles sont toutes mortes
    try {
      Player phyl = alive.firstWhere((p) => p.role?.toLowerCase() == "phyl");
      if (phyl.isVillageChief && phyl.phylTargets.length >= 2) {
        bool allTargetsDead = phyl.phylTargets.every((t) => !t.isAlive);
        debugPrint("⚔️ CAPTEUR [Victoire] : Phyl est chef avec ${phyl.phylTargets.length} cibles. Toutes mortes: $allTargetsDead");
        if (allTargetsDead) return "PHYL";
      }
    } catch (e) {
      // Phyl n'est pas dans la partie ou n'est plus vivant
    }

    // --- CONDITION DE VICTOIRE : AMOUREUX ---
    final lovers = alive.where((p) => p.isLinkedByCupidon).toList();
    if (lovers.length == 2) {
      final nonLoverNonCupidon = alive.where(
        (p) => !p.isLinkedByCupidon && p.role?.toLowerCase() != "cupidon"
      ).toList();
      if (nonLoverNonCupidon.isEmpty) {
        debugPrint("💕 LOG [Fin] : VICTOIRE DES AMOUREUX !");
        return "AMOUREUX";
      }
    }

    // --- DÉTERMINATION DES FACTIONS ENCORE EN LICE ---
    // Les fans de Ron-Aldo restent dans sa faction même si Ron-Aldo est mort
    Set<String> activeFactions = {};
    for (var p in alive) {
      if (p.team == "village") {
        activeFactions.add(p.isFanOfRonAldo ? "RON-ALDO" : "VILLAGE");
      } else if (p.team == "loups") {
        activeFactions.add("LOUPS-GAROUS");
      } else if (p.team == "solo") {
        String role = p.role?.toLowerCase() ?? "";
        if (role == "ron-aldo" || p.isFanOfRonAldo) {
          activeFactions.add("RON-ALDO");
        } else if (role == "dresseur" || role == "pokémon") {
          activeFactions.add("DRESSEUR");
        } else if (role == "archiviste") {
          activeFactions.add("ARCHIVISTE");
        } else {
          activeFactions.add(role.toUpperCase());
        }
      }
    }

    // Si plus d'une faction est vivante, le jeu continue
    if (activeFactions.length > 1) {
      debugPrint("⚔️ LOG [Fin] : Factions restantes : $activeFactions");
      return null;
    }

    // Si une seule faction reste, elle a gagné
    final winner = activeFactions.length == 1 ? activeFactions.first : null;
    if (winner != null) {
      debugPrint("🏆 LOG [Fin] : VICTOIRE DE LA FACTION : $winner");
    }

    return winner;
  }
}