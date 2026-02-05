import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class SorciereInterface extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final VoidCallback onActionComplete;
  final Function(Player) onKill;

  const SorciereInterface({
    super.key,
    required this.player,
    required this.allPlayers,
    required this.onActionComplete,
    required this.onKill,
  });

  @override
  State<SorciereInterface> createState() => _SorciereInterfaceState();
}

class _SorciereInterfaceState extends State<SorciereInterface> {
  bool actionUsedThisNight = false;

  @override
  Widget build(BuildContext context) {
    bool hasWolfTarget = (nightWolvesTarget != null);
    String wolfTargetName = hasWolfTarget ? nightWolvesTarget!.name : "Personne";

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("La Sorcière se réveille...", style: TextStyle(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        ),

        // Info Cible
        Container(
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: hasWolfTarget ? Colors.red.withOpacity(0.2) : Colors.white10,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: hasWolfTarget ? Colors.redAccent : Colors.white24),
          ),
          child: Column(
            children: [
              const Text("👁️ Vision de la Sorcière", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 5),
              Text(
                hasWolfTarget ? "Les Loups ont attaqué :\n$wolfTargetName" : "Aucune attaque détectée.",
                textAlign: TextAlign.center,
                style: TextStyle(color: hasWolfTarget ? Colors.redAccent : Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              // Potion Vie
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.greenAccent, size: 30),
                title: const Text("Potion de Vie", style: TextStyle(color: Colors.white)),
                subtitle: Text(widget.player.hasUsedSorciereRevive ? "Déjà utilisée" : "Disponible (1/partie)", style: const TextStyle(color: Colors.white38)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: (!widget.player.hasUsedSorciereRevive && !actionUsedThisNight && hasWolfTarget) ? _useRevive : null,
                  child: const Text("SAUVER"),
                ),
              ),
              const Divider(color: Colors.white12),
              // Potion Mort
              ListTile(
                leading: const Icon(Icons.science, color: Colors.redAccent, size: 30),
                title: const Text("Potion de Mort", style: TextStyle(color: Colors.white)),
                subtitle: Text(widget.player.hasUsedSorciereKill ? "Déjà utilisée" : "Disponible (1/partie)", style: const TextStyle(color: Colors.white38)),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: (!widget.player.hasUsedSorciereKill && !actionUsedThisNight) ? _showKillSelector : null,
                  child: const Text("TUER"),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: const BorderSide(color: Colors.white24)
            ),
            onPressed: widget.onActionComplete,
            child: const Text("TERMINER / SE RENDORMIR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _useRevive() {
    setState(() {
      widget.player.hasUsedSorciereRevive = true;
      actionUsedThisNight = true;
      nightWolvesTargetSurvived = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La cible est sauvée !"), backgroundColor: Colors.green));
  }

  void _showKillSelector() {
    // TRI ALPHABÉTIQUE
    final targets = widget.allPlayers.where((p) => p.isAlive && p != widget.player).toList();
    targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Empoisonner qui ?", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: targets.length,
            itemBuilder: (c, i) => ListTile(
              leading: const Icon(Icons.dangerous_outlined, color: Colors.white54),
              title: Text(targets[i].name, style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmKill(targets[i]);
              },
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler"))],
      ),
    );
  }

  void _confirmKill(Player target) {
    setState(() {
      widget.player.hasUsedSorciereKill = true;
      actionUsedThisNight = true;
    });
    widget.onKill(target);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${target.name} a bu la potion..."), backgroundColor: Colors.red));
  }
}