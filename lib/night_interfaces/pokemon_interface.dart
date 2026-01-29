import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'target_selector_interface.dart';

class PokemonInterface extends StatefulWidget {
  final Player actor;
  final List<Player> players;
  final Function(Player) onTargetSelected;

  const PokemonInterface({
    super.key,
    required this.actor,
    required this.players,
    required this.onTargetSelected,
  });

  @override
  State<PokemonInterface> createState() => _PokemonInterfaceState();
}

class _PokemonInterfaceState extends State<PokemonInterface> {
  @override
  Widget build(BuildContext context) {
    debugPrint("🔥 LOG [Pokémon] : Interface Revenge Link chargée.");

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "LIEN DE VENGEANCE\nSi vous mourrez ce tour-ci, la personne choisie mourra avec vous.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
        Expanded(
          child: TargetSelectorInterface(
            players: widget.players.where((p) => p.isAlive && p != widget.actor).toList(),
            maxTargets: 1,
            isProtective: false, // C'est une menace, donc rouge
            onTargetsSelected: (selected) {
              if (selected.isNotEmpty) {
                final target = selected.first;
                debugPrint("⚡ LOG : Pokémon lie son destin à ${target.name} (Vengeance)");

                setState(() {
                  widget.actor.pokemonRevengeTarget = target;
                });

                widget.onTargetSelected(target);
              }
            },
          ),
        ),
      ],
    );
  }
}