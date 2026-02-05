import 'package:flutter/material.dart';
import '../models/player.dart';

class SaltimbanqueInterface extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final VoidCallback onActionComplete;

  const SaltimbanqueInterface({super.key, required this.player, required this.allPlayers, required this.onActionComplete});

  @override
  State<SaltimbanqueInterface> createState() => _SaltimbanqueInterfaceState();
}

class _SaltimbanqueInterfaceState extends State<SaltimbanqueInterface> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Saltimbanque, qui protégez-vous ?", style: TextStyle(color: Colors.amberAccent, fontSize: 18)),
        const Padding(padding: EdgeInsets.all(8.0), child: Text("Vous ne pouvez pas protéger la même personne deux fois de suite.", style: TextStyle(color: Colors.white54, fontSize: 12))),

        if (widget.player.lastSaltimbanqueTarget != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text("Dernière protection : ${widget.player.lastSaltimbanqueTarget!.name}", style: const TextStyle(color: Colors.redAccent)),
          ),

        Expanded(
          child: ListView.builder(
            itemCount: widget.allPlayers.length,
            itemBuilder: (context, i) {
              final p = widget.allPlayers[i];
              if (!p.isAlive) return const SizedBox();

              // Interdiction de protéger le même joueur 2 fois de suite
              bool isBlocked = (widget.player.lastSaltimbanqueTarget == p);

              return Card(
                color: isBlocked ? Colors.grey.withOpacity(0.1) : Colors.white10,
                child: ListTile(
                  title: Text(p.name, style: TextStyle(color: isBlocked ? Colors.white38 : Colors.white)),
                  trailing: isBlocked ? const Icon(Icons.block, color: Colors.red) : const Icon(Icons.shield, color: Colors.amber),
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
    widget.player.lastSaltimbanqueTarget = target;
    target.isProtectedBySaltimbanque = true;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${target.name} est protégé cette nuit.")));
    widget.onActionComplete();
  }
}