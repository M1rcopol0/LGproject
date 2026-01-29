import 'package:flutter/material.dart';
import '../../models/player.dart';

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
      debugPrint("🎭 LOG [Pantin] : Début de l'application des malédictions.");

      for (var target in _selectedTargets) {
        // --- LOGIQUE DE RICOCHET : LA MAISON ---
        if (target.isInHouse) {
          try {
            // Si la cible est dans la maison, c'est le propriétaire qui reçoit la malédiction
            Player houseOwner = widget.players.firstWhere(
                    (p) => p.role?.toLowerCase() == "maison" && p.isAlive
            );

            // Si le propriétaire est déjà maudit, le ricochet ne prolonge pas sa malédiction
            if (houseOwner.pantinCurseTimer != null) {
              debugPrint("🏠 LOG [Pantin] : Ricochet annulé, le propriétaire ${houseOwner.name} est déjà maudit.");
            } else {
              debugPrint("🏠 LOG [Pantin] : La cible ${target.name} est à l'abri. Ricochet sur le propriétaire : ${houseOwner.name}");
              houseOwner.pantinCurseTimer = 2;
            }
          } catch (e) {
            debugPrint("🎭 LOG [Pantin] : Cible ${target.name} en maison, mais propriétaire introuvable. Malédiction directe.");
            target.pantinCurseTimer = 2;
          }
        } else {
          // Cible normale
          debugPrint("🎭 LOG [Pantin] : Malédiction appliquée sur ${target.name}.");
          target.pantinCurseTimer = 2;
        }
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
            "PANTIN : Choisissez 2 joueurs à maudire.\nIls mourront dans 2 nuits.",
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
                      ? const Text("Est dans la Maison (Ricochet possible)", style: TextStyle(color: Colors.blueAccent, fontSize: 12))
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
            // On désactive le bouton si on ne peut pas choisir 2 personnes (ex: il reste 1 survivant non maudit)
            onPressed: (_selectedTargets.length == 2)
                ? _confirmSelection
                : (availableTargets.length < 2 && _selectedTargets.length == availableTargets.length ? _handleForcePass : null),
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
    // Cas rare : Il reste moins de 2 cibles valides. On maudit ce qu'on peut et on passe.
    _confirmSelection();
    if (_selectedTargets.length < 2) {
      // Si on n'avait pas assez de cibles, on force la fin
      widget.onTargetsSelected(_selectedTargets);
    }
  }

  String _getButtonText(int availableCount) {
    if (_selectedTargets.length == 2) return "MAUDIRE LES CIBLES";
    if (availableCount < 2) return "PASSER (Pas assez de cibles)";
    return "SÉLECTIONNEZ 2 CIBLES";
  }
}