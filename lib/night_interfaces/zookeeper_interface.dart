import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'target_selector_interface.dart';

class ZookeeperInterface extends StatelessWidget {
  final List<Player> players;
  final Function(Player) onTargetSelected;

  const ZookeeperInterface({
    super.key,
    required this.players,
    required this.onTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    // --- CORRECTION CRITIQUE ---
    // 1. On ne garde QUE les joueurs VIVANTS.
    // 2. On exclut ceux qui ont déjà le venin en cours.
    // 3. AJOUT : On exclut le Zookeeper lui-même (ne peut pas se viser).
    final selectablePlayers = players.where((p) =>
    p.isAlive &&
        !p.hasBeenHitByDart &&
        !p.zookeeperEffectReady &&
        p.role?.toLowerCase() != "zookeeper" // <--- EMPÊCHE L'AUTO-CIBLE
    ).toList();

    // Tri alphabétique pour plus de clarté
    selectablePlayers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    debugPrint("💉 LOG [Zookeeper] : Interface chargée. Cibles éligibles : ${selectablePlayers.length}");

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.colorize, color: Colors.cyanAccent, size: 50),
              const SizedBox(height: 10),
              const Text(
                "FLÉCHETTE ANESTHÉSIANTE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Le venin est lent. Votre cible pourra voter demain, mais s'endormira la NUIT PROCHAINE.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.cyanAccent, thickness: 0.5, indent: 40, endIndent: 40),
        Expanded(
          child: TargetSelectorInterface(
            players: selectablePlayers,
            maxTargets: 1,
            isProtective: false,
            onTargetsSelected: (selectedList) {
              if (selectedList.isNotEmpty) {
                final target = selectedList.first;

                debugPrint("💉 LOG [Zookeeper] : Fléchette tirée sur ${target.name}.");
                debugPrint("⏳ LOG [Zookeeper] : Venin injecté. Activation prévue au début de la Nuit suivante.");

                target.hasBeenHitByDart = true;
                target.zookeeperEffectReady = true;

                onTargetSelected(target);
              } else {
                debugPrint("💉 LOG [Zookeeper] : Aucun tir effectué ce tour.");
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Text(
            "⚠️ L'effet dure un cycle complet (Nuit + Jour).",
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
        ),
      ],
    );
  }
}