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
import 'achievement_logic.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    hasVotedThisTurn = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGameStateIntegrity();
    });
  }

  void _recoverActivePlayers() {
    if (globalRolesDistributed) {
      for (var p in widget.players) {
        if (p.role != null && p.role!.isNotEmpty) {
          p.isPlaying = true;
        }
      }
    }
  }

  List<Player> get _activePlayers => widget.players.where((p) => p.isPlaying).toList();

  // ==========================================================
  // MENU DEV / ADMINISTRATION MJ
  // ==========================================================

  void _showPlayerAdminMenu(Player p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1E33),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.name.toUpperCase(),
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(p.role?.toUpperCase() ?? "SANS RÔLE",
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const Divider(color: Colors.white10, height: 30),

            // 1. TUER / RESSUSCITER
            ListTile(
              leading: Icon(p.isAlive ? Icons.dangerous : Icons.favorite, color: p.isAlive ? Colors.redAccent : Colors.greenAccent),
              title: Text(p.isAlive ? "ÉLIMINER LE JOUEUR" : "RESSUSCITER LE JOUEUR", style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                if (p.isAlive) {
                  _executeManualElimination(p);
                } else {
                  _executeManualResurrection(p);
                }
              },
            ),

            // 2. APPLIQUER EFFET
            ListTile(
              leading: const Icon(Icons.auto_fix_high, color: Colors.blueAccent),
              title: const Text("APPLIQUER UN EFFET / ÉTAT", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showEffectsMenu(p);
              },
            ),

            // 3. NOMMER CHEF
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text("NOMMER CHEF DU VILLAGE", style: TextStyle(color: Colors.white)),
              onTap: () {
                debugPrint("👑 LOG [Chef] : Manuel - Nouveau leader -> ${p.name}");
                setState(() {
                  for (var pl in widget.players) pl.isVillageChief = false;
                  p.isVillageChief = true;
                });
                Navigator.pop(ctx);
              },
            ),

            // 4. RETOUR
            ListTile(
              leading: const Icon(Icons.arrow_back, color: Colors.white54),
              title: const Text("RETOUR AU VILLAGE", style: TextStyle(color: Colors.white54)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showEffectsMenu(Player p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E21),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          children: [
            const Text("MODIFIER LES ÉTATS", style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _effectSwitch("Dans la Maison", p.isInHouse, (v) => p.isInHouse = v),
                  _effectSwitch("Protégé (Dresseur)", p.isProtectedByPokemon, (v) => p.isProtectedByPokemon = v),
                  _effectSwitch("Endormi (Venin/Somni)", p.isEffectivelyAsleep, (v) => p.isEffectivelyAsleep = v),
                  _effectSwitch("Censuré (Muet)", p.isMutedDay, (v) => p.isMutedDay = v),
                  _effectSwitch("Immunisé Vote (Bled)", p.isImmunizedFromVote, (v) => p.isImmunizedFromVote = v),
                  _effectSwitch("Révélé (Devin)", p.isRevealedByDevin, (v) => p.isRevealedByDevin = v),
                  _effectSwitch("Marqué par Tardos (Bombe)", p.isBombed, (v) => p.isBombed = v),
                  _effectSwitch("Maudit par Pantin", p.pantinCurseTimer != null, (v) {
                    p.pantinCurseTimer = v ? 2 : null;
                  }),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text("TERMINER"),
            )
          ],
        ),
      ),
    );
  }

  Widget _effectSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: value,
      activeColor: Colors.blueAccent,
      onChanged: (v) {
        setState(() => onChanged(v));
      },
    );
  }

  // ==========================================================
  // ACTIONS TECHNIQUES
  // ==========================================================

  void _executeManualElimination(Player p) async {
    debugPrint("💀 LOG [MJ] : Élimination manuelle de ${p.name}");
    hasVotedThisTurn = true;
    Player v = GameLogic.eliminatePlayer(context, _activePlayers, p);
    setState(() {});
    playSfx("cloche.mp3");
    await _showDeathResultDialog(v);
    _checkGameStateIntegrity();
  }

  void _executeManualResurrection(Player p) {
    debugPrint("✨ LOG [MJ] : Résurrection de ${p.name}");
    setState(() {
      p.isAlive = true;
      p.isEffectivelyAsleep = false;
      p.hasBeenHitByDart = false;
      if (p.role?.toLowerCase() == "maison") p.isHouseDestroyed = false;
    });
    playSfx("magic_sparkle.mp3");
    _checkGameStateIntegrity();
  }

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
    if (globalTurnNumber <= 1 && !nightOnePassed) return;

    List<Player> winnersList = _activePlayers.where((p) =>
    (winner == "VILLAGE" && p.team == "village") ||
        (winner == "LOUPS" && p.team == "loups") ||
        (winner == "SOLO" && p.team == "solo")
    ).toList();

    // CORRECTION ICI : Ajout du paramètre 'context'
    AchievementLogic.checkEndGameAchievements(context, winnersList, widget.players);

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
                  title: Text(Player.formatName(p.name), style: const TextStyle(color: Colors.white)),
                  onTap: () {
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

  void _handlePlayerTap(Player p) {
    if (!globalRolesDistributed) {
      setState(() => p.isPlaying = !p.isPlaying);
      return;
    }
    if (!p.isPlaying) return;

    // OUVERTURE DU NOUVEAU MENU MJ
    _showPlayerAdminMenu(p);
  }

  void _goToNight({bool force = false}) {
    bool isFirstNight = (globalTurnNumber == 1 && !nightOnePassed);
    if (!force && !hasVotedThisTurn && !isFirstNight) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1D1E33),
          title: const Text("⚠️ Vote Oublié", style: TextStyle(color: Colors.redAccent)),
          content: const Text("Le village n'a pas voté ce jour."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER")),
            TextButton(onPressed: () { Navigator.pop(ctx); _goToNight(force: true); }, child: const Text("FORCER LA NUIT")),
          ],
        ),
      );
      return;
    }

    _resetTimer();
    isDayTime = false;
    playMusic("ambiance_nuit.mp3");

    Navigator.push(context, MaterialPageRoute(builder: (_) => NightActionsScreen(players: _activePlayers))).then((_) {
      setState(() {
        isDayTime = true;
        hasVotedThisTurn = false;
        _resetTimer();
        _checkGameStateIntegrity();
      });
    });
  }

  void _goToVote() async {
    _resetTimer();
    await playSfx("vote_music.mp3");
    List<Player> voters = _activePlayers.where((p) => p.isAlive).toList();
    voters.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    Navigator.push(context, MaterialPageRoute(builder: (_) => PassScreen(
        voters: voters,
        allPlayers: _activePlayers,
        index: 0,
        onComplete: () {
          hasVotedThisTurn = true;
          setState(() {
            _checkGameOver();
            if (!_isGameOverProcessing) {
              bool chiefAlive = _activePlayers.any((p) => p.isAlive && p.isVillageChief);
              if (!chiefAlive) _showChiefElectionDialog();
            }
            isDayTime = false;
            _resetTimer();
          });
        }
    )));
  }

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
          ElevatedButton(onPressed: () {
            String cleanName = currentNameInput.trim();
            if (cleanName.isNotEmpty) {
              setState(() {
                int idx = widget.players.indexWhere((p) => p.name.toLowerCase() == cleanName.toLowerCase());
                String? role = currentRoleInput.isNotEmpty ? currentRoleInput.trim() : null;
                String team = role != null ? GameLogic.getTeamForRole(role) : "village";

                if (idx != -1) {
                  widget.players[idx].isPlaying = true;
                  widget.players[idx].isAlive = true;
                  if (role != null) {
                    widget.players[idx].role = role;
                    widget.players[idx].team = team;
                    widget.players[idx].isRoleLocked = true;
                  }
                } else {
                  Player newP = Player(name: cleanName, isPlaying: true);
                  if (role != null) {
                    newP.role = role;
                    newP.team = team;
                    newP.isRoleLocked = true;
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

  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSeconds > 0) {
        setState(() => _currentSeconds--);
      } else {
        _timer?.cancel();
        setState(() => _isTimerRunning = false);
        playSfx("alarm.mp3");
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
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

  Future<void> _showDeathResultDialog(Player victim) async {
    return showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      title: const Text("MORT CONFIRMÉE", style: TextStyle(color: Colors.white)),
      content: Text("${victim.name} était ${victim.role?.toUpperCase()}.", style: const TextStyle(color: Colors.white70)),
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
                        p.buildStatusIcons(),
                      ],
                    ),
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
                      Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () => _goToNight(force: false), icon: const Icon(Icons.nights_stay), label: const Text("NUIT"))),
                    ],
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () async {
                      if (_activePlayers.length < 3) return;
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const RouletteScreen()));
                      setState(() {
                        GameLogic.assignRoles(_activePlayers);
                        globalRolesDistributed = true;
                        isDayTime = false;
                      });
                      await GameSaveService.saveGame();
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