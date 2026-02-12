import 'package:flutter/material.dart';
import '../models/player.dart';
import 'team_logic.dart';
import 'turn_logic.dart';
import 'vote_logic.dart';
import 'elimination_logic.dart';
import 'game_setup_logic.dart';
import 'win_condition_logic.dart';

// Re-export des sous-modules pour faciliter les imports directs dans le reste de l'app
export 'team_logic.dart';
export 'turn_logic.dart';
export 'vote_logic.dart';
export 'elimination_logic.dart';
export 'game_setup_logic.dart';
export 'win_condition_logic.dart';

class GameLogic {
  /// Détermine l'équipe (camp) d'un rôle donné
  static String getTeamForRole(String role) => TeamLogic.getTeamForRole(role);

  /// Gère le passage au tour suivant et le nettoyage des états temporaires
  static void nextTurn(List<Player> allPlayers) => TurnLogic.nextTurn(allPlayers);

  /// Vérifie l'intégrité des statistiques de vote pour les succès
  static void validateVoteStats(BuildContext context, List<Player> allPlayers) =>
      VoteLogic.validateVoteStats(context, allPlayers);

  /// Calcule les résultats du vote du village
  static void processVillageVote(BuildContext context, List<Player> allPlayers) =>
      VoteLogic.processVillageVote(context, allPlayers);

  /// Tue un joueur et gère toutes les réactions en chaîne (Amants, Chasseur, etc.)
  /// Retourne désormais une LISTE de joueurs décédés suite à cette action.
  static List<Player> eliminatePlayer(BuildContext context, List<Player> allPlayers, Player target,
      {bool isVote = false, String reason = ""}) {
    return EliminationLogic.eliminatePlayer(
        context,
        allPlayers,
        target,
        isVote: isVote,
        reason: reason
    );
  }

  /// Distribue les rôles aléatoirement en début de partie
  static void assignRoles(List<Player> players) => GameSetupLogic.assignRoles(players);

  /// Vérifie si une condition de victoire est remplie
  /// Utilise checkWinner qui prend la liste des joueurs en paramètre
  static String? checkWinner(List<Player> players) => WinConditionLogic.checkWinner(players);
}