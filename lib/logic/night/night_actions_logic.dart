import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';

// Imports des modules de nuit
import 'night_preparation.dart';
import 'night_explosion.dart';
import 'night_info_generator.dart';
import 'night_death_resolver.dart';
import 'night_cleanup.dart';

class NightResult {
  final List<Player> deadPlayers;
  final Map<String, String> deathReasons;
  final bool villageWasProtected;
  final List<String> announcements;
  final bool villageIsNarcoleptic;
  final bool exorcistVictory;
  final List<String> revealedPlayerNames;

  NightResult({
    required this.deadPlayers,
    required this.deathReasons,
    required this.villageWasProtected,
    this.announcements = const [],
    this.villageIsNarcoleptic = false,
    this.exorcistVictory = false,
    this.revealedPlayerNames = const [],
  });
}

class NightActionsLogic {

  static void prepareNightStates(List<Player> players) {
    NightPreparation.run(players);
  }

  static NightResult resolveNight(
      BuildContext context,
      List<Player> players,
      Map<Player, String> pendingDeathsMap,
      {bool somnifereActive = false,
        bool exorcistSuccess = false}) {

    debugPrint("🏁 LOG [Logic] : Début de la résolution finale.");
    Map<String, String> finalDeathReasons = {};
    List<String> playersToReveal = [];

    // --- VICTOIRE EXORCISTE ---
    if (exorcistSuccess) {
      debugPrint("🏆 LOG [Exorciste] : VICTOIRE IMMÉDIATE DÉTECTÉE.");
      return NightResult(
        deadPlayers: [],
        deathReasons: {},
        villageWasProtected: false,
        exorcistVictory: true,
      );
    }

    // --- ROLES SPECIAUX (Time Master, Maison) ---
    NightInfoGenerator.processSpecialRoles(context, players, pendingDeathsMap);

    // --- ANNONCES (Voyageur, Houston, Devin) ---
    List<String> morningAnnouncements = NightInfoGenerator.generateAnnouncements(context, players, playersToReveal, pendingDeathsMap);

    // --- SOMNIFERE ---
    if (somnifereActive) {
      for (var p in players) p.isEffectivelyAsleep = true;
      morningAnnouncements.add("💤 Le village se réveille engourdi... Le Somnifère a frappé !");
      debugPrint("💤 LOG [Somnifère] : Activé (Mode annonce uniquement).");
    }

    // --- EXPLOSIONS ---
    for (var p in players) {
      if (p.hasPlacedBomb && p.bombTimer == 0 && p.tardosTarget != null) {
        NightExplosion.handle(
            context: context, allPlayers: players, target: p.tardosTarget!,
            pendingDeathsMap: pendingDeathsMap, reason: "Explosion Bombe (Tardos)",
            attacker: p, announcements: morningAnnouncements);
        p.tardosTarget = null;
      }
    }
    for (var p in players) {
      bool targetedByTardos = players.any((attacker) => attacker.role?.toLowerCase() == "tardos" && attacker.hasPlacedBomb && attacker.tardosTarget == p);
      if (p.isBombed && p.attachedBombTimer == 0 && !targetedByTardos) {
        NightExplosion.handle(
            context: context, allPlayers: players, target: p,
            pendingDeathsMap: pendingDeathsMap, reason: "Explosion Bombe (Manuelle)",
            attacker: null, announcements: morningAnnouncements);
      }
    }

    // --- QUICHE ---
    bool quicheIsActive = false;
    if (globalTurnNumber > 1) {
      quicheIsActive = players.any((p) => p.role?.toLowerCase() == "grand-mère" && p.isAlive && p.isVillageProtected && !p.isEffectivelyAsleep);
    }

    // --- RESOLUTION DES MORTS ---
    NightDeathResolver.resolve(
      context: context,
      players: players,
      pendingDeathsMap: pendingDeathsMap,
      finalDeathReasons: finalDeathReasons,
      morningAnnouncements: morningAnnouncements,
      quicheIsActive: quicheIsActive,
    );

    // --- NETTOYAGE ---
    NightCleanup.run(
      context: context,
      players: players,
      finalDeathReasons: finalDeathReasons,
      morningAnnouncements: morningAnnouncements,
      quicheIsActive: quicheIsActive,
    );

    List<Player> deadNow = players.where((p) => !p.isAlive && finalDeathReasons.containsKey(p.name)).toList();

    debugPrint("🏁 LOG [Logic] : Résolution terminée.");
    return NightResult(
      deadPlayers: deadNow,
      deathReasons: finalDeathReasons,
      villageWasProtected: quicheIsActive,
      announcements: morningAnnouncements,
      villageIsNarcoleptic: false,
      revealedPlayerNames: playersToReveal,
      exorcistVictory: exorcistSuccess,
    );
  }
}
