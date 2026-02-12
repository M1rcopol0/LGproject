import 'package:flutter/material.dart';
import '../models/player.dart';

class SaltimbanqueInterface extends StatefulWidget {
  final Player player; // Le joueur qui joue le rôle (Saltimbanque)
  final List<Player> allPlayers; // Tous les joueurs
  final VoidCallback onActionComplete;

  const SaltimbanqueInterface({
    super.key,
    required this.player,
    required this.allPlayers,
    required this.onActionComplete
  });

  @override
  State<SaltimbanqueInterface> createState() => _SaltimbanqueInterfaceState();
}

class _SaltimbanqueInterfaceState extends State<SaltimbanqueInterface> {
  @override
  Widget build(BuildContext context) {
    // 1. On ne garde que les joueurs vivants
    List<Player> activePlayers = widget.allPlayers.where((p) => p.isAlive).toList();

    // 2. On trie par ordre alphabétique (Correction demandée)
    activePlayers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Saltimbanque, qui protégez-vous ?",
            style: TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Vous ne pouvez pas protéger la même personne deux fois de suite.",
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),

        // Rappel visuel de la dernière cible
        if (widget.player.lastSaltimbanqueTarget != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3))
              ),
              child: Text(
                "Interdit ce tour : ${widget.player.lastSaltimbanqueTarget!.name}",
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        Expanded(
          child: ListView.builder(
            itemCount: activePlayers.length,
            itemBuilder: (context, i) {
              final p = activePlayers[i];

              // Vérification : Est-ce le joueur bloqué ?
              // On compare les noms pour être sûr (plus robuste que la comparaison d'objet après un chargement)
              bool isBlocked = false;
              if (widget.player.lastSaltimbanqueTarget != null) {
                isBlocked = (widget.player.lastSaltimbanqueTarget!.name == p.name);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: isBlocked ? Colors.grey.withOpacity(0.1) : const Color(0xFF2C2C40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: isBlocked ? BorderSide.none : const BorderSide(color: Colors.amberAccent, width: 0.5)
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBlocked ? Colors.grey : Colors.amber,
                    child: Text(
                      p.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(
                      color: isBlocked ? Colors.white38 : Colors.white,
                      decoration: isBlocked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: isBlocked
                      ? const Icon(Icons.block, color: Colors.redAccent)
                      : const Icon(Icons.shield_outlined, color: Colors.amberAccent),
                  onTap: isBlocked ? null : () => _protect(p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _protect(Player target) {
    debugPrint("🎭 CAPTEUR [Action] : Saltimbanque protège ${target.name}. Ancienne cible: ${widget.player.lastSaltimbanqueTarget?.name ?? 'aucune'}.");

    // Mémorisation pour le tour suivant
    widget.player.lastSaltimbanqueTarget = target;

    // Application de la protection pour cette nuit
    target.isProtectedBySaltimbanque = true;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${target.name} est protégé ! 🛡️"),
            backgroundColor: Colors.amber,
            duration: const Duration(seconds: 2),
          )
      );
      // On passe à la suite
      widget.onActionComplete();
    }
  }
}