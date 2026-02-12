import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';

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
      } else {
        // CORRECTION : On vide la liste pour ne garder qu'une seule cible
        _selectedTargets.clear();
        _selectedTargets.add(p);
      }
    });
  }

  void _confirmSelection() {
    // On vérifie qu'il y a bien 1 cible (ou 0 si on force le passage car pas de cibles dispo)
    bool canConfirm = _selectedTargets.length == 1;
    bool noTargetsAvailable = widget.players.where((p) => p.isAlive && p.role?.toLowerCase() != "pantin" && p.pantinCurseTimer == null).isEmpty;

    if (canConfirm || (noTargetsAvailable && _selectedTargets.isEmpty)) {
      debugPrint("🎭 CAPTEUR [Action] : Pantin application de la malédiction.");

      for (var target in _selectedTargets) {
        debugPrint("🎭 CAPTEUR [Action] : Pantin maudit ${target.name} (timer: 2 nuits).");
        target.pantinCurseTimer = 2;
      }
      widget.onTargetsSelected(_selectedTargets);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filtrer : Vivants + Pas Pantin + PAS DÉJÀ MAUDIT (Timer doit être null)
    final List<Player> availableTargets = widget.players
        .where((p) => p.isAlive &&
        p.role?.toLowerCase() != "pantin" &&
        p.pantinCurseTimer == null)
        .toList();

    // 2. Trier par ordre alphabétique
    availableTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "PANTIN : Choisissez 1 joueur à maudire.\nIl mourra dans 2 nuits.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
          ),
        ),
        if (availableTargets.isEmpty)
          const Expanded(child: Center(child: Text("Plus personne à maudire !", style: TextStyle(color: Colors.white54))))
        else
          Expanded(
            child: ListView.builder(
              itemCount: availableTargets.length,
              itemBuilder: (context, index) {
                final p = availableTargets[index];
                final isSelected = _selectedTargets.contains(p);

                return ListTile(
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  subtitle: p.isInHouse
                      ? const Text("Dans la Maison", style: TextStyle(color: Colors.blueAccent, fontSize: 12))
                      : null,
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
            onPressed: (_selectedTargets.length == 1)
                ? _confirmSelection
                : (availableTargets.isEmpty ? _handleForcePass : null),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                disabledBackgroundColor: Colors.white10
            ),
            child: Text(
              _getButtonText(availableTargets.length),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void _handleForcePass() {
    _selectedTargets.clear();
    _confirmSelection();
  }

  String _getButtonText(int availableCount) {
    if (_selectedTargets.length == 1) return "MAUDIRE LA CIBLE";
    if (availableCount == 0) return "PASSER (Personne à maudire)";
    return "SÉLECTIONNEZ 1 CIBLE";
  }
}