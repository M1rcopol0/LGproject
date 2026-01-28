import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';

class TargetSelectorInterface extends StatefulWidget {
  final List<Player> players;
  final int maxTargets;
  final int minTargets; // Ajout du paramètre manquant
  final Function(List<Player>) onTargetsSelected;
  final bool isProtective;

  const TargetSelectorInterface({
    super.key,
    required this.players,
    required this.maxTargets,
    required this.onTargetsSelected,
    this.minTargets = 0, // Valeur par défaut à 0 pour ne pas casser les autres rôles
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

    // Vérification de la validité pour le bouton
    // Valide si aucune sélection (Action Passer) OU si le min est atteint
    bool isValid = _selected.isEmpty || _selected.length >= widget.minTargets;

    String buttonText = _selected.isEmpty ? "PASSER" : "VALIDER";

    // Si on a commencé à sélectionner mais pas assez, on indique le manque
    if (!_selected.isEmpty && _selected.length < widget.minTargets) {
      buttonText = "CHOISIR ${widget.minTargets} CIBLES";
      isValid = false;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.minTargets > 0
                ? "Sélectionnez entre ${widget.minTargets} et ${widget.maxTargets} joueur(s)"
                : "Sélectionnez jusqu'à ${widget.maxTargets} joueur(s)",
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
              backgroundColor: isValid
                  ? (widget.isProtective ? Colors.green[700] : Colors.red[900])
                  : Colors.grey, // Grisé si invalide
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: isValid ? () {
              if (_selected.isEmpty) {
                debugPrint("🎯 LOG [Selector] : Aucune cible choisie (Action PASSÉE).");
                widget.onTargetsSelected([]);
              } else {
                debugPrint("🎯 LOG [Selector] : Validation de ${_selected.length} cible(s) : ${_selected.map((s) => s.name).join(', ')}");
                widget.onTargetsSelected(_selected);
              }
            } : null, // Bouton désactivé si condition minTargets non respectée
            child: Text(buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _toggleSelection(Player p) {
    setState(() {
      if (_selected.contains(p)) {
        debugPrint("🎯 LOG [Selector] : Désélection de ${p.name}");
        _selected.remove(p);
      } else {
        if (_selected.length >= widget.maxTargets) {
          // Si on dépasse le max, on retire le premier pour ajouter le nouveau (comportement glissant)
          final removed = _selected.removeAt(0);
          debugPrint("🎯 LOG [Selector] : Limite atteinte (${widget.maxTargets}). Remplacement de ${removed.name} par ${p.name}");
        } else {
          debugPrint("🎯 LOG [Selector] : Sélection de ${p.name}");
        }
        _selected.add(p);
      }
    });
  }
}