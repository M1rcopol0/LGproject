import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'player.dart';

extension PlayerStatusIconsExtension on Player {
  Widget buildStatusIcons() {
    if (!isAlive) return const SizedBox.shrink();

    List<Widget> icons = [];

    if (isVillageChief) icons.add(const Icon(Icons.workspace_premium, size: 16, color: Colors.amber));
    if (isRoi) icons.add(const Icon(FontAwesomeIcons.crown, size: 14, color: Colors.amberAccent));
    if (isInHouse) icons.add(const Icon(Icons.home, size: 16, color: Colors.orangeAccent));
    if (isProtectedByPokemon) icons.add(const Icon(Icons.bolt, size: 16, color: Colors.yellow));
    if (isEffectivelyAsleep) icons.add(const Icon(Icons.bedtime, size: 16, color: Colors.blueAccent));

    if (isRevealedByDevin) {
      icons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(Icons.remove_red_eye, size: 16, color: Colors.purpleAccent),
      ));
    }

    if (hasBeenHitByDart) icons.add(const Icon(Icons.colorize, size: 16, color: Colors.deepPurpleAccent));
    if (pantinCurseTimer != null) icons.add(const Icon(Icons.link, size: 16, color: Colors.redAccent));

    if (isBombed) {
      icons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(FontAwesomeIcons.bomb, size: 14, color: Colors.redAccent),
      ));
    }

    if (isLinkedByCupidon) {
      icons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(Icons.favorite, size: 14, color: Colors.pinkAccent),
      ));
    }

    if (isProtectedBySaltimbanque) {
      icons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(Icons.shield, size: 14, color: Colors.amberAccent),
      ));
    }

    if (hasScapegoatPower) {
      icons.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Icon(Icons.pets, size: 14, color: Colors.white),
      ));
    }

    if (role?.toLowerCase() == "dingo" && dingoStrikeCount > 0) {
      icons.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.gps_fixed, size: 14, color: Colors.red),
            Text(
              "$dingoStrikeCount",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ));
    }

    if (role?.toLowerCase() == "voyageur" && travelerBullets > 0) {
      icons.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.change_history, size: 14, color: Colors.cyanAccent),
            Text(
              "$travelerBullets",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }
}
