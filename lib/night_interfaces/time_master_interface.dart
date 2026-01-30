import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class TimeMasterInterface extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;
  final Function(String, dynamic) onAction;

  const TimeMasterInterface({
    super.key,
    required this.player,
    required this.allPlayers,
    required this.onAction,
  });

  @override
  State<TimeMasterInterface> createState() => _TimeMasterInterfaceState();
}

class _TimeMasterInterfaceState extends State<TimeMasterInterface> {
  // On utilise une liste pour gérer jusqu'à 2 cibles
  final List<Player> _selectedTargets = [];

  void _toggleSelection(Player p) {
    setState(() {
      if (_selectedTargets.contains(p)) {
        _selectedTargets.remove(p);
      } else {
        if (_selectedTargets.length < 2) {
          _selectedTargets.add(p);
        } else {
          // Feedback si on essaie d'en sélectionner plus de 2
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Maximum 2 cibles autorisées."),
              duration: Duration(milliseconds: 800),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer les candidats : Vivants et pas le Maître du Temps lui-même
    // On exclut aussi le Maître du Temps de la liste pour qu'il ne puisse pas se suicider par erreur
    final candidates = widget.allPlayers
        .where((p) => p.isAlive && p.name != widget.player.name)
        .toList();

    // AJOUT : Tri alphabétique pour faciliter la recherche
    candidates.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Adapter le texte du bouton
    String buttonText = "PASSER SON TOUR";
    Color buttonColor = Colors.grey;
    if (_selectedTargets.isNotEmpty) {
      buttonText = "ÉLIMINER (${_selectedTargets.length})";
      buttonColor = Colors.cyanAccent;
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "MAÎTRE DU TEMPS",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Leur temps est écoulé.\nChoisissez jusqu'à 2 joueurs à effacer de la chronologie.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        // Liste des candidats
        Expanded(
          child: candidates.isEmpty
              ? const Center(
            child: Text("Personne d'autre n'est en vie...", style: TextStyle(color: Colors.white38)),
          )
              : ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final p = candidates[index];
              final isSelected = _selectedTargets.contains(p);

              return Card(
                color: isSelected ? Colors.cyanAccent.withOpacity(0.2) : Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.cyanAccent : Colors.white54,
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    p.role != null && p.isFanOfRonAldo ? "Fan" : "Cible potentielle",
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                  onTap: () => _toggleSelection(p),
                ),
              );
            },
          ),
        ),

        // Bouton d'action
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_selectedTargets.isEmpty) {
                  // Action Passer
                  widget.onAction("SKIP", null);
                } else {
                  // Action Tuer
                  // 1. On marque que le pouvoir a été utilisé (pour le succès "Clean Hands")
                  widget.player.timeMasterUsedPower = true;

                  // 2. On sauvegarde la liste des noms des cibles dans le profil du joueur.
                  widget.player.timeMasterTargets = _selectedTargets.map((p) => p.name).toList();

                  // 3. On envoie l'action pour fermer l'écran
                  widget.onAction("KILL", _selectedTargets);
                }
              },
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}