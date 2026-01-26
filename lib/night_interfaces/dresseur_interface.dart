import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';

class DresseurInterface extends StatelessWidget {
  final Player actor; // Le joueur qui agit (Dresseur ou Pokémon)
  final List<Player> allPlayers;
  final Function(Player?) onComplete;

  const DresseurInterface({
    super.key,
    required this.actor,
    required this.allPlayers,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Recherche des deux protagonistes
    final trainerPlayer = allPlayers.firstWhere(
          (p) => p.role?.toLowerCase() == "dresseur",
      orElse: () => Player(name: "Inconnu", isAlive: false),
    );
    final pokemonPlayer = allPlayers.firstWhere(
          (p) => p.role?.toLowerCase() == "pokémon",
      orElse: () => Player(name: "Inconnu", isAlive: false),
    );

    bool isTrainerAlive = trainerPlayer.isAlive;
    bool isPokemonAlive = pokemonPlayer.isAlive;
    String? lastAction = actor.lastDresseurAction;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTrainerAlive ? Icons.pets : Icons.auto_fix_high,
            color: isTrainerAlive ? Colors.orangeAccent : Colors.redAccent,
            size: 60,
          ),
          const SizedBox(height: 10),
          Text(
            isTrainerAlive ? "ACTIONS DU DRESSEUR" : "RAGE DU POKÉMON",
            style: TextStyle(
              color: isTrainerAlive ? Colors.white : Colors.redAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isTrainerAlive
                  ? "Le Dresseur est en vie. Alternez vos pouvoirs."
                  : "Le Dresseur est mort. Le Pokémon ne connaît plus que la violence.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          const SizedBox(height: 30),

          // --- OPTION : RÉANIMATION (1x par partie) ---
          // Apparaît si le Dresseur est en vie, le Pokémon mort, et le pouvoir non utilisé
          if (isTrainerAlive && !isPokemonAlive && !actor.hasUsedRevive)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _btn(Icons.healing, "RÉANIMER POKÉMON", Colors.green, Colors.white, () {
                _executeRevive(pokemonPlayer);
              }),
            ),

          // --- OPTION 1 : IMMOBILISER (Alternance requise) ---
          if (isTrainerAlive && isPokemonAlive && lastAction != "IMMOBILISER")
            _btn(Icons.flash_on, "IMMOBILISER", Colors.orange, Colors.white, () {
              _showImmobilizeSelector(context);
            }),

          // --- OPTION 2 : PROTÉGER (Alternance requise) ---
          if (isTrainerAlive && isPokemonAlive && lastAction != "PROTEGER")
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _btn(Icons.shield, "PROTÉGER", Colors.blue, Colors.white, () {
                _showProtectionChoice(context);
              }),
            ),

          // --- OPTION 3 : ATTAQUE (Dresseur MORT) ---
          if (!isTrainerAlive && isPokemonAlive)
            _btn(Icons.dangerous, "ATTAQUER (MORTEL)", Colors.red[900]!, Colors.white, () {
              _showKillSelector(context);
            }),

          // Cas où le Pokémon est mort et la réanimation a été utilisée
          if (!isPokemonAlive && (actor.hasUsedRevive || !isTrainerAlive))
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Le Pokémon ne peut plus agir.",
                style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
              ),
            ),

          const SizedBox(height: 20),
          TextButton(
            onPressed: () => onComplete(null),
            child: const Text("PASSER SON TOUR", style: TextStyle(color: Colors.white24)),
          )
        ],
      ),
    );
  }

  void _executeRevive(Player pokemon) {
    pokemon.isAlive = true;
    actor.hasUsedRevive = true; // Consomme l'unique utilisation
    actor.lastDresseurAction = "REVIVE";
    onComplete(null);
  }

  void _showImmobilizeSelector(BuildContext context) {
    final targets = allPlayers.where((p) => p.isAlive && p != actor).toList();
    targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Immobilisation", style: TextStyle(color: Colors.orangeAccent)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(formatPlayerName(targets[i].name), style: const TextStyle(color: Colors.white)),
              subtitle: Text(targets[i].role ?? "Villageois", style: const TextStyle(color: Colors.white38)),
              onTap: () {
                // L'immobilisation met le joueur en état de sommeil différé
                targets[i].isEffectivelyAsleep = true;
                targets[i].powerActiveThisTurn = true;
                actor.lastDresseurAction = "IMMOBILISER";
                Navigator.pop(ctx);
                onComplete(null);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showProtectionChoice(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Qui protéger ?", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Le Dresseur", style: TextStyle(color: Colors.white)),
              leading: const Icon(Icons.person, color: Colors.blueAccent),
              onTap: () {
                final d = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "dresseur");
                d.isProtectedByPokemon = true;
                actor.lastDresseurAction = "PROTEGER";
                Navigator.pop(ctx);
                onComplete(null);
              },
            ),
            ListTile(
              title: const Text("Le Pokémon", style: TextStyle(color: Colors.white)),
              leading: const Icon(Icons.catching_pokemon, color: Colors.amber),
              onTap: () {
                final p = allPlayers.firstWhere((p) => p.role?.toLowerCase() == "pokémon");
                p.isProtectedByPokemon = true;
                actor.lastDresseurAction = "PROTEGER";
                Navigator.pop(ctx);
                onComplete(null);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showKillSelector(BuildContext context) {
    final targets = allPlayers.where((p) => p.isAlive && p != actor).toList();
    targets.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Choisir une proie", style: TextStyle(color: Colors.redAccent)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(formatPlayerName(targets[i].name), style: const TextStyle(color: Colors.white)),
              leading: const Icon(Icons.close, color: Colors.red),
              onTap: () {
                actor.lastDresseurAction = "ATTAQUE";
                Navigator.pop(ctx);
                onComplete(targets[i]); // Renvoie la victime pour élimination
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String lbl, Color bgCol, Color txtCol, VoidCallback tap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgCol,
        foregroundColor: txtCol,
        minimumSize: const Size(280, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      onPressed: tap,
      icon: Icon(icon, color: txtCol),
      label: Text(
        lbl,
        style: TextStyle(
          color: txtCol,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}