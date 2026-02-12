import 'package:flutter/material.dart';
import 'package:fluffer/models/player.dart';
import 'target_selector_interface.dart';

class VoyageurInterface extends StatefulWidget {
  final Player actor;
  final List<Player> allPlayers;
  final VoidCallback onDepart;
  final VoidCallback onReturnWithoutShooting;
  final VoidCallback onStayTraveling;
  final VoidCallback onStayAtVillage;
  final Function(Player) onShoot;

  const VoyageurInterface({
    super.key,
    required this.actor,
    required this.allPlayers,
    required this.onDepart,
    required this.onReturnWithoutShooting,
    required this.onStayTraveling,
    required this.onStayAtVillage,
    required this.onShoot,
  });

  @override
  State<VoyageurInterface> createState() => _VoyageurInterfaceState();
}

class _VoyageurInterfaceState extends State<VoyageurInterface> {
  bool _showKillSelector = false;

  @override
  Widget build(BuildContext context) {
    bool isTraveling = widget.actor.isInTravel;
    bool canTravel = widget.actor.canTravelAgain;

    // --- MODE SÉLECTEUR DE CIBLE (Si on a cliqué sur "Rentrer en tuant") ---
    if (_showKillSelector) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("CHOISISSEZ VOTRE VICTIME", style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TargetSelectorInterface(
              players: widget.allPlayers.where((p) => p.isAlive && p != widget.actor).toList(),
              maxTargets: 1,
              isProtective: false,
              onTargetsSelected: (selected) {
                if (selected.isNotEmpty) {
                  widget.onShoot(selected.first);
                } else {
                  setState(() => _showKillSelector = false); // Retour menu
                }
              },
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showKillSelector = false),
            child: const Text("ANNULER LE TIR", style: TextStyle(color: Colors.white54)),
          )
        ],
      );
    }

    // --- MENU PRINCIPAL ---
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isTraveling ? Icons.flight_takeoff : Icons.home, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 20),
          Text(isTraveling ? "ÉTAT : EN VOYAGE" : "ÉTAT : AU VILLAGE", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text("Munitions : ${widget.actor.travelerBullets}", style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 40),

          if (isTraveling) ...[
            _btn(Icons.timelapse, "CONTINUER LE VOYAGE", Colors.blueGrey, () {
              debugPrint("🎭 CAPTEUR [Action] : Voyageur continue le voyage.");
              widget.onStayTraveling();
            }),
            const SizedBox(height: 10),
            _btn(Icons.home, "RENTRER (PACIFIQUE)", Colors.green, () {
              debugPrint("🎭 CAPTEUR [Action] : Voyageur retour pacifique.");
              widget.onReturnWithoutShooting();
            }),
            const SizedBox(height: 10),
            if (widget.actor.travelerBullets > 0)
              _btn(Icons.gps_fixed, "RENTRER EN TUANT...", Colors.redAccent, () {
                debugPrint("🎭 CAPTEUR [Action] : Voyageur prépare un tir. Munitions: ${widget.actor.travelerBullets}.");
                setState(() => _showKillSelector = true);
              }),
          ] else ...[
            if (canTravel) ...[
              _btn(Icons.flight, "PARTIR EN VOYAGE", Colors.blueAccent, () {
                debugPrint("🎭 CAPTEUR [Action] : Voyageur part en voyage.");
                widget.onDepart();
              }),
              const SizedBox(height: 10),
              _btn(Icons.bed, "RESTER AU VILLAGE", Colors.grey, widget.onStayAtVillage),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Vous êtes rentré définitivement.", style: TextStyle(color: Colors.orange)),
              ),
              _btn(Icons.bed, "PASSER LA NUIT", Colors.grey, widget.onStayAtVillage),
            ]
          ],
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, Color col, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: col, minimumSize: const Size(250, 50)),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}