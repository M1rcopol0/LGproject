import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class TimeMasterInterface extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final Function(String, dynamic) onAction;

  const TimeMasterInterface({
    super.key,
    required this.player,
    required this.allPlayers,
    required this.onAction,
  });

  @override
  State<TimeMasterInterface> createState() => _TimeMasterInterfaceState();
}

class _TimeMasterInterfaceState extends State<TimeMasterInterface> {
  Player? _selectedTarget;

  @override
  Widget build(BuildContext context) {
    // On retire le Maître du Temps lui-même de la liste (ne peut pas s'auto-cibler)
    final candidates = widget.allPlayers
        .where((p) => p.isAlive && p.name != widget.player.name)
        .toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Choisis un joueur pour remonter le temps.\n(Sa mort sera annulée s'il meurt cette nuit)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final p = candidates[index];
              final isSelected = _selectedTarget == p;
              return ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                leading: Radio<Player>(
                  value: p,
                  groupValue: _selectedTarget,
                  activeColor: Colors.orangeAccent,
                  onChanged: (val) => setState(() => _selectedTarget = val),
                ),
                onTap: () => setState(() => _selectedTarget = p),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
              onPressed: () {
                if (_selectedTarget == null) {
                  // Permet de passer son tour explicitement
                  widget.onAction("SKIP", null);
                } else {
                  // --- SUIVI POUR SUCCÈS "TIME PERFECT" ---
                  widget.player.timeMasterUsedPower = true;

                  widget.onAction("REWIND", _selectedTarget);
                }
              },
              child: Text(
                _selectedTarget == null ? "PASSER SON TOUR" : "PROTÉGER ${_selectedTarget!.name.toUpperCase()}",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}