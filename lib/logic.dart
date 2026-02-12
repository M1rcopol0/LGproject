import 'package:flutter/material.dart';
import 'models/player.dart';
import 'logic/team_logic.dart';
import 'logic/turn_logic.dart';
import 'logic/vote_logic.dart';
import 'logic/elimination_logic.dart';
import 'logic/game_setup_logic.dart';
import 'logic/win_condition_logic.dart';

// Re-export des sous-modules pour les imports directs
export 'logic/team_logic.dart';
export 'logic/turn_logic.dart';
export 'logic/vote_logic.dart';
export 'logic/elimination_logic.dart';
export 'logic/game_setup_logic.dart';
export 'logic/win_condition_logic.dart';

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
