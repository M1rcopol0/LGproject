import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/globals.dart';

class ChamanInterface extends StatelessWidget {
  final List<Player> players;
  final Function(Player?) onTargetSelected;

  const ChamanInterface({
    super.key,
    required this.players,
    required this.onTargetSelected
  });

  @override
  Widget build(BuildContext context) {
    // 1. Vérifier si le Chaman est le dernier loup en vie
    final otherWolvesAlive = players.where((p) =>
    p.isAlive &&
        p.team == "loups" &&
        p.role?.toLowerCase() != "loup-garou chaman"
    ).toList();

    bool isLastWolf = otherWolvesAlive.isEmpty;

    // 2. Si c'est le dernier loup, son pouvoir de vision est désactivé
    if (isLastWolf) {
      debugPrint("🔮 LOG [Chaman] : Le Chaman est le dernier loup. Vision désactivée.");
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.visibility_off, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text(
                "DERNIER LOUP EN VIE",
                style: TextStyle(color: Colors.purpleAccent, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "En tant que dernier survivant de votre meute, vous perdez votre vision chamanique pour vous concentrer sur la chasse.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
                onPressed: () {
                  debugPrint("🔮 LOG [Chaman] : Passage forcé au meurtre des loups.");
                  onTargetSelected(null);
                },
                child: const Text("PASSER AU VOTE DES LOUPS", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Sinon, filtrer les cibles pour la vision (Vivant et PAS loup)
    final targets = players.where((p) => p.isAlive && p.team != "loups").toList();
    targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "VISION CHAMANIQUE\nChoisissez un joueur pour révéler son rôle.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final p = targets[index];
              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  title: Text(formatPlayerName(p.name), style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.remove_red_eye, color: Colors.purpleAccent),
                  onTap: () => _showRolePopup(context, p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRolePopup(BuildContext context, Player target) {
    // Enregistrement de la cible pour le succès "Chaman Sniper"
    nightChamanTarget = target;
    debugPrint("🔮 LOG [Chaman] : A utilisé son pouvoir sur ${target.name} (${target.role}).");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Révélation", style: TextStyle(color: Colors.purpleAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatPlayerName(target.name).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("est en réalité :", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Text(
              target.role?.toUpperCase() ?? "INCONNU",
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                onTargetSelected(target);
              },
              child: const Text("BIEN REÇU"),
            ),
          ),
        ],
      ),
    );
  }
}