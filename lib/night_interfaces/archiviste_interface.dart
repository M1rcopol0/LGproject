import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../globals.dart';

class ArchivisteInterface extends StatefulWidget {
  final List<Player> players;
  final Player actor;
  final Function(String? popupMsg) onComplete;

  const ArchivisteInterface({
    super.key,
    required this.players,
    required this.actor,
    required this.onComplete
  });

  @override
  State<ArchivisteInterface> createState() => _ArchivisteInterfaceState();
}

class _ArchivisteInterfaceState extends State<ArchivisteInterface> {
  String? _currentView;

  // Enregistre l'action pour les succès
  void _recordAction(String actionName) {
    if (!widget.actor.archivisteActionsUsed.contains(actionName)) {
      widget.actor.archivisteActionsUsed.add(actionName);
    }
  }

  // --- LOGIQUE DU DÉPÔT DU DESTIN ---
  void _consultDestiny() {
    widget.actor.mjNightsCount++;
    _recordAction("transcendance_return");

    int chance = (widget.actor.mjNightsCount == 1) ? 15
        : (widget.actor.mjNightsCount == 2) ? 7 : 3;

    int roll = Random().nextInt(chance) + 1;

    if (roll == 1) {
      setState(() {
        widget.actor.needsToChooseTeam = true;
      });
    } else {
      widget.onComplete("Le destin vous maintient dans l'ombre (Roll: $roll/$chance). L'exil continue.");
    }
  }

  void _applyTeamChoice(String team) {
    setState(() {
      widget.actor.team = team;
      widget.actor.isAwayAsMJ = false;
      widget.actor.needsToChooseTeam = false;
    });
    widget.onComplete("Vous avez choisi le camp : ${team.toUpperCase()}. Vous reviendrez au village à l'aube.");
  }

  void _startTranscendance() {
    _recordAction("transcendance_start");
    setState(() {
      widget.actor.isAwayAsMJ = true;
      widget.actor.hasUsedSwapMJ = true;
      widget.actor.mjNightsCount = 0;
    });
    widget.onComplete("Vous quittez le village. Le dé de retour pourra être lancé dès la nuit prochaine.");
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actor.needsToChooseTeam) return _buildTeamSelectionView();
    if (widget.actor.isAwayAsMJ) return _buildAwayView();
    if (_currentView != null) return _buildPlayerSelector();

    return _buildMainPowerMenu();
  }

  // --- VUES ---

  Widget _buildMainPowerMenu() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _powerBtn("ANNULER UN VOTE", Icons.block, () => setState(() => _currentView = 'cancelVote')),
        _powerBtn("CENSURER UN JOUEUR", Icons.mic_off, () => setState(() => _currentView = 'mute')),

        if (widget.actor.scapegoatUses > 0)
          _powerBtn("BOUC ÉMISSAIRE (${widget.actor.scapegoatUses})", Icons.keyboard_return, () {
            _recordAction("scapegoat");
            widget.actor.hasScapegoatPower = true;
            widget.actor.scapegoatUses--;
            widget.onComplete("Pouvoir Bouc Émissaire activé pour le prochain vote.");
          }),

        if (!widget.actor.hasUsedSwapMJ)
          _powerBtn("TRANSCENDANCE (DEVENIR MJ)", Icons.auto_awesome, _startTranscendance),

        const SizedBox(height: 20),
        TextButton(
            onPressed: () => widget.onComplete(null),
            child: const Text("PASSER MON TOUR", style: TextStyle(color: Colors.white54))
        )
      ],
    );
  }

  Widget _buildAwayView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_motion, color: Colors.amberAccent, size: 60),
          const SizedBox(height: 20),
          const Text("VOUS ÊTES LE MAÎTRE DU JEU", style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Le village ne vous voit plus. Sollicitez le destin pour tenter de revenir parmi les mortels.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
          _actionBtn("CONSULTER LE DESTIN", Colors.indigo, _consultDestiny),
        ],
      ),
    );
  }

  Widget _buildTeamSelectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 60),
          const SizedBox(height: 10),
          const Text("DICE ROLL RÉUSSI !", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          _teamBtn("VILLAGE", Colors.green, () => _applyTeamChoice("village")),
          _teamBtn("LOUPS-GAROUS", Colors.red, () => _applyTeamChoice("loups")),
          _teamBtn("SOLO", Colors.deepPurpleAccent, () => _applyTeamChoice("solo")),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector() {
    final list = widget.players.where((p) => p.isAlive).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _currentView == 'cancelVote' ? "ANNULER LE VOTE DE :" : "CENSURER :",
            style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(formatPlayerName(list[i].name), style: const TextStyle(color: Colors.white)),
              onTap: () {
                if (_currentView == 'cancelVote') {
                  list[i].isVoteCancelled = true;
                  _recordAction("cancel_vote");
                }
                if (_currentView == 'mute') {
                  list[i].isMutedDay = true;
                  _recordAction("mute");
                }
                widget.onComplete(_currentView == 'mute' ? "${list[i].name} est censuré !" : "${list[i].name} ne pourra pas voter.");
              },
            ),
          ),
        ),
        TextButton(onPressed: () => setState(() => _currentView = null), child: const Text("RETOUR"))
      ],
    );
  }

  // --- WIDGETS REUTILISABLES ---

  Widget _powerBtn(String text, IconData icon, VoidCallback onTap) => Card(
    color: Colors.white10,
    margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
    child: ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: onTap,
    ),
  );

  Widget _teamBtn(String text, Color col, VoidCallback fn) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: SizedBox(
      width: 250,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: col),
        onPressed: fn,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    ),
  );

  Widget _actionBtn(String text, Color col, VoidCallback fn) => ElevatedButton(
    style: ElevatedButton.styleFrom(
        backgroundColor: col,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
    ),
    onPressed: fn,
    child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );
}