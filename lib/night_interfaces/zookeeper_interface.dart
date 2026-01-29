import 'package:flutter/material.dart';
import '../models/player.dart';
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
    // 1. On ne garde QUE les joueurs VIVANTS (fix du bug "viser un mort").
    // 2. On exclut ceux qui ont déjà le venin en cours pour éviter les doublons inutiles.
    final selectablePlayers = players.where((p) =>
    p.isAlive &&
        !p.hasBeenHitByDart &&
        !p.zookeeperEffectReady
    ).toList();

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
            // Si la liste filtrée est vide (rare, fin de partie), on fallback sur les vivants
            players: selectablePlayers.isNotEmpty
                ? selectablePlayers
                : players.where((p) => p.isAlive).toList(),
            maxTargets: 1,
            isProtective: false,
            onTargetsSelected: (selectedList) {
              if (selectedList.isNotEmpty) {
                final target = selectedList.first;

                // --- LOGS DE CONSOLE ---
                debugPrint("💉 LOG [Zookeeper] : Fléchette tirée sur ${target.name}.");
                debugPrint("⏳ LOG [Zookeeper] : Venin injecté. Activation prévue au début de la Nuit suivante.");

                // --- LOGIQUE DIFFÉRÉE ---
                // On marque que la cible a été touchée
                target.hasBeenHitByDart = true;
                // On prépare le venin pour qu'il s'active au début de la prochaine boucle de nuit
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