import 'dart:io'; // Pour File
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart'; // Pour le dossier temporaire
import 'package:share_plus/share_plus.dart'; // Pour envoyer le fichier
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart'; // Pour récupérer l'historique

// IMPORTS JEU
import 'pick_ban_screen.dart';
import '../globals.dart';
import '../services/backup_service.dart';
import '../services/trophy_service.dart';
import '../models/player.dart';
import '../services/cloud_service.dart'; // Nécessaire pour forceUploadData

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _volume = 1.0;
  bool _autoCloudSync = false;
  // Variable locale pour l'état du switch SMS
  bool _smsAutoEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('app_volume') ?? 1.0;
      _autoCloudSync = prefs.getBool('auto_cloud_sync') ?? false;
      // Chargement du réglage SMS (par défaut : true)
      _smsAutoEnabled = prefs.getBool('cfg_sms_auto_send') ?? true;
    });
  }

  Future<void> _setVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('app_volume', value);
    setState(() {
      _volume = value;
      globalVolume = value;
    });
  }

  Future<void> _setAutoCloud(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_cloud_sync', value);
    setState(() {
      _autoCloudSync = value;
    });
  }

  // --- NOUVELLE FONCTION POUR LE SWITCH SMS ---
  Future<void> _setSmsAuto(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cfg_sms_auto_send', value);
    setState(() {
      _smsAutoEnabled = value;
    });
  }

  // ===========================================================================
  // 1. LOGIQUE D'EXPORTATION DES LOGS
  // ===========================================================================
  Future<void> _generateAndSendLogs() async {
    try {
      StringBuffer sb = StringBuffer();
      sb.writeln("=== LOUP GAROU 3.0 - RAPPORT DE BUG ===");
      sb.writeln("Date: ${DateTime.now()}");
      sb.writeln("Version: $globalGameVersion");
      sb.writeln("\n--------------------------------------------------\n");

      final history = globalTalker.history;

      if (history.isEmpty) {
        sb.writeln("Aucun log enregistré en mémoire.");
      } else {
        for (var log in history) {
          sb.writeln(log.generateTextMessage());
        }
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/debug_logs_lg3.txt');

      await file.writeAsString(sb.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'Rapport Bug Loup Garou 3.0');

    } catch (e) {
      debugPrint("Erreur lors de l'export des logs: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de la création du rapport de bug."), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ===========================================================================
  // 2. RÉINITIALISATION GLOBALE (LOCAL + CLOUD)
  // ===========================================================================
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Table rase ?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Cela supprimera TOUS les joueurs et les succès du téléphone ET du Google Sheets.\nL'action est irréversible.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ANNULER", style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_players_list');
              await TrophyService.resetAllStats();
              globalTalker.cleanHistory();
              setState(() { globalPlayers.clear(); });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nettoyage Cloud en cours...")));
                await CloudService.forceUploadData(context);
              }
            },
            child: const Text("TOUT EFFACER", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SUPPRESSION JOUEUR (LOCAL + CLOUD)
  // ===========================================================================
  void _showDeletePlayerDialog() async {
    if (globalPlayers.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Supprimer un joueur", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: globalPlayers.length,
            itemBuilder: (context, index) {
              final player = globalPlayers[index];
              return ListTile(
                title: Text(player.name, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onTap: () async {
                  Navigator.pop(ctx);

                  await TrophyService.deletePlayerStats(player.name);
                  setState(() { globalPlayers.removeAt(index); });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList('saved_players_list', globalPlayers.map((p) => p.name).toList());

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${player.name} supprimé. Mise à jour du Cloud...")));
                    await CloudService.forceUploadData(context);
                  }
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("FERMER"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("PARAMÈTRES"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- AUDIO ---
          _buildSectionTitle("Audio"),
          _buildSwitchTile(
            title: "Musique de fond",
            subtitle: "Activer la musique d'ambiance",
            icon: Icons.music_note,
            value: globalMusicEnabled,
            onChanged: (v) {
              setState(() => globalMusicEnabled = v);
              saveAudioSettings();
              if (v) playMusic('ambiance_sus.mp3'); else stopMusic();
            },
          ),
          _buildSwitchTile(
            title: "Effets sonores (SFX)",
            subtitle: "Activer les sons d'interface",
            icon: Icons.volume_up,
            value: globalSfxEnabled,
            onChanged: (v) {
              setState(() => globalSfxEnabled = v);
              saveAudioSettings();
            },
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Gameplay"),

          _buildSwitchTile(
            title: "Vote Anonyme (App)",
            subtitle: "Activé : Chaque joueur vote sur le téléphone.\nDésactivé : Vote à main levée, saisie directe.",
            icon: FontAwesomeIcons.checkToSlot,
            value: globalVoteAnonyme,
            onChanged: (val) {
              setState(() {
                globalVoteAnonyme = val;
                saveAudioSettings();
              });
            },
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("Configuration"),

          // --- NOUVEAU SWITCH SMS ---
          _buildSwitchTile(
            title: "Envoi Auto SMS",
            subtitle: "Envoie le rôle aux joueurs au début de la partie.",
            icon: Icons.sms,
            value: _smsAutoEnabled,
            onChanged: (val) => _setSmsAuto(val),
          ),
          // --------------------------

          const SizedBox(height: 10),

          // --- TIMER ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Durée du Timer :", style: TextStyle(color: Colors.white70)),
                Text("${globalTimerMinutes.toInt()} min", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Slider(
            value: globalTimerMinutes,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            activeColor: Colors.orangeAccent,
            onChanged: (v) => setState(() => globalTimerMinutes = v),
          ),

          const Divider(color: Colors.white24),

          // --- PICK & BAN ---
          ListTile(
            title: const Text("Choisir les rôles (Pick & Ban)", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.edit, color: Colors.orangeAccent),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const PickBanScreen())
            ),
          ),
          ListTile(
            title: const Text("Version du jeu", style: TextStyle(color: Colors.white)),
            subtitle: Text(globalGameVersion, style: const TextStyle(color: Colors.white38)),
            trailing: const Icon(Icons.info_outline, color: Colors.white24),
          ),

          const Divider(color: Colors.white24, height: 40),

          // --- SECTION CLOUD ---
          const Text("CLOUD (GOOGLE SHEETS)", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),

          _buildSwitchTile(
            title: "Synchro Auto",
            subtitle: "Mise à jour des stats après chaque partie",
            icon: Icons.cloud_sync,
            value: _autoCloudSync,
            onChanged: (val) => _setAutoCloud(val),
          ),

          const SizedBox(height: 10),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.2),
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(color: Colors.greenAccent),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => CloudService.synchronizeData(context),
            icon: const Icon(Icons.cloud_upload),
            label: const Text("FORCER LA SYNCHRO (Fusion)"),
          ),

          const SizedBox(height: 25),

          // --- SECTION GESTION LOCALE ---
          const Text("GESTION DONNÉES", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 15),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.2),
              foregroundColor: Colors.blueAccent,
              side: const BorderSide(color: Colors.blueAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => BackupService.exportData(context),
            icon: const Icon(Icons.upload_file),
            label: const Text("EXPORTER SAUVEGARDE JSON"),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withOpacity(0.1),
              foregroundColor: Colors.orangeAccent,
              side: const BorderSide(color: Colors.orangeAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showDeletePlayerDialog,
            icon: const Icon(Icons.person_remove),
            label: const Text("SUPPRIMER UN JOUEUR"),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showResetDialog,
            icon: const Icon(Icons.delete_forever),
            label: const Text("RÉINITIALISER TOUT (LOCAL + CLOUD)"),
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),

          // --- DEBUG ---
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.withOpacity(0.2),
              foregroundColor: Colors.tealAccent,
              side: const BorderSide(color: Colors.tealAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _generateAndSendLogs,
            icon: const Icon(Icons.bug_report),
            label: const Text("ENVOYER LOGS (DEBUG)"),
          ),

          const SizedBox(height: 10),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.withOpacity(0.2),
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => TalkerScreen(talker: globalTalker)),
            ),
            icon: const Icon(Icons.monitor_heart),
            label: const Text("OUVRIR CONSOLE LIVE"),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      color: Colors.white10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        activeColor: Colors.blueAccent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        secondary: Icon(icon, color: Colors.blueAccent, size: 28),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}