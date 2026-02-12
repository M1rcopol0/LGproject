import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';
import '../achievement_logic.dart';

class VoteLogic {
  static void validateVoteStats(BuildContext context, List<Player> allPlayers) {
    debugPrint("📊 LOG [GameLogic] : Analyse statistique des votes...");

    for (var p in allPlayers.where((p) => p.isAlive)) {
      if (p.role?.toLowerCase() == "dingo") {
        if (p.targetVote == null || p.targetVote!.name != p.name) {
          debugPrint("❌ LOG [Dingo] : ${p.name} a voté pour ${p.targetVote?.name ?? 'Personne'}. Série 'Self Vote' brisée.");
          p.dingoSelfVotedOnly = false;
        } else {
          debugPrint("🤪 LOG [Dingo] : ${p.name} vote pour lui-même. Série OK.");
        }
      }

      if (p.isFanOfRonAldo && p.targetVote != null) {
        if (p.targetVote!.role?.toLowerCase() == "ron-aldo") {
          p.hasBetrayedRonAldo = true;
          AchievementLogic.checkTraitorFan(context, p, p.targetVote!);
          debugPrint("🐍 LOG [Trahison] : Le fan ${p.name} a voté contre Ron-Aldo !");
        }
      }

      if (p.votes > 0) {
        p.totalVotesReceivedDuringGame += p.votes;
      }
    }
  }

  static void processVillageVote(BuildContext context, List<Player> allPlayers) {
    debugPrint("🗳️ LOG [Vote] : Calcul du résultat du vote.");

    hasVotedThisTurn = true;

    for (var p in allPlayers) {
      p.votes = 0;
    }

    Player? ronAldo;
    int fanCount = 0;

    try {
      ronAldo = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "ron-aldo" && p.isAlive);
      fanCount = allPlayers.where((p) => p.isFanOfRonAldo && p.isAlive).length;
      debugPrint("⚽ LOG [Ron-Aldo] : Fans actifs détectés : $fanCount");
    } catch (_) {
      debugPrint("⚽ LOG [Ron-Aldo] : Pas de Ron-Aldo vivant.");
    }

    for (var voter in allPlayers.where((p) => p.isAlive && !p.isAwayAsMJ)) {
      if (voter.isVoteCancelled) {
        debugPrint("🚫 LOG [Vote] : Le vote de ${voter.name} a été annulé par l'Archiviste.");
        continue;
      }

      if (ronAldo != null && voter.isFanOfRonAldo) {
        continue;
      }

      if (voter.targetVote != null) {
        int weight = 1;

        if (voter.role?.toLowerCase() == "pantin") {
          weight = 2;
        }

        if (voter.role?.toLowerCase() == "ron-aldo") {
          weight += fanCount;
          debugPrint("⚽ LOG [Ron-Aldo] : Vote avec un poids de $weight (dont $fanCount fans).");
        }

        try {
          var target = allPlayers.firstWhere((p) => p.name == voter.targetVote!.name);
          target.votes += weight;
          debugPrint("🗳️ LOG [Vote] : ${voter.name} (+${weight}) -> ${target.name} (Total: ${target.votes})");
        } catch (e) {
          debugPrint("⚠️ Vote ignoré : Cible introuvable.");
        }
      }
    }

    validateVoteStats(context, allPlayers);

    List<Player> votablePlayers =
    allPlayers.where((p) => p.isAlive && !p.isImmunizedFromVote && !p.isAwayAsMJ).toList();

    if (votablePlayers.isEmpty) {
      debugPrint("🕊️ LOG [Vote] : Personne n'est éliminable aujourd'hui.");
      return;
    }

    votablePlayers.sort((a, b) {
      int voteComp = b.votes.compareTo(a.votes);
      if (voteComp != 0) return voteComp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    Player first = votablePlayers[0];
    debugPrint("💀 LOG [Vote] : Cible désignée -> ${first.name} avec ${first.votes} voix.");

    for (var p in allPlayers.where((p) => p.isAlive && p.role?.toLowerCase() == "dingo")) {
      if (p.targetVote == first) {
        AchievementLogic.checkParkingShot(context, p, first, allPlayers);
      }
    }
  }
}
