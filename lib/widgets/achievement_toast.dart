import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementToast extends StatefulWidget {
  final Achievement achievement;
  final String playerName; // Ajout du nom du joueur
  final VoidCallback onDismiss;

  const AchievementToast({
    super.key,
    required this.achievement,
    required this.playerName,
    required this.onDismiss,
  });

  // Méthode statique mise à jour pour prendre le playerName
  static void show(BuildContext context, Achievement achievement, String playerName) {
    debugPrint("🔔 LOG [Toast] : Affichage pour ${achievement.title} -> $playerName");

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AchievementToast(
            achievement: achievement,
            playerName: playerName,
            onDismiss: () {
              if (overlayEntry.mounted) {
                overlayEntry.remove();
              }
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  State<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<AchievementToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color rarityColor = widget.achievement.color;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: rarityColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: rarityColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rarityColor.withOpacity(0.1),
                ),
                child: Text(
                  widget.achievement.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 15),
              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Affichage du nom du joueur en majuscules
                    Text(
                      "SUCCÈS DÉBLOQUÉ PAR ${widget.playerName.toUpperCase()}",
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.achievement.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.achievement.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}