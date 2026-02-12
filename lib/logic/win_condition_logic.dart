import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class WinConditionLogic {
  static String? checkWinner(List<Player> players) {
    if (exorcistWin) {
      debugPrint("✝️ LOG [Fin] : L'EXORCISTE A RÉUSSI ! VICTOIRE DU VILLAGE.");
      return "EXORCISTE";
    }

    final alive = players.where((p) => p.isAlive).toList();
    debugPrint("⚔️ CAPTEUR [Victoire] : Joueurs vivants: ${alive.length}/${players.length}. Détail: ${alive.map((p) => '${p.name}(${p.role}/${p.team})').join(', ')}");
    if (alive.isEmpty && players.isNotEmpty) {
      debugPrint("⚔️ CAPTEUR [Victoire] : ÉGALITÉ SANGUINAIRE - tout le monde est mort !");
      return "ÉGALITÉ_SANGUINAIRE";
    }
    if (players.isEmpty) return null;

    try {
      Player phyl = alive.firstWhere((p) => p.role?.toLowerCase() == "phyl");
      if (phyl.isVillageChief && phyl.phylTargets.length >= 2) {
        debugPrint("⚔️ CAPTEUR [Victoire] : Phyl est chef avec ${phyl.phylTargets.length} cibles. Toutes mortes: ${phyl.phylTargets.every((t) => !t.isAlive)}");
        if (phyl.phylTargets.every((t) => !t.isAlive)) return "PHYL";
      }
    } catch (e) {}

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

    if (activeFactions.length > 1) {
      debugPrint("⚔️ LOG [Fin] : Factions restantes : $activeFactions");
      return null;
    }

    final winner = activeFactions.length == 1 ? activeFactions.first : null;
    if (winner != null) debugPrint("🏆 LOG [Fin] : VICTOIRE DE LA FACTION : $winner");

    return winner;
  }
}
