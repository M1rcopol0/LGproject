import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'target_selector_interface.dart';

class VoyageurInterface extends StatefulWidget {
  final Player actor;
  final List<Player> allPlayers; // Nécessaire pour choisir une cible
  final VoidCallback onStayAtVillage;
  final VoidCallback onDepart;
  final VoidCallback onReturnWithoutShooting; // Rentrer sans tirer (ou pas de balles)
  final VoidCallback onStayTraveling;
  final Function(Player target) onShoot; // Nouveau callback pour le tir

  const VoyageurInterface({
    super.key,
    required this.actor,
    required this.allPlayers,
    required this.onStayAtVillage,
    required this.onDepart,
    required this.onReturnWithoutShooting,
    required this.onStayTraveling,
    required this.onShoot,
  });

  @override
  State<VoyageurInterface> createState() => _VoyageurInterfaceState();
}

class _VoyageurInterfaceState extends State<VoyageurInterface> {
  bool _isAiming = false; // État local : est-on en train de choisir une cible ?

  @override
  void initState() {
    super.initState();
    debugPrint("✈️ LOG [Voyageur] : ${widget.actor.name} accède à l'interface.");
    debugPrint("✈️ État : ${widget.actor.isInTravel ? 'EN VOYAGE' : 'AU VILLAGE'} | Munitions : ${widget.actor.travelerBullets}");
  }

  @override
  Widget build(BuildContext context) {
    // Si le joueur a cliqué sur "Tirer", on affiche le sélecteur
    if (_isAiming) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              "CHOISISSEZ VOTRE CIBLE",
              style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(
              "Une balle sera consommée.",
              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ),
          Expanded(
            child: TargetSelectorInterface(
              players: widget.allPlayers.where((p) => p.isAlive && p != widget.actor).toList(),
              maxTargets: 1,
              onTargetsSelected: (selected) {
                if (selected.isNotEmpty) {
                  debugPrint("✈️🔫 LOG [Voyageur] : Tir confirmé sur ${selected.first.name}");
                  widget.onShoot(selected.first);
                }
              },
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text("RETOUR AU MENU", style: TextStyle(color: Colors.white)),
            onPressed: () => setState(() => _isAiming = false),
          )
        ],
      );
    }

    // Sinon, on affiche le menu classique
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.actor.isInTravel ? Icons.flight_takeoff : Icons.home,
            size: 80,
            color: widget.actor.isInTravel ? Colors.cyanAccent : Colors.greenAccent,
          ),
          const SizedBox(height: 20),
          Text(
            widget.actor.isInTravel ? "VOUS ÊTES EN VOYAGE" : "VOUS ÊTES AU VILLAGE",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            "Munitions disponibles : ${widget.actor.travelerBullets}",
            style: TextStyle(
                color: widget.actor.travelerBullets > 0 ? Colors.redAccent : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 40),

          // --- BOUTONS SELON L'ÉTAT ---
          if (!widget.actor.isInTravel) ...[
            // CAS 1 : AU VILLAGE
            _buildChoiceBtn("PARTIR EN VOYAGE", Colors.deepPurple, () {
              debugPrint("✈️ LOG [Voyageur] : Départ vers l'inconnu.");
              widget.onDepart();
            }),
            const SizedBox(height: 15),

            // Si on a des balles au village, on peut tirer
            if (widget.actor.travelerBullets > 0)
              _buildChoiceBtn("TIRER UNE BALLE", Colors.red.shade800, () {
                setState(() => _isAiming = true);
              }),

            const SizedBox(height: 15),
            _buildChoiceBtn("RESTER CALME", Colors.blueGrey, () {
              debugPrint("🏠 LOG [Voyageur] : Reste au village sans rien faire.");
              widget.onStayAtVillage();
            }),
          ] else ...[
            // CAS 2 : EN VOYAGE
            if (widget.actor.travelerBullets > 0)
              _buildChoiceBtn("RENTRER ET TIRER", Colors.redAccent, () {
                // Rentrer et tirer : on ouvre le viseur
                // L'action de retour se fera implicitement après le tir dans le Dispatcher
                setState(() => _isAiming = true);
              }),

            const SizedBox(height: 15),
            _buildChoiceBtn(
                widget.actor.travelerBullets > 0 ? "RENTRER SANS TIRER" : "RENTRER AU VILLAGE",
                Colors.green,
                    () {
                  debugPrint("🏠 LOG [Voyageur] : Retour simple au bercail.");
                  widget.onReturnWithoutShooting();
                }
            ),
            const SizedBox(height: 15),
            _buildChoiceBtn("RESTER EN VOYAGE", Colors.cyan.withOpacity(0.5), () {
              debugPrint("✈️ LOG [Voyageur] : Poursuite du voyage.");
              widget.onStayTraveling();
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 260,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 8,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}