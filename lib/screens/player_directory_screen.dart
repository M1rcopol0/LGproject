import 'package:flutter/material.dart';
import '../player_storage.dart';
import '../globals.dart'; // pour globalPlayers si besoin de refresh instantané

class PlayerDirectoryScreen extends StatefulWidget {
  const PlayerDirectoryScreen({super.key});

  @override
  State<PlayerDirectoryScreen> createState() => _PlayerDirectoryScreenState();
}

class _PlayerDirectoryScreenState extends State<PlayerDirectoryScreen> {
  Map<String, dynamic> _directory = {};
  bool _isLoading = true;
  List<String> _filteredNames = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    final data = await PlayerDirectory.getDirectory();
    setState(() {
      _directory = data;
      _isLoading = false;
      _filterList();
    });
  }

  void _filterList() {
    String query = _searchCtrl.text.toLowerCase();
    List<String> names = _directory.keys.toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (query.isEmpty) {
      _filteredNames = names;
    } else {
      _filteredNames = names.where((name) => name.toLowerCase().contains(query)).toList();
    }
  }

  void _showEditDialog(String originalName) {
    String? currentPhone = _directory[originalName]['phoneNumber'];
    TextEditingController nameCtrl = TextEditingController(text: originalName);
    TextEditingController phoneCtrl = TextEditingController(text: currentPhone ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: const Text("Modifier le profil", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Nom", labelStyle: TextStyle(color: Colors.white54), prefixIcon: Icon(Icons.person, color: Colors.blueAccent)),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Téléphone", labelStyle: TextStyle(color: Colors.white54), prefixIcon: Icon(Icons.phone, color: Colors.greenAccent), hintText: "+336...", hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              String newName = nameCtrl.text.trim();
              String newPhone = phoneCtrl.text.trim();
              if (newName.isEmpty) return;

              await PlayerDirectory.updatePlayerProfile(originalName, newName, newPhone.isEmpty ? null : newPhone);
              await _loadDirectory(); // Recharger l'UI

              // Petit hack : Si on est dans le lobby, faudrait refresh globalPlayers,
              // mais au prochain restart ce sera bon grâce à _updateLegacyList

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("SAUVEGARDER", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(title: const Text("Annuaire des Joueurs"), backgroundColor: const Color(0xFF1D1E33)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _filterList()),
              decoration: InputDecoration(
                hintText: "Rechercher...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _filteredNames.isEmpty
                ? const Center(child: Text("Aucun joueur trouvé", style: TextStyle(color: Colors.white38)))
                : ListView.builder(
              itemCount: _filteredNames.length,
              itemBuilder: (context, index) {
                String name = _filteredNames[index];

                // Lecture sécurisée des données
                var playerData = _directory[name];
                String? phone;

                if (playerData != null) {
                  // phoneNumber peut être null, String, ou parfois int par erreur
                  var phoneValue = playerData['phoneNumber'];
                  if (phoneValue != null) {
                    phone = phoneValue.toString();
                  }
                }

                return Card(
                  color: const Color(0xFF1D1E33),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.blueGrey, child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: phone != null && phone.isNotEmpty
                        ? Row(children: [const Icon(Icons.phone, size: 14, color: Colors.greenAccent), const SizedBox(width: 6), Text(phone, style: const TextStyle(color: Colors.greenAccent, fontSize: 13))])
                        : const Text("Aucun numéro", style: TextStyle(color: Colors.white24, fontSize: 12)),
                    trailing: const Icon(Icons.edit, color: Colors.blueAccent),
                    onTap: () => _showEditDialog(name),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}