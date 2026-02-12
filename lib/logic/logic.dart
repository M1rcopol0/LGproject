import 'package:flutter/material.dart';
import '../models/player.dart';
import 'team_logic.dart';
import 'turn_logic.dart';
import 'vote_logic.dart';
import 'elimination_logic.dart';
import 'game_setup_logic.dart';
import 'win_condition_logic.dart';

// Re-export des sous-modules pour les imports directs
export 'team_logic.dart';
export 'turn_logic.dart';
export 'vote_logic.dart';
export 'elimination_logic.dart';
export 'game_setup_logic.dart';
export 'win_condition_logic.dart';

class GameLogic {
  static String getTeamForRole(String role) => TeamLogic.getTeamForRole(role);

  static void nextTurn(List<Player> allPlayers) => TurnLogic.nextTurn(allPlayers);

  static void validateVoteStats(BuildContext context, List<Player> allPlayers) =>
      VoteLogic.validateVoteStats(context, allPlayers);

  static void processVillageVote(BuildContext context, List<Player> allPlayers) =>
      VoteLogic.processVillageVote(context, allPlayers);

  static Player eliminatePlayer(BuildContext context, List<Player> allPlayers, Player target,
      {bool isVote = false, String reason = ""}) =>
      EliminationLogic.eliminatePlayer(context, allPlayers, target, isVote: isVote, reason: reason);

  static void assignRoles(List<Player> players) => GameSetupLogic.assignRoles(players);

  static String? checkWinner(List<Player> players) => WinConditionLogic.checkWinner(players);
}
