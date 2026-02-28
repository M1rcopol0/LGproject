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
  final Function(Player) onVillageShoot;

  const VoyageurInterface({
    super.key,
    required this.actor,
    required this.allPlayers,
    required this.onDepart,
    required this.onReturnWithoutShooting,
    required this.onStayTraveling,
    required this.onStayAtVillage,
    required this.onShoot,
    required this.onVillageShoot,
  });

  @override
  State<VoyageurInterface> createState() => _VoyageurInterfaceState();
}

class _VoyageurInterfaceState extends State<VoyageurInterface> {
  bool _showKillSelector = false;
  bool _isVillageShot = false;

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
                  if (_isVillageShot) {
                    widget.onVillageShoot(selected.first);
                  } else {
                    widget.onShoot(selected.first);
                  }
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
          Text(
            isTraveling
              ? "Munitions accumulées : ${widget.actor.travelerBullets}"
              : !canTravel && widget.actor.travelerBullets > 0
                ? "⚡ ${widget.actor.travelerBullets} munition${widget.actor.travelerBullets > 1 ? 's' : ''} disponible${widget.actor.travelerBullets > 1 ? 's' : ''} ce soir"
                : !canTravel
                  ? "Aucune munition restante"
                  : "Munitions : ${widget.actor.travelerBullets}",
            style: TextStyle(
              color: !canTravel && widget.actor.travelerBullets > 0
                ? Colors.orangeAccent
                : Colors.white70,
              fontWeight: !canTravel && widget.actor.travelerBullets > 0
                ? FontWeight.bold
                : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 40),

          if (isTraveling) ...[
            _btn(Icons.timelapse, "RESTER EN VOYAGE", Colors.blueGrey, () {
              debugPrint("🎭 CAPTEUR [Action] : Voyageur continue le voyage.");
              widget.onStayTraveling();
            }),
            const SizedBox(height: 10),
            _btn(Icons.home, "RENTRER", widget.actor.travelerBullets > 0 ? Colors.redAccent : Colors.green, () {
              if (widget.actor.travelerBullets > 0) {
                debugPrint("🎭 CAPTEUR [Action] : Voyageur rentre en tuant. Munitions: ${widget.actor.travelerBullets}.");
                setState(() { _showKillSelector = true; _isVillageShot = false; });
              } else {
                debugPrint("🎭 CAPTEUR [Action] : Voyageur retour pacifique (0 munitions).");
                widget.onReturnWithoutShooting();
              }
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
              if (widget.actor.travelerBullets > 0) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 16.0),
                  child: Text("Utilisez vos munitions restantes !", style: TextStyle(color: Colors.redAccent)),
                ),
                _btn(Icons.gps_fixed, "TIRER SUR QUELQU'UN", Colors.redAccent, () {
                  debugPrint("🎭 CAPTEUR [Action] : Voyageur utilise une munition au village. Munitions: ${widget.actor.travelerBullets}.");
                  setState(() { _showKillSelector = true; _isVillageShot = true; });
                }),
              ] else ...[
                _btn(Icons.bed, "PASSER LA NUIT", Colors.grey, widget.onStayAtVillage),
              ]
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