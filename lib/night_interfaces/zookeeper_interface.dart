import 'package:flutter/material.dart';
import '../../models/player.dart';
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
    // 1. On filtre les joueurs vivants
    // 2. Optionnel : On peut empêcher de cibler quelqu'un qui a déjà une fléchette
    // en attente pour éviter le gaspillage.
    final selectablePlayers = players.where((p) =>
    p.isAlive && !p.hasBeenHitByDart && !p.zookeeperEffectReady
    ).toList();

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
            players: selectablePlayers.isNotEmpty ? selectablePlayers : players.where((p) => p.isAlive).toList(),
            maxTargets: 1,
            isProtective: false, // Thème orange/rouge car c'est un malus
            onTargetsSelected: (selectedList) {
              if (selectedList.isNotEmpty) {
                final target = selectedList.first;

                // --- NOUVELLE LOGIQUE DIFFÉRÉE ---
                // On marque que la cible a été touchée cette nuit (N)
                target.hasBeenHitByDart = true;
                // On prépare le venin pour qu'il s'active au début de la nuit (N+1)
                target.zookeeperEffectReady = true;

                onTargetSelected(target);
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