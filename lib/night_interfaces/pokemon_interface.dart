import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluffer/models/player.dart';
import 'package:fluffer/logic.dart';
import 'package:fluffer/fin.dart';
import 'package:fluffer/achievement_logic.dart';
import 'package:fluffer/game_save_service.dart';
import 'package:fluffer/globals.dart';

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
    // Vérifier si le Dresseur est mort (Logique active)
    bool trainerDead = !allPlayers.any((p) => p.role?.toLowerCase() == "dresseur" && p.isAlive);

    if (!trainerDead) {
      // Cas passif (Dresseur vivant) : Juste un message
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, size: 80, color: Colors.yellowAccent),
              const SizedBox(height: 20),
              const Text(
                "Le Dresseur est en vie.",
                style: TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const Text(
                "Tu agis à travers lui.",
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => onAction(null),
                child: const Text("CONTINUER"),
              ),
            ],
          ),
        ),
      );
    }

    // Cas Actif (Dresseur Mort) : Sélection de cible pour attaque nocturne
    // TRI ALPHABÉTIQUE
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
            "Le Dresseur est mort. Ta rage te permet de foudroyer un joueur chaque nuit !",
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
              onAction(target); // Renvoie la cible au Dispatcher (sera ajoutée à pendingDeaths)
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

  /// Lance la séquence de vengeance complète
  static Future<void> handleVengeance({
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

    if (!context.mounted) return;

    // 2. Sélection de la cible
    // RÈGLE : Le Pokémon ne peut PAS tuer le Dresseur
    final List<Player> validTargets = allPlayers.where((p) =>
    p.isAlive &&
        p.name != pokemon.name &&
        p.role?.toLowerCase() != "dresseur"
    ).toList();

    // TRI ALPHABÉTIQUE
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

    // Si aucune cible n'est sélectionnée (ex: annulation ou liste vide), on arrête là.
    if (selectedTarget == null) {
      debugPrint("⚡ LOG [Pokémon] : Aucune cible sélectionnée pour la vengeance.");
      return;
    }

    if (!context.mounted) return;

    // 3. Exécution du Kill Immédiat
    playSfx("gunshot.mp3");
    Player deadPlayer = GameLogic.eliminatePlayer(
        context,
        allPlayers,
        selectedTarget,
        isVote: false,
        reason: "Attaque Tonnerre (Vengeance)"
    );

    // 4. Dialogue de confirmation
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("CIBLE FOUDROYÉE", style: TextStyle(color: Colors.white)),
        content: Text(
          "${deadPlayer.name} a été grillé sur place.\nSon rôle était : ${deadPlayer.role?.toUpperCase()}",
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
    String? winner = GameLogic.checkWinner(allPlayers);

    if (winner != null && context.mounted) {
      debugPrint("🏆 LOG [Pokémon] : Le tonnerre a donné la victoire à $winner !");

      // Gestion des succès de fin
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

      // Navigation forcée vers l'écran de fin
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => GameOverScreen(
                    winnerType: winner,
                    players: List.from(allPlayers)
                )
            ),
                (route) => false
        );
      });
    }
  }
}