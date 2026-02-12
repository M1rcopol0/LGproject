import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';

class KungFuPandaInterface extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final VoidCallback onActionComplete;

  const KungFuPandaInterface({super.key, required this.player, required this.allPlayers, required this.onActionComplete});

  @override
  State<KungFuPandaInterface> createState() => _KungFuPandaInterfaceState();
}

class _KungFuPandaInterfaceState extends State<KungFuPandaInterface> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Kung-Fu Panda 🐼", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("Désignez un joueur qui devra crier 'KUNG-FU PANDA !' demain matin.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: widget.allPlayers.length,
            itemBuilder: (context, i) {
              final p = widget.allPlayers[i];
              if (!p.isAlive) return const SizedBox();

              return Card(
                color: Colors.white10,
                child: ListTile(
                  leading: const Icon(Icons.record_voice_over, color: Colors.white),
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    debugPrint("🎭 CAPTEUR [Action] : Kung-Fu Panda désigne ${p.name}.");
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${p.name} devra crier !")));
                    widget.onActionComplete();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}