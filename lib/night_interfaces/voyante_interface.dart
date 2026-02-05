import 'package:flutter/material.dart';
import '../models/player.dart';

class VoyanteInterface extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final VoidCallback onActionComplete;

  const VoyanteInterface({super.key, required this.player, required this.allPlayers, required this.onActionComplete});

  @override
  State<VoyanteInterface> createState() => _VoyanteInterfaceState();
}

class _VoyanteInterfaceState extends State<VoyanteInterface> {
  bool hasLooked = false;

  @override
  Widget build(BuildContext context) {
    if (hasLooked) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, size: 60, color: Colors.purple),
            const SizedBox(height: 20),
            const Text("Vous avez vu ce que vous vouliez...", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: widget.onActionComplete, child: const Text("SUIVANT")),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Text("Voyante, dont voulez-vous voir le rôle ?", style: TextStyle(color: Colors.purpleAccent, fontSize: 18)),
        Expanded(
          child: ListView.builder(
            itemCount: widget.allPlayers.length,
            itemBuilder: (context, i) {
              final p = widget.allPlayers[i];
              if (!p.isAlive || p == widget.player) return const SizedBox(); // Ne se regarde pas elle-même

              return Card(
                color: Colors.white10,
                child: ListTile(
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.remove_red_eye, color: Colors.white54),
                  onTap: () => _revealRole(p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _revealRole(Player target) {
    setState(() => hasLooked = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text("Rôle de ${target.name}", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 50, color: Colors.orangeAccent),
            const SizedBox(height: 10),
            Text(target.role?.toUpperCase() ?? "INCONNU", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
}