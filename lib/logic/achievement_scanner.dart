import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/achievement.dart';
import '../services/trophy_service.dart';
import '../globals.dart';
import 'achievement_events.dart';

class AchievementScanner {

  static Future<void> checkMidGameAchievements(BuildContext context, List<Player> allPlayers) async {
    await evaluateGenericAchievements(context, allPlayers, winnerRole: null);
  }

  static Future<void> evaluateGenericAchievements(BuildContext context, List<Player> allPlayers, {String? winnerRole}) async {
    debugPrint("🔍 CAPTEUR [Global Scan] : Début analyse. Vainqueur potentiel: $winnerRole");

    for (var p in allPlayers) {
      Map<String, dynamic> stats = buildPlayerStats(p, winnerRole, allPlayers);

      if (p.role?.toLowerCase().contains("archiviste") == true && winnerRole != null) {
        debugPrint("🔍 CAPTEUR [Archiviste] ${p.name} :");
        debugPrint("   > Role Joueur: ${stats['player_role']}");
        debugPrint("   > Team Joueur: '${stats['team']}' (Attendu: 'solo')");
        debugPrint("   > Role Vainqueur: '$winnerRole' (Attendu: 'ARCHIVISTE' ou 'SOLO')");
      }

      if (p.role?.toLowerCase().contains("ron-aldo") == true || p.role?.toLowerCase().contains("maison") == true || p.wasMaisonConverted) {
        if (stats['ramenez_la_coupe'] == true) {
          debugPrint("🔍 CAPTEUR [Coupe Maison] ${p.name} : FLAG ACTIF (Succès devrait tomber)");
        }
      }

      if (winnerRole != null && p.isAlive) {
        bool valid = stats['choix_cornelien_valid'];
        if (!valid) {
          debugPrint("🔍 CAPTEUR [Cornélien] ${p.name} : ÉCHEC. Historique: ${p.votedAgainstHistory}");
        }
      }

      for (var achievement in AchievementData.allAchievements) {
        try {
          if (achievement.checkCondition(stats)) {
            await TrophyService.checkAndUnlockImmediate(
              context: context,
              playerName: p.name,
              achievementId: achievement.id,
              checkData: stats,
            );
          }
        } catch (e) {
          debugPrint("⚠️ LOG [Achievement] : Erreur vérification succès '${achievement.id}' pour ${p.name} - $e");
        }
      }
    }
  }

  static Map<String, dynamic> buildPlayerStats(Player p, String? winnerRole, List<Player> allPlayers) {
    bool hasDuplicateVotes = p.votedAgainstHistory.length != p.votedAgainstHistory.toSet().length;
    int totalVotesCast = p.votedAgainstHistory.length;

    // IMPORTANT : On ne remplit 'roles' que si on est en fin de partie (winnerRole != null)
    // Sinon, les succès de fin ("Héros du Village", "Membre de la Meute", etc.) se déclenchent en mid-game
    Map<String, int> rolesMap = {};
    if (winnerRole != null) {
      rolesMap = {
        'VILLAGE': p.team == "village" ? 1 : 0,
        'LOUPS-GAROUS': p.team == "loups" ? 1 : 0,
        'SOLO': p.team == "solo" ? 1 : 0,
      };
    }

    return {
      'player_role': p.role,
      'is_player_alive': p.isAlive,
      'winner_role': winnerRole,
      'turn_count': globalTurnNumber,
      'is_wolf_faction': p.team == "loups",
      'team': p.team,
      'roles': rolesMap,
      'wolves_alive_count': allPlayers.where((pl) => pl.team == "loups" && pl.isAlive).length,
      'wolves_night_kills': wolvesNightKills,
      'no_friendly_fire_vote': !wolfVotedWolf,
      'evolved_hunger_achieved': evolvedHungerAchieved,
      'chaman_sniper_achieved': chamanSniperAchieved,
      'paradox_achieved': paradoxAchieved,
      'pokemon_died_t1': pokemonDiedTour1,
      'totalVotesReceivedDuringGame': p.totalVotesReceivedDuringGame,
      'vote_anonyme': globalVoteAnonyme,
      'somnifere_uses_left': p.somnifereUses,
      'dingo_shots_fired': p.dingoShotsFired,
      'dingo_shots_hit': p.dingoShotsHit,
      'dingo_self_voted_all_game': p.dingoSelfVotedOnly,
      'parking_shot_achieved': p.parkingShotUnlocked,
      'devin_reveals_count': p.devinRevealsCount,
      'devin_revealed_same_twice': p.hasRevealedSamePlayerTwice,
      'bled_protected_everyone': (p.protectedPlayersHistory.length >= (allPlayers.length - 1)),
      'saved_by_own_quiche': p.hasSavedSelfWithQuiche,
      'quiche_saved_count': quicheSavedThisNight,
      'houstonApollo13Triggered': p.houstonApollo13Triggered,
      'maison_hosted_wolf': false,
      'hosted_enemies_count': p.hostedEnemiesCount,
      'tardos_suicide': p.tardosSuicide,
      'traveler_killed_wolf': p.travelerKilledWolf,
      'was_revived': p.wasRevivedInThisGame,
      'pantinClutchTriggered': p.pantinClutchTriggered,
      'canaclean_present': p.canacleanPresent,
      'is_fan': p.isFanOfRonAldo,
      'ultimate_fan_action': false,
      'is_fan_sacrifice': false,
      'ramenez_la_coupe': p.wasMaisonConverted,
      'house_collapsed': false,
      'is_first_blood': false,
      'choix_cornelien_valid': p.isAlive && !hasDuplicateVotes && totalVotesCast >= 3,
    };
  }

  static Future<void> checkEndGameAchievements(BuildContext context, List<Player> winners, List<Player> allPlayers) async {
    if (winners.isEmpty) return;

    debugPrint("🏁 CAPTEUR [EndGame] : Calcul des succès de fin.");

    String winnerRole = "VILLAGE";
    if (winners.any((p) => p.team == "loups")) {
      winnerRole = "LOUPS-GAROUS";
    } else if (winners.any((p) => p.role?.toLowerCase() == "ron-aldo")) {
      winnerRole = "RON-ALDO";
    } else if (winners.any((p) => p.team == "solo")) {
      if (winners.any((p) => p.role?.toLowerCase() == "dresseur" || p.role?.toLowerCase() == "pokémon")) {
        winnerRole = "DRESSEUR";
      } else if (winners.any((p) => p.role?.toLowerCase() == "maître du temps")) {
        winnerRole = "MAÎTRE DU TEMPS";
      } else if (winners.any((p) => p.role?.toLowerCase() == "phyl")) {
        winnerRole = "PHYL";
      } else if (winners.any((p) => p.role?.toLowerCase() == "archiviste")) {
        winnerRole = "ARCHIVISTE";
      } else {
        winnerRole = winners.first.role?.toUpperCase() ?? "SOLO";
      }
    }

    debugPrint("🏆 CAPTEUR [EndGame] : WinnerRole déduit -> $winnerRole");

    await evaluateGenericAchievements(context, allPlayers, winnerRole: winnerRole);

    for (var p in winners) {
      Map<String, dynamic> winStats = {
        'totalWins': 1,
        'roles': {
          'VILLAGE': p.team == "village" ? 1 : 0,
          'LOUPS-GAROUS': p.team == "loups" ? 1 : 0,
          'SOLO': p.team == "solo" ? 1 : 0,
        },
      };
      await TrophyService.checkAndUnlockImmediate(
        context: context, playerName: p.name,
        achievementId: "first_win", checkData: winStats,
      );
      if (p.team == "village") {
        await TrophyService.checkAndUnlockImmediate(
          context: context, playerName: p.name,
          achievementId: "village_hero", checkData: winStats,
        );
      }
      if (p.team == "loups") {
        await TrophyService.checkAndUnlockImmediate(
          context: context, playerName: p.name,
          achievementId: "wolf_pack", checkData: winStats,
        );
      }
      if (p.team == "solo") {
        await TrophyService.checkAndUnlockImmediate(
          context: context, playerName: p.name,
          achievementId: "lone_wolf", checkData: winStats,
        );
      }
    }

    for (var p in allPlayers) {
      if (p.role?.toLowerCase() == "archiviste") {
        await AchievementEvents.checkArchivisteEndGame(context, p);
      }
      if (p.role?.toLowerCase() == "dresseur" && winnerRole == "DRESSEUR") {
        try {
          var pokemon = allPlayers.firstWhere(
            (pl) => pl.role?.toLowerCase() == "pokémon" || pl.role?.toLowerCase() == "pokemon",
            orElse: () => Player(name: "Unknown", isAlive: true),
          );
          if (pokemon.name != "Unknown" && !pokemon.isAlive) {
            await TrophyService.checkAndUnlockImmediate(
              context: context, playerName: p.name,
              achievementId: "master_no_pokemon",
              checkData: {
                'player_role': "Dresseur",
                'winner_role': "DRESSEUR",
                'pokemon_is_dead_at_end': !pokemon.isAlive,
              },
            );
          }
        } catch (_) {}
      }
    }
  }

}

