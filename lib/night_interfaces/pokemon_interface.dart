import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/player.dart';
import '../logic/logic.dart';
import '../screens/fin_screen.dart';
import '../logic/achievement_logic.dart';
import '../services/game_save_service.dart';
import '../services/audio_service.dart';
import '../globals.dart';

class PokemonInterface extends StatelessWidget {
  final Player player;
  final List<Player> allPlayers;
  final Function(Player?) onAction; // Appelée avec la cible (ou null si skip)

  const PokemonInterface({
    super.key,
    required this.player,
    required this.allPlayers,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // Le Pokémon attaque chaque nuit
    final targets = allPlayers.where((p) => p.isAlive && p.name != player.name).toList();
    targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(10.0),
          child: Text("⚡ ATTAQUE TONNERRE", style: TextStyle(color: Colors.yellowAccent, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
          child: Text(
            "Foudroie un joueur cette nuit !",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final p = targets[index];
              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.flash_on, color: Colors.yellow),
                  onTap: () => _confirmAttack(context, p),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextButton(
            onPressed: () => onAction(null),
            child: const Text("PASSER", style: TextStyle(color: Colors.white54)),
          ),
        ),
      ],
    );
  }

  void _confirmAttack(BuildContext context, Player target) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text("Foudroyer ${target.name} ?", style: const TextStyle(color: Colors.white)),
        content: const Text(
          "Cette attaque sera fatale demain matin.\nLa cible reste active cette nuit.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onAction(target);
            },
            child: const Text("FOUDROYER", style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// GESTIONNAIRE CENTRALISÉ DE LA MORT DU POKÉMON (VENGEANCE)
class PokemonDeathHandler {

  /// Lance la séquence de vengeance complète (appelé par MJResultScreen ou NightDeathResolver)
  static Future<List<Player>> handleVengeance({
    required BuildContext context,
    required List<Player> allPlayers,
    required Player pokemon,
  }) async {

    debugPrint("⚡ LOG [Pokémon] : Début de la séquence de vengeance post-mortem.");

    // 1. Dialogue d'annonce
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text("⚡ VENGEANCE ÉLECTRIQUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "${pokemon.name} (Pokémon) est mort.\nIl libère une dernière décharge foudroyante !",
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

    if (!context.mounted) return [];

    // 2. Sélection de la cible
    // RÈGLE : Le Pokémon ne peut PAS tuer le Dresseur
    final List<Player> validTargets = allPlayers.where((p) =>
    p.isAlive &&
        p.name != pokemon.name &&
        p.role?.toLowerCase() != "dresseur"
    ).toList();

    validTargets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final Player? selectedTarget = await showDialog<Player>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Attaque Tonnerre ⚡", style: TextStyle(color: Colors.yellowAccent)),
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
                leading: const Icon(Icons.bolt, color: Colors.yellow),
                onTap: () => Navigator.pop(ctx, p),
              );
            },
          ),
        ),
      ),
    );

    if (selectedTarget == null) {
      debugPrint("⚡ LOG [Pokémon] : Aucune cible sélectionnée.");
      return [];
    }

    if (!context.mounted) return [];

    // 3. Exécution du Kill (Peut entraîner des morts en chaîne via List<Player>)
    playSfx("gunshot.mp3");
    List<Player> victims = GameLogic.eliminatePlayer(
        context,
        allPlayers,
        selectedTarget,
        isVote: false,
        reason: "Attaque Tonnerre (Vengeance)"
    );

    // 4. Dialogue de confirmation
    String msg = victims.map((v) => "- ${v.name} (${v.role})").join("\n");
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("CIBLE FOUDROYÉE", style: TextStyle(color: Colors.white)),
        content: Text(
          "Le tonnerre a frappé :\n$msg",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.orangeAccent)),
          )
        ],
      ),
    );

    // 5. CHECK VICTOIRE IMMÉDIAT
    String? winner = WinConditionLogic.checkWinner(allPlayers);

    if (winner != null && context.mounted) {
      debugPrint("🏆 LOG [Pokémon] : Le tonnerre a donné la victoire à $winner !");

      try {
        List<Player> winnersList = allPlayers.where((p) =>
        (winner == "VILLAGE" && p.team == "village") ||
            (winner == "LOUPS" && p.team == "loups") ||
            (winner == "SOLO" && p.team == "solo")
        ).toList();
        await AchievementLogic.checkEndGameAchievements(context, winnersList, allPlayers);
      } catch (e) {
        debugPrint("⚠️ Erreur succès: $e");
      }

      await GameSaveService.clearSave();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => GameOverScreen(
                  winnerType: winner,
                  players: allPlayers,
                )
            ),
                (route) => false
        );
      });
    }

    return victims;
  }
}