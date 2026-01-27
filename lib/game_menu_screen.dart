import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/player.dart';
import 'logic.dart';
import 'vote_screens.dart';
import 'night_actions_screen.dart';
import 'settings_screen.dart';
import 'wiki_page.dart';
import 'roulette_screen.dart';
import 'globals.dart';
import 'fin.dart';
import 'game_save_service.dart';

class GameMenuScreen extends StatefulWidget {
  final List<Player> players;
  const GameMenuScreen({super.key, required this.players});

  @override
  _GameMenuScreenState createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  Timer? _timer;
  int _currentSeconds = 0;
  bool _isTimerRunning = false;
  bool _isGameOverProcessing = false;

  @override
  void initState() {
    super.initState();
    debugPrint("📱 LOG [Menu] : Initialisation de l'écran principal.");
    _currentSeconds = (globalTimerMinutes * 60).toInt();
    _recoverActivePlayers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGameStateIntegrity();
    });
  }

  void _recoverActivePlayers() {
    if (globalRolesDistributed) {
      debugPrint("🔄 LOG [Menu] : Rôles déjà distribués. Récupération des joueurs actifs...");
      for (var p in widget.players) {
        if (p.role != null && p.role!.isNotEmpty) {
          p.isPlaying = true;
        }
      }
    }
  }

  List<Player> get _activePlayers => widget.players.where((p) => p.isPlaying).toList();

  // ==========================================================
  // LOGIQUES DE VÉRIFICATION
  // ==========================================================

  void _checkGameStateIntegrity() {
    _checkGameOver();
    if (!_isGameOverProcessing && isDayTime && nightOnePassed) {
      _checkChiefAlive();
    }
  }

  void _checkGameOver() {
    if (_isGameOverProcessing || !globalRolesDistributed) return;

    String? winner = GameLogic.checkWinner(_activePlayers);
    if (winner == null) return;

    // Pas de victoire jour 1 si la nuit n'est pas passée (sauf cas exceptionnels)
    if (globalTurnNumber <= 1 && !nightOnePassed) return;

    debugPrint("🏁 LOG [Game Over] : Victoire détectée -> $winner");
    setState(() => _isGameOverProcessing = true);
    _timer?.cancel();
    GameSaveService.clearSave();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => GameOverScreen(winnerType: winner, players: widget.players)),
          (route) => false,
    );
  }

  void _checkChiefAlive() {
    if (_isGameOverProcessing) return;
    bool chiefExists = _activePlayers.any((p) => p.isAlive && p.isVillageChief);
    if (!chiefExists) {
      debugPrint("👑 LOG [Chef] : Poste vacant. Ouverture de l'élection.");
      _showChiefElectionDialog();
    }
  }

  void _showChiefElectionDialog() {
    List<Player> eligible = _activePlayers.where((p) => p.isAlive).toList();
    if (eligible.isEmpty) return;

    eligible.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("ÉLECTION DU CHEF", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: eligible.length,
            itemBuilder: (context, i) {
              final p = eligible[i];
              return Card(
                color: Colors.white10,
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: Text(formatPlayerName(p.name), style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    debugPrint("👑 LOG [Chef] : Nouveau leader désigné -> ${p.name}");
                    setState(() {
                      for (var pl in widget.players) pl.isVillageChief = false;
                      p.isVillageChief = true;
                    });
                    Navigator.pop(ctx);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ACTIONS MJ ET NAVIGATION
  // ==========================================================

  void _handlePlayerTap(Player p) {
    if (!globalRolesDistributed) {
      // Phase de préparation : Activer/Désactiver le joueur
      debugPrint("👤 LOG [Préparation] : ${p.name} est maintenant ${!p.isPlaying ? 'ACTIF' : 'INACTIF'}");
      setState(() => p.isPlaying = !p.isPlaying);
      return;
    }

    // Phase de Jeu : Tuer / Ressusciter
    if (!p.isPlaying) return;
    if (!p.isAlive) {
      _showResurrectionConfirmation(p);
    } else {
      _showEliminationConfirmation(p);
    }
  }

  void _goToNight() {
    debugPrint("🌙 LOG [Navigation] : Passage en phase de Nuit.");
    _resetTimer();
    isDayTime = false;
    playMusic("ambiance_nuit.mp3");
    Navigator.push(context, MaterialPageRoute(builder: (_) => NightActionsScreen(players: _activePlayers))).then((_) {
      debugPrint("☀️ LOG [Navigation] : Retour de la Nuit. Début du Jour.");
      setState(() {
        isDayTime = true;
        _resetTimer();
        _checkGameStateIntegrity();
      });
    });
  }

  void _goToVote() async {
    debugPrint("🗳️ LOG [Navigation] : Ouverture de la phase de vote.");
    _resetTimer();
    await playSfx("vote_music.mp3");

    // On passe les joueurs déjà triés alphabétiquement
    List<Player> voters = _activePlayers.where((p) => p.isAlive).toList();
    voters.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    Navigator.push(context, MaterialPageRoute(builder: (_) => PassScreen(
        voters: voters,
        allPlayers: _activePlayers, // PassScreen et IndividualVoteScreen feront leur propre tri des cibles
        index: 0,
        onComplete: () {
          debugPrint("⚖️ LOG [Vote] : Clôture du vote. Vérification de la survie du Chef...");
          setState(() {
            _checkGameOver();

            if (!_isGameOverProcessing) {
              bool chiefAlive = _activePlayers.any((p) => p.isAlive && p.isVillageChief);
              if (!chiefAlive) {
                debugPrint("👑 LOG [Chef] : Le Chef a succombé au vote ! Succession immédiate.");
                _showChiefElectionDialog();
              }
            }

            isDayTime = false; // Transition cycle
            _resetTimer();
          });
        }
    )));
  }

  // ==========================================================
  // GESTION DES JOUEURS
  // ==========================================================

  void _addPlayerDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedNames = prefs.getStringList("saved_players_list") ?? [];
    List<String> allRoles = [...globalPickBan["village"]!, ...globalPickBan["loups"]!, ...globalPickBan["solo"]!];
    String currentNameInput = "";
    String currentRoleInput = "";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("NOUVEAU JOUEUR", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (text) => text.text.isEmpty ? const Iterable<String>.empty() : savedNames.where((opt) => opt.toLowerCase().startsWith(text.text.toLowerCase())),
              onSelected: (val) => currentNameInput = val,
              fieldViewBuilder: (ctx, controller, focus, onSubmitted) {
                controller.addListener(() => currentNameInput = controller.text);
                return TextField(controller: controller, focusNode: focus, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nom"));
              },
            ),
            const SizedBox(height: 10),
            Autocomplete<String>(
              optionsBuilder: (text) => text.text.isEmpty ? const Iterable<String>.empty() : allRoles.where((opt) => opt.toLowerCase().contains(text.text.toLowerCase())),
              onSelected: (val) => currentRoleInput = val,
              fieldViewBuilder: (ctx, controller, focus, onSubmitted) {
                controller.addListener(() => currentRoleInput = controller.text);
                return TextField(controller: controller, focusNode: focus, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Rôle (Optionnel)"));
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
          ElevatedButton(onPressed: () async {
            String cleanName = currentNameInput.trim();
            if (cleanName.isNotEmpty) {
              debugPrint("➕ LOG [Menu] : Ajout du joueur $cleanName");
              setState(() {
                int idx = widget.players.indexWhere((p) => p.name.toLowerCase() == cleanName.toLowerCase());
                if (idx != -1) {
                  widget.players[idx].isPlaying = true;
                  widget.players[idx].isAlive = true;
                  if (currentRoleInput.isNotEmpty) {
                    widget.players[idx].role = currentRoleInput.trim();
                    widget.players[idx].isRoleLocked = true; // Verrouillage manuel
                  }
                } else {
                  Player newP = Player(name: cleanName, isPlaying: true);
                  if (currentRoleInput.isNotEmpty) {
                    newP.role = currentRoleInput.trim();
                    newP.isRoleLocked = true; // Verrouillage manuel
                  }
                  widget.players.add(newP);
                }
                if (!savedNames.contains(cleanName)) {
                  savedNames.add(cleanName);
                  prefs.setStringList("saved_players_list", savedNames);
                }
              });
              Navigator.pop(ctx);
            }
          }, child: const Text("AJOUTER")),
        ],
      ),
    );
  }

  // ==========================================================
  // UI ET MJ HELPERS
  // ==========================================================

  void _startTimer() {
    if (_isTimerRunning) return;
    debugPrint("⏲️ LOG [Chrono] : Démarrage.");
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        setState(() => _currentSeconds--);
      } else {
        _timer?.cancel();
        setState(() => _isTimerRunning = false);
        debugPrint("⏰ LOG [Chrono] : Temps écoulé !");
        playSfx("alarm.mp3");
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    debugPrint("⏲️ LOG [Chrono] : Réinitialisation.");
    setState(() {
      _isTimerRunning = false;
      _currentSeconds = (globalTimerMinutes * 60).toInt();
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  void _showEliminationConfirmation(Player p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: Text("ÉLIMINER ${p.name.toUpperCase()} ?", style: const TextStyle(color: Colors.redAccent)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("NON")),
        ElevatedButton(onPressed: () async {
          debugPrint("💀 LOG [MJ] : Élimination manuelle de ${p.name}");
          Navigator.pop(ctx);
          Player v = GameLogic.eliminatePlayer(context, _activePlayers, p);
          setState(() {});
          playSfx("cloche.mp3");
          await _showDeathResultDialog(v);
          _checkGameStateIntegrity();
        }, child: const Text("OUI")),
      ],
    ));
  }

  void _showResurrectionConfirmation(Player p) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: Text("RESSUSCITER ${p.name.toUpperCase()} ?", style: const TextStyle(color: Colors.greenAccent)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("NON")),
        ElevatedButton(onPressed: () {
          debugPrint("✨ LOG [MJ] : Résurrection de ${p.name}");
          setState(() {
            p.isAlive = true;
            p.isEffectivelyAsleep = false;
            p.hasBeenHitByDart = false;
            if (p.role?.toLowerCase() == "maison") p.isHouseDestroyed = false;
          });
          Navigator.pop(ctx);
          playSfx("magic_sparkle.mp3");
          _checkGameStateIntegrity();
        }, child: const Text("OUI")),
      ],
    ));
  }

  Future<void> _showDeathResultDialog(Player victim) async {
    return showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: const Text("MORT CONFIRMÉE"),
      content: Text("${victim.name} était ${victim.role?.toUpperCase()}."),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Player> displayList = globalRolesDistributed ? _activePlayers : List.from(widget.players);
    displayList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(!globalRolesDistributed ? "PRÉPARATION" : (isDayTime ? "JOUR $globalTurnNumber" : "NUIT $globalTurnNumber")),
        backgroundColor: const Color(0xFF1D1E33),
        actions: [
          IconButton(icon: const Icon(Icons.casino), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen()))),
          IconButton(icon: const Icon(Icons.menu_book), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WikiPage()))),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!globalRolesDistributed) ...[
                  const Icon(Icons.groups, color: Colors.greenAccent),
                  const SizedBox(width: 10),
                  Text("${_activePlayers.length} Participants", style: const TextStyle(fontSize: 18, color: Colors.white)),
                ] else ...[
                  const Icon(Icons.timer, color: Colors.orangeAccent),
                  const SizedBox(width: 10),
                  Text(_formatTime(_currentSeconds), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(),
                  IconButton(icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow), onPressed: _isTimerRunning ? () { _timer?.cancel(); setState(() => _isTimerRunning = false); } : _startTimer),
                  IconButton(icon: const Icon(Icons.replay), onPressed: _resetTimer),
                ]
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final p = displayList[index];
                bool isDead = globalRolesDistributed && !p.isAlive;

                return Card(
                  color: isDead ? Colors.red.withOpacity(0.1) : Colors.white10,
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  child: ListTile(
                    onTap: () => _handlePlayerTap(p),
                    leading: Icon(isDead ? Icons.dangerous : Icons.person, color: isDead ? Colors.red : Colors.greenAccent),
                    title: Row(
                      children: [
                        Flexible(child: Text(p.name, style: TextStyle(color: Colors.white, decoration: isDead ? TextDecoration.lineThrough : null), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 5),
                        // --- CORRECTION : Affichage des icônes (Bombe, Œil, etc.) ---
                        p.buildStatusIcons(),
                      ],
                    ),
                    // --- CORRECTION : Affichage du rôle manuel avec cadenas ---
                    subtitle: globalRolesDistributed
                        ? Text(p.role?.toUpperCase() ?? "INCONNU", style: const TextStyle(color: Colors.white38, fontSize: 10))
                        : (p.isRoleLocked ? Text("🔒 ${p.role?.toUpperCase()}", style: const TextStyle(color: Colors.amberAccent, fontSize: 10)) : null),
                    trailing: !globalRolesDistributed ? Checkbox(value: p.isPlaying, activeColor: Colors.orangeAccent, onChanged: (v) => setState(() => p.isPlaying = v!)) : null,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFF1D1E33), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            child: Column(
              children: [
                if (globalRolesDistributed) ...[
                  Row(
                    children: [
                      Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: _goToVote, icon: const Icon(Icons.how_to_vote), label: const Text("VOTE"))),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: _goToNight, icon: const Icon(Icons.nights_stay), label: const Text("NUIT"))),
                    ],
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () async {
                      if (_activePlayers.length < 3) return;
                      debugPrint("🎮 LOG [Menu] : Démarrage du tirage des rôles.");
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen()));
                      setState(() {
                        GameLogic.assignRoles(_activePlayers);
                        globalRolesDistributed = true;
                        isDayTime = false;
                      });
                      await GameSaveService.saveGame();
                      debugPrint("💾 LOG [Menu] : Partie lancée et sauvegardée.");
                    },
                    child: const Text("LANCER LA PARTIE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(onPressed: () => _addPlayerDialog(context), icon: const Icon(Icons.add, color: Colors.orangeAccent), label: const Text("AJOUTER UN JOUEUR", style: TextStyle(color: Colors.orangeAccent))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}