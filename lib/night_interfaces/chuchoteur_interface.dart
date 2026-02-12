import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/globals.dart'; // Pour récupérer le tour actuel
import 'target_selector_interface.dart';

class ChuchoteurInterface extends StatelessWidget {
  final List<Player> players;
  final Function(List<Player>) onTargetsSelected; // Signature standard

  const ChuchoteurInterface({
    super.key,
    required this.players,
    // Note : Dans NightActionsScreen, le TargetSelector est appelé directement
    // mais si vous utilisez ce fichier, adaptez NightActionsScreen ou utilisez ce wrapper
    required this.onTargetsSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul du nombre de cibles selon le tour
    int maxMutes = (globalTurnNumber >= 5) ? 3 : (globalTurnNumber >= 3 ? 2 : 1);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            "Choisissez $maxMutes joueur(s) à réduire au silence.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            players: players,
            maxTargets: maxMutes,
            onTargetsSelected: (selected) {
              debugPrint("🎭 CAPTEUR [Action] : Chuchoteur réduit au silence ${selected.length} joueur(s): ${selected.map((p) => p.name).join(', ')}.");
              onTargetsSelected(selected);
            },
            isProtective: false, // C'est une attaque (silence)
          ),
        ),
      ],
    );
  }
}