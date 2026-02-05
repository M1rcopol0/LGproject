import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class CupidonInterface extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final VoidCallback onActionComplete;

  const CupidonInterface({super.key, required this.player, required this.allPlayers, required this.onActionComplete});

  @override
  State<CupidonInterface> createState() => _CupidonInterfaceState();
}

class _CupidonInterfaceState extends State<CupidonInterface> {
  List<Player> selectedLovers = [];

  @override
  Widget build(BuildContext context) {
    if (globalTurnNumber > 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Cupidon a déjà tiré ses flèches.", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: widget.onActionComplete, child: const Text("SUIVANT")),
          ],
        ),
      );
    }

    // TRI ALPHABÉTIQUE
    final sortedPlayers = List<Player>.from(widget.allPlayers);
    sortedPlayers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        const Text("Cupidon, formez un couple !", style: TextStyle(color: Colors.pinkAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        const Padding(padding: EdgeInsets.all(8.0), child: Text("Sélectionnez exactement 2 joueurs.", style: TextStyle(color: Colors.white70))),
        Expanded(
          child: ListView.builder(
            itemCount: sortedPlayers.length,
            itemBuilder: (context, i) {
              final p = sortedPlayers[i];
              if (!p.isAlive) return const SizedBox();

              final isSelected = selectedLovers.contains(p);
              return Card(
                color: isSelected ? Colors.pinkAccent.withOpacity(0.3) : Colors.white10,
                child: ListTile(
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  trailing: isSelected ? const Icon(Icons.favorite, color: Colors.pink) : null,
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedLovers.remove(p);
                      } else {
                        if (selectedLovers.length < 2) selectedLovers.add(p);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size(double.infinity, 50)),
          onPressed: (selectedLovers.length == 2) ? _validateLovers : null,
          child: const Text("UNIR CES JOUEURS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _validateLovers() {
    final p1 = selectedLovers[0];
    final p2 = selectedLovers[1];

    p1.isLinkedByCupidon = true;
    p1.lover = p2;
    p2.isLinkedByCupidon = true;
    p2.lover = p1;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${p1.name} et ${p2.name} sont maintenant amoureux ❤️ !")));
    widget.onActionComplete();
  }
}