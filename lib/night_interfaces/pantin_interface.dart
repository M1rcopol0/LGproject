import 'package:flutter/material.dart';
import '../models/player.dart';

class PantinInterface extends StatefulWidget {
  final List<Player> players;
  final Function(List<Player>) onTargetsSelected;

  const PantinInterface({
    super.key,
    required this.players,
    required this.onTargetsSelected,
  });

  @override
  State<PantinInterface> createState() => _PantinInterfaceState();
}

class _PantinInterfaceState extends State<PantinInterface> {
  final List<Player> _selectedTargets = [];

  void _toggleTarget(Player p) {
    setState(() {
      if (_selectedTargets.contains(p)) {
        _selectedTargets.remove(p);
      } else if (_selectedTargets.length < 2) {
        _selectedTargets.add(p);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedTargets.length == 2) {
      // Application de la logique de malédiction
      for (var target in _selectedTargets) {
        // --- LOGIQUE DE RICOCHET : LA MAISON ---
        if (target.isInHouse) {
          try {
            // Si la cible est dans la maison, c'est le propriétaire qui reçoit la malédiction
            Player houseOwner = widget.players.firstWhere(
                    (p) => p.role == "Maison" && p.isAlive
            );
            houseOwner.pantinCurseTimer = 2;
          } catch (e) {
            // Si la maison est déjà détruite ou introuvable, on maudit la cible normalement
            target.pantinCurseTimer = 2;
          }
        } else {
          // Cible normale
          target.pantinCurseTimer = 2;
        }
      }
      widget.onTargetsSelected(_selectedTargets);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le Pantin ne peut pas se maudire lui-même
    final List<Player> availableTargets = widget.players
        .where((p) => p.isAlive && p.role != "Pantin")
        .toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "PANTIN : Choisissez 2 joueurs à maudire.\nIls mourront dans 2 nuits.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: availableTargets.length,
            itemBuilder: (context, index) {
              final p = availableTargets[index];
              final isSelected = _selectedTargets.contains(p);

              return ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                // Information MJ : On voit si le joueur est protégé par la maison
                subtitle: Text(p.isInHouse ? "Est dans la Maison (Protection active)" : "Au village",
                    style: TextStyle(
                        color: p.isInHouse ? Colors.blueAccent : Colors.white54,
                        fontSize: 12,
                        fontWeight: p.isInHouse ? FontWeight.bold : FontWeight.normal
                    )),
                leading: Icon(
                  isSelected ? Icons.whatshot : Icons.person_outline,
                  color: isSelected ? Colors.orange : Colors.grey,
                ),
                onTap: () => _toggleTarget(p),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _selectedTargets.length == 2 ? _confirmSelection : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.white10
            ),
            child: Text(
              _selectedTargets.length < 2
                  ? "SÉLECTIONNEZ 2 CIBLES"
                  : "MAUDIRE LES 2 CIBLES",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}