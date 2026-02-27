import 'package:flutter/material.dart';
import '../models/player.dart';
import '../logic/logic.dart';
import '../services/audio_service.dart';

/// GESTIONNAIRE CENTRALISÉ DE LA MORT DU CHASSEUR (VENGEANCE)
class ChasseurDeathHandler {

  /// Lance la séquence de vengeance complète du Chasseur
  static Future<(List<Player>, String?)> handleVengeance({
    required BuildContext context,
    required List<Player> allPlayers,
    required Player chasseur,
  }) async {

    debugPrint("🔫 LOG [Chasseur] : Début de la séquence de vengeance post-mortem.");

    // 1. Dialogue d'annonce
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text("🔫 DERNIER SOUFFLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "${chasseur.name} (Chasseur) est mort.\nIl doit éliminer quelqu'un immédiatement !",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CHOISIR LA CIBLE", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );

    if (!context.mounted) return (<Player>[], null);

    // 2. Sélection de la cible
    final List<Player> validTargets = allPlayers
        .where((p) => p.isAlive && p.name != chasseur.name)
        .toList();
    validTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final Player? selectedTarget = await showDialog<Player>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(
          "CIBLE DE ${chasseur.name.toUpperCase()}",
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: validTargets.isEmpty
              ? const Center(child: Text("Aucune cible valide.", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
            itemCount: validTargets.length,
            itemBuilder: (c, i) {
              final p = validTargets[i];
              return ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white)),
                leading: const Icon(Icons.gps_fixed, color: Colors.redAccent),
                onTap: () => Navigator.pop(ctx, p),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text("PASSER", style: TextStyle(color: Colors.white54)),
          )
        ],
      ),
    );

    if (selectedTarget == null) {
      debugPrint("🔫 LOG [Chasseur] : Aucune cible sélectionnée.");
      return (<Player>[], null);
    }

    if (!context.mounted) return (<Player>[], null);

    // 3. Exécution du Kill
    playSfx("gunshot.mp3");
    List<Player> victims = GameLogic.eliminatePlayer(
        context,
        allPlayers,
        selectedTarget,
        isVote: false,
        reason: "Tir du Chasseur"
    );

    // 4. Dialogue de confirmation
    String msg = victims.isNotEmpty
        ? victims.map((v) => "- ${v.name} (${v.role})").join("\n")
        : "La balle n'a touché personne.";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("CIBLE ABATTUE", style: TextStyle(color: Colors.white)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)),
          )
        ],
      ),
    );

    return (victims, selectedTarget.name);
  }
}
