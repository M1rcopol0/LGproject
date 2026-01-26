import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';

class DevinInterface extends StatefulWidget {
  final Player devin;
  final List<Player> allPlayers;
  // Le callback renvoie le joueur choisi pour le focus.
  final Function(Player selected) onNext;

  const DevinInterface({
    super.key,
    required this.devin,
    required this.allPlayers,
    required this.onNext,
  });

  @override
  State<DevinInterface> createState() => _DevinInterfaceState();
}

class _DevinInterfaceState extends State<DevinInterface> {
  bool _isChangingTarget = false;

  @override
  Widget build(BuildContext context) {
    // 1. Vérifier si une cible est déjà en cours et vivante
    Player? currentTarget;
    try {
      if (widget.devin.concentrationTargetName != null) {
        currentTarget = widget.allPlayers.firstWhere(
              (p) => p.name == widget.devin.concentrationTargetName && p.isAlive,
        );
      }
    } catch (e) {
      currentTarget = null;
    }

    // CAS 1 : Déjà focus sur quelqu'un vivant, et pas en train de changer
    if (currentTarget != null && !_isChangingTarget) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, size: 80, color: Colors.purpleAccent),
            const SizedBox(height: 20),
            Text(
              "CONCENTRATION EN COURS",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              formatPlayerName(currentTarget.name),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Nuit ${widget.devin.concentrationNights + 1} / 2", // +1 car on est dans la nuit courante
              style: const TextStyle(color: Colors.purpleAccent, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),

            // Si on a déjà passé au moins 1 nuit (donc on est à l'aube de la 2ème validation), on peut révéler
            if (widget.devin.concentrationNights >= 1) ...[
              SizedBox(
                width: 280,
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    debugPrint("👁️ LOG [Devin] : Révélation du rôle de ${currentTarget!.name}.");
                    _revealRoleAndFinish(context, currentTarget);
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("RÉVÉLER LE RÔLE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              // Sinon, on doit continuer (valider la 2ème nuit)
              SizedBox(
                width: 280,
                height: 60,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => widget.onNext(currentTarget!),
                  icon: const Icon(Icons.hourglass_bottom, color: Colors.white),
                  label: const Text("CONTINUER L'OBSERVATION", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // BOUTON CHANGER
            TextButton.icon(
              onPressed: () {
                debugPrint("👁️ LOG [Devin] : Abandon de l'observation sur ${currentTarget!.name}.");
                setState(() {
                  _isChangingTarget = true;
                });
              },
              icon: const Icon(Icons.refresh, color: Colors.white54),
              label: const Text("CHANGER DE CIBLE (RESET)", style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );
    }

    // CAS 2 : Pas de cible ou choix de changer -> Liste des joueurs
    List<Player> targets = widget.allPlayers
        .where((p) => p.isAlive && p != widget.devin)
        .toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Choisissez un joueur à observer.\n(Nécessite 2 nuits consécutives)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: targets.length,
            itemBuilder: (context, i) {
              final p = targets[i];
              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.person_search, color: Colors.purpleAccent),
                  title: Text(formatPlayerName(p.name), style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    debugPrint("👁️ LOG [Devin] : Nouvelle cible choisie : ${p.name} (Nuit 1/2)");
                    widget.onNext(p);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Affiche le rôle découvert, met à jour les stats et reset le compteur
  void _revealRoleAndFinish(BuildContext context, Player target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Vision de la Devin", style: TextStyle(color: Colors.purpleAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatPlayerName(target.name).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("est en réalité :", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 15),
            Text(
              target.role?.toUpperCase() ?? "INCONNU",
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {
                // --- 1. TRACKING SUCCÈS ---
                widget.devin.devinRevealsCount++; // Incrémente le nombre de révélations totales

                // Vérification pour le succès "Double Check" (révéler 2 fois le même)
                if (widget.devin.revealedPlayersHistory.contains(target.name)) {
                  widget.devin.hasRevealedSamePlayerTwice = true;
                  debugPrint("👁️ LOG [Devin] : SUCCÈS 'Double Check' validé !");
                }
                widget.devin.revealedPlayersHistory.add(target.name);

                // --- 2. RESET DU CYCLE ---
                // On met la cible à null manuellement.
                // Cela force le Dispatcher à considérer l'appel suivant comme une NOUVELLE cible (Nuit 1)
                // car (null != target.name) -> reset à 1.
                widget.devin.concentrationTargetName = null;
                widget.devin.concentrationNights = 0;

                Navigator.pop(ctx);

                // --- 3. NAVIGATION ---
                // On passe la main au Dispatcher.
                // Comme on a reset la variable juste avant, le dispatcher va initialiser un nouveau cycle (Nuit 1)
                // sur la cible, ou simplement passer au joueur suivant si la nuit est finie.
                widget.onNext(target);
              },
              child: const Text("BIEN REÇU", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}