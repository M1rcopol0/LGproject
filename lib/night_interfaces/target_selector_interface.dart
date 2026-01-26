import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart'; // Import corrigé (pas logic/)

class TargetSelectorInterface extends StatefulWidget {
  final List<Player> players;
  final int maxTargets;
  final Function(List<Player>) onTargetsSelected;
  final bool isProtective;

  const TargetSelectorInterface({
    super.key,
    required this.players,
    required this.maxTargets,
    required this.onTargetsSelected,
    this.isProtective = false,
  });

  @override
  State<TargetSelectorInterface> createState() => _TargetSelectorInterfaceState();
}

class _TargetSelectorInterfaceState extends State<TargetSelectorInterface> {
  final List<Player> _selected = [];

  @override
  Widget build(BuildContext context) {
    // 1. Filtrer les vivants
    final candidates = widget.players.where((p) => p.isAlive).toList();

    // 2. TRI ALPHABÉTIQUE
    candidates.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Sélectionnez ${widget.maxTargets} joueur(s)",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, i) {
              final p = candidates[i];
              final isSel = _selected.contains(p);
              return ListTile(
                title: Text(formatPlayerName(p.name), style: const TextStyle(color: Colors.white)),
                trailing: isSel
                    ? Icon(Icons.check_circle, color: widget.isProtective ? Colors.green : Colors.red)
                    : const Icon(Icons.circle_outlined, color: Colors.white24),
                onTap: () => _toggleSelection(p),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isProtective ? Colors.green[700] : Colors.red[900],
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: (_selected.isNotEmpty)
                ? () => widget.onTargetsSelected(_selected)
                : () => widget.onTargetsSelected([]), // Permet de passer
            child: Text(_selected.isEmpty ? "PASSER" : "VALIDER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _toggleSelection(Player p) {
    setState(() {
      if (_selected.contains(p)) {
        _selected.remove(p);
      } else {
        if (_selected.length >= widget.maxTargets) {
          _selected.removeAt(0);
        }
        _selected.add(p);
      }
    });
  }
}