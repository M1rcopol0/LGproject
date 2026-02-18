import 'dart:math';
import 'package:flutter/material.dart';
import '../globals.dart';

class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> roles = [
    {"name": "MAIRE", "color": Colors.blueAccent},
    {"name": "ROI", "color": Colors.orangeAccent},
    {"name": "DICTATEUR", "color": Colors.redAccent},
  ];

  String result = "";
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentRotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _calculateResult();
      }
    });
  }

  void _calculateResult() async {
    if (result.isNotEmpty) return;

    double angleFinal = _currentRotation % (2 * pi);
    double sectorAngle = (2 * pi) / roles.length;
    int index = (((2 * pi - angleFinal) % (2 * pi)) / sectorAngle).floor();

    String finalName = roles[index % roles.length]["name"];

    setState(() {
      result = finalName;
      // --- CORRECTION : MISE À JOUR GLOBALE ---
      globalGovernanceMode = finalName; // Met à jour le mode pour GameLogic
    });

    debugPrint("👑 LOG [Roulette] : Nouveau mode de gouvernance -> $globalGovernanceMode");

    if (finalName == "MAIRE") await playSfx("maire.mp3");
    else if (finalName == "ROI") await playSfx("roi.mp3");
    else if (finalName == "DICTATEUR") await playSfx("dictateur.mp3");
  }

  void _skipAnimation() {
    if (_controller.isAnimating && result.isEmpty) {
      _controller.stop();
      _calculateResult();
    }
  }

  void spin() async {
    setState(() {
      result = "";
      _currentRotation += (pi * 2 * (12 + Random().nextInt(5))) + (Random().nextDouble() * pi * 2);
    });

    await playSfx("roulette.mp3");

    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text("ROULETTE DES POUVOIRS"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_drop_down, size: 60, color: Colors.orange),

            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                double rotationValue = _controller.isAnimating
                    ? _animation.value * _currentRotation
                    : _currentRotation;
                return Transform.rotate(
                  angle: rotationValue,
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(300, 300),
                painter: RoulettePainter(roles: roles),
              ),
            ),
            const SizedBox(height: 40),

            if (result.isEmpty) ...[
              ElevatedButton(
                onPressed: _controller.isAnimating ? null : spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  _controller.isAnimating ? "TIRAGE EN COURS..." : "LANCER LA ROUE",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (_controller.isAnimating) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _skipAnimation,
                  icon: const Icon(Icons.fast_forward, color: Colors.white70),
                  label: const Text("PASSER L'ANIMATION", style: TextStyle(color: Colors.white70)),
                ),
              ],
            ],

            if (result.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orangeAccent, width: 2),
                ),
                child: Text(
                  "LE VILLAGE A UN : $result",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("OK", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RoulettePainter extends CustomPainter {
  final List<Map<String, dynamic>> roles;
  RoulettePainter({required this.roles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sectorAngle = (2 * pi) / roles.length;

    for (int i = 0; i < roles.length; i++) {
      final paint = Paint()..color = roles[i]["color"]..style = PaintingStyle.fill;
      double startAngle = (i * sectorAngle) - (pi / 2);
      canvas.drawArc(rect, startAngle, sectorAngle, true, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: roles[i]["name"],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      double textAngle = startAngle + (sectorAngle / 2);
      final x = center.dx + (radius * 0.65) * cos(textAngle);
      final y = center.dy + (radius * 0.65) * sin(textAngle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(textAngle + (pi / 2));
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    canvas.drawCircle(center, 12, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}