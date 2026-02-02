import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../globals.dart';

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
  int? _generatedDestinyNumber; // Le chiffre que l'appli a généré pour ce tour

  // Enregistre l'action pour les succès et LOGS
  void _recordAction(String actionName, String details) {
    debugPrint("📖 LOG [Archiviste] : $details");
    if (!widget.actor.archivisteActionsUsed.contains(actionName)) {
      widget.actor.archivisteActionsUsed.add(actionName);
    }
  }

  // --- LOGIQUE DU DÉPÔT DU DESTIN ---
  void _generateDestinyNumber() {
    // Si on a déjà généré un chiffre pour cette session d'écran, on ne le change pas
    if (_generatedDestinyNumber != null) return;

    int maxRange = 15;
    if (widget.actor.mjNightsCount >= 2) maxRange = 3;      // 3ème nuit et +
    else if (widget.actor.mjNightsCount == 1) maxRange = 7; // 2ème nuit
    else maxRange = 15;                                     // 1ère nuit

    setState(() {
      _generatedDestinyNumber = Random().nextInt(maxRange) + 1;
    });

    debugPrint("🎲 LOG [Archiviste] : Chiffre du destin généré : $_generatedDestinyNumber (Range 1-$maxRange)");
  }

  void _handleMjSuccess() {
    _recordAction("transcendance_return", "Le MJ a trouvé le chiffre ! Retour de l'Archiviste.");
    setState(() {
      widget.actor.needsToChooseTeam = true;
    });
  }

  void _handleMjFailure() {
    widget.actor.mjNightsCount++;
    debugPrint("📖 LOG [Archiviste] : Le MJ a échoué. L'exil continue (Compteur: ${widget.actor.mjNightsCount}).");
    widget.onComplete("Le MJ n'a pas trouvé le chiffre caché. L'exil continue jusqu'à la prochaine nuit.");
  }

  void _applyTeamChoice(String team) {
    _recordAction("team_choice", "Retour au village dans l'équipe : ${team.toUpperCase()}");
    setState(() {
      widget.actor.team = team;
      widget.actor.isAwayAsMJ = false;
      widget.actor.needsToChooseTeam = false;
      widget.actor.mjNightsCount = 0; // Reset pour une future transcendance éventuelle
    });
    widget.onComplete("Vous avez choisi le camp : ${team.toUpperCase()}. Vous reviendrez au village à l'aube.");
  }

  void _startTranscendance() {
    _recordAction("transcendance_start", "Activation de la Transcendance. Départ vers l'exil MJ.");
    setState(() {
      widget.actor.isAwayAsMJ = true;
      widget.actor.hasUsedSwapMJ = true;
      widget.actor.mjNightsCount = 0; // Départ compteur
    });
    widget.onComplete("Vous quittez le village pour remplacer le MJ. Bonne chance !");
  }

  @override
  void initState() {
    super.initState();
    // Si on est en mode "Away", on génère le chiffre dès l'arrivée sur l'écran
    if (widget.actor.isAwayAsMJ && !widget.actor.needsToChooseTeam) {
      _generateDestinyNumber();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.actor.needsToChooseTeam) return _buildTeamSelectionView();
    if (widget.actor.isAwayAsMJ) return _buildDestinyView();
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
            _recordAction("scapegoat", "Arme le pouvoir Bouc Émissaire pour le prochain vote.");
            widget.actor.hasScapegoatPower = true;
            widget.actor.scapegoatUses--;
            widget.onComplete("Pouvoir Bouc Émissaire activé pour le prochain vote.");
          }),

        if (!widget.actor.hasUsedSwapMJ)
          _powerBtn("TRANSCENDANCE (DEVENIR MJ)", Icons.auto_awesome, _startTranscendance),

        const SizedBox(height: 20),
        TextButton(
            onPressed: () {
              debugPrint("📖 LOG [Archiviste] : Aucun pouvoir utilisé ce tour.");
              widget.onComplete(null);
            },
            child: const Text("PASSER MON TOUR", style: TextStyle(color: Colors.white54))
        )
      ],
    );
  }

  // NOUVELLE VUE : LE DÉFI DU MJ
  Widget _buildDestinyView() {
    int maxRange = 15;
    if (widget.actor.mjNightsCount >= 2) maxRange = 3;
    else if (widget.actor.mjNightsCount == 1) maxRange = 7;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_alt, color: Colors.amberAccent, size: 60),
            const SizedBox(height: 20),
            const Text(
                "DÉFI DU DESTIN",
                style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)
            ),
            const SizedBox(height: 10),
            Text(
              "Demandez au MJ de deviner un chiffre\nentre 1 et $maxRange.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // AFFICHAGE DU CHIFFRE SECRET
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amberAccent),
              ),
              child: Column(
                children: [
                  const Text("LE CHIFFRE EST :", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text(
                    "${_generatedDestinyNumber ?? '?'}",
                    style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BOUTONS DE RÉSOLUTION
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: _handleMjSuccess,
              icon: const Icon(Icons.check_circle, size: 30),
              label: const Text("LE MJ A DEVINÉ !", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
              onPressed: _handleMjFailure,
              icon: const Icon(Icons.close, size: 30),
              label: const Text("LE MJ A ÉCHOUÉ...", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelectionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.handshake, color: Colors.greenAccent, size: 60),
          const SizedBox(height: 10),
          const Text("RETOUR VALIDÉ !", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text("Vous reprenez votre place de joueur.\nChoisissez votre nouvelle allégeance :",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70)
            ),
          ),
          const SizedBox(height: 20),
          _teamBtn("RESTER VILLAGE", Colors.green, () => _applyTeamChoice("village")),
          _teamBtn("REJOINDRE LES LOUPS", Colors.red, () => _applyTeamChoice("loups")),
          _teamBtn("JOUER SOLO", Colors.deepPurpleAccent, () => _applyTeamChoice("solo")),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector() {
    // CORRECTION : TRI ALPHABÉTIQUE
    final list = widget.players.where((p) => p.isAlive).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
              title: Text(Player.formatName(list[i].name), style: const TextStyle(color: Colors.white)),
              onTap: () {
                if (_currentView == 'cancelVote') {
                  list[i].isVoteCancelled = true;
                  _recordAction("cancel_vote", "A annulé le vote de ${list[i].name}");
                }
                if (_currentView == 'mute') {
                  list[i].isMutedDay = true;
                  _recordAction("mute", "A censuré ${list[i].name} pour le prochain jour.");
                }
                widget.onComplete(_currentView == 'mute' ? "${list[i].name} est censuré !" : "${list[i].name} ne pourra pas voter.");
              },
            ),
          ),
        ),
        TextButton(
            onPressed: () => setState(() => _currentView = null),
            child: const Text("RETOUR", style: TextStyle(color: Colors.white38))
        )
      ],
    );
  }

  // --- WIDGETS RÉUTILISABLES ---

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
      width: 280,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: col,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        onPressed: fn,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    ),
  );
}