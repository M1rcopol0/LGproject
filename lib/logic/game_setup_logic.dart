import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';
import '../achievement_logic.dart';
import '../role_distribution_logic.dart';
import 'team_logic.dart';

class GameSetupLogic {
  static void assignRoles(List<Player> players) {
    debugPrint("--------------------------------------------------");
    debugPrint("🎭 LOG [Setup] : Distribution des rôles en cours...");
    RoleDistributionLogic.distribute(players);
    _finalizeTeams(players);
    debugPrint("--------------------------------------------------");
  }

  static void _finalizeTeams(List<Player> players) {
    for (var p in players) {
      _initializePlayerState(p);
      p.team = TeamLogic.getTeamForRole(p.role ?? "");
      debugPrint("👤 LOG [Setup] : ${p.name} -> ${p.role} (${p.team})");
    }
  }

  static void _initializePlayerState(Player p) {
    debugPrint("🎭 CAPTEUR [Action] : Init état pour ${p.name} (${p.role}). somnifère: ${(p.role?.toLowerCase() == "somnifère") ? 2 : 0}, archiviste: ${(p.role?.toLowerCase() == "archiviste") ? 2 : 0} charges.");
    p.isAlive = true;
    p.votes = 0;
    p.pantinCurseTimer = null;
    p.pantinClutchTriggered = false;
    p.roleChangesCount = 0;
    p.killsThisGame = 0;
    p.mutedPlayersCount = 0;
    p.hasHeardWolfSecrets = false;
    p.wasRevivedInThisGame = false;
    p.hasUsedRevive = false;
    p.hasBetrayedRonAldo = false;
    p.travelerBullets = 0;
    p.somnifereUses = (p.role?.toLowerCase() == "somnifère") ? 2 : 0;
    p.bombTimer = 0;
    p.hasPlacedBomb = false;
    p.dingoStrikeCount = 0;
    p.dingoShotsFired = 0;
    p.dingoShotsHit = 0;
    p.dingoSelfVotedOnly = true;
    p.phylTargets = [];
    p.isFanOfRonAldo = false;
    p.isVillageChief = false;
    p.hasBeenHitByDart = false;
    p.zookeeperEffectReady = false;
    p.isEffectivelyAsleep = false;
    p.powerActiveThisTurn = false;
    p.lastDresseurAction = null;
    p.pokemonRevengeTarget = null;
    p.hasBakedQuiche = false;
    p.isVillageProtected = false;
    p.archivisteActionsUsed = [];

    p.archivisteScapegoatCharges = (p.role?.toLowerCase() == "archiviste") ? 2 : 0;
    p.hasScapegoatPower = false;

    p.canacleanPresent = false;
    p.isHouseDestroyed = false;
    p.hasSurvivedVote = false;
    p.isAwayAsMJ = false;

    if (globalTurnNumber == 1) {
      AchievementLogic.resetFullGameData();
    }
  }
}
