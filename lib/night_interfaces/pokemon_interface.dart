import 'package:flutter/material.dart';
import '../models/player.dart';
import 'target_selector_interface.dart';

class PokemonInterface extends StatelessWidget {
  final Player actor;
  final List<Player> players;
  final Function(Player?) onRevengeTargetSelected; // La cible si le Pokemon meurt

  const PokemonInterface({
    super.key,
    required this.actor,
    required this.players,
    required this.onRevengeTargetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.bolt, size: 60, color: Colors.yellowAccent),
              SizedBox(height: 10),
              Text(
                "INSTINCT DE SURVIE",
                style: TextStyle(color: Colors.yellowAccent, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Si vous mourez cette nuit (attaque ou sacrifice),\nqui emportez-vous avec vous ?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            // On exclut le joueur lui-même
            players: players.where((p) => p.isAlive && p != actor).toList(),
            maxTargets: 1,
            isProtective: false, // Affichage rouge (agressif)
            onTargetsSelected: (selected) {
              if (selected.isNotEmpty) {
                onRevengeTargetSelected(selected.first);
              } else {
                onRevengeTargetSelected(null); // Pas de cible
              }
            },
          ),
        ),
      ],
    );
  }
}