import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/globals.dart';
import 'package:fluffer/achievement_logic.dart';

class NightCleanup {
  static void run({
    required BuildContext context,
    required List<Player> players,
    required Map<String, String> finalDeathReasons,
    required List<String> morningAnnouncements,
    required bool quicheIsActive,
  }) {
    debugPrint("🔄 CAPTEUR [Cleanup] : Début du nettoyage de fin de nuit.");
    for (var p in players) {
      // Morts differees (Pantin)
      if (p.isAlive && p.pantinCurseTimer == 0) {
        if (quicheIsActive) {
          debugPrint("🔄 CAPTEUR [Cleanup] : Malédiction retardée par Quiche pour ${p.name}.");
          p.pantinCurseTimer = 1;
          quicheSavedThisNight++;
        } else {
          debugPrint("🔄 CAPTEUR [Cleanup] : Malédiction fatale: ${p.name} meurt (Pantin).");
          p.isAlive = false;
          AchievementLogic.checkDeathAchievements(context, p, players);
          finalDeathReasons[p.name] = "Malédiction du Pantin";
          if (p.role?.toLowerCase().contains("pok") == true && p.pokemonRevengeTarget != null && p.pokemonRevengeTarget!.isAlive) {
            Player rev = p.pokemonRevengeTarget!;
            debugPrint("🔄 CAPTEUR [Cleanup] : Pokémon vengeance (via malédiction) -> cible ${rev.name}.");
            rev.isAlive = false;
            finalDeathReasons[rev.name] = "Vengeance du Pokémon";
            morningAnnouncements.add("⚡ Le Pokémon emporte ${rev.name} !");
          }
        }
      }

      // Machine d'etat Grand-mere Quiche
      if (p.role?.toLowerCase() == "grand-mère" && p.isAlive) {
        if (p.hasBakedQuiche) {
          debugPrint("🔄 CAPTEUR [Cleanup] : Quiche activée pour ${p.name}.");
          p.isVillageProtected = true;
          p.hasBakedQuiche = false;
          p.powerActiveThisTurn = true;
        } else if (p.isVillageProtected && !p.powerActiveThisTurn) {
          debugPrint("🔄 CAPTEUR [Cleanup] : Quiche expirée pour ${p.name}.");
          p.isVillageProtected = false;
          p.hasSavedSelfWithQuiche = false;
        }
      }

      // Reset des flags temporaires
      debugPrint("🔄 CAPTEUR [Cleanup] : Reset flags pour ${p.name}.");
      p.powerActiveThisTurn = false;
      p.isProtectedByPokemon = false;
      p.hasReturnedThisTurn = false;
      p.hostedRonAldoThisTurn = false;
      p.isProtectedBySaltimbanque = false;
      if (!p.hasBeenHitByDart) p.isEffectivelyAsleep = false;
    }
  }
}
