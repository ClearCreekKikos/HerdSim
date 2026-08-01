import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ranch_model.dart';
import '../providers/game_provider.dart';
import 'pasture_screen.dart';

class Ranch3DPainter extends CustomPainter {
  final GameState gameState;
  final List<AnimatedGoatSprite> goatSprites;
  final AnimatedDonkeySprite? donkeySprite;

  Ranch3DPainter({
    required this.gameState,
    required this.goatSprites,
    this.donkeySprite,
  });

  // Projection math: 3D coordinates (X, Y, Z) to 2D screen coordinates (screenX, screenY)
  Offset project3D(double x, double y, double z, Size size) {
    final centerX = size.width / 2;
    // Shift slightly down to allow room for Z-height of buildings
    final centerY = size.height / 2 + 25;

    // Isometric projection:
    // screenX = (X - Y) * cos(30 degrees)
    // screenY = (X + Y) * sin(30 degrees) - Z
    // cos(30) ≈ 0.866, sin(30) = 0.5
    final screenX = centerX + (x - y) * 0.866;
    final screenY = centerY + (x + y) * 0.5 - z;
    return Offset(screenX, screenY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ranch = gameState.ranch;

    // 1. Draw Sky & Background
    final bgPaint = Paint()..color = const Color(0xFF1E293B); // Dark slate background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Weather Effects Visuals in sky
    _drawSkyEffects(canvas, size, ranch.weather);

    // 2. Draw Ground Pastures (flat at Z = 0)
    _drawPastures(canvas, size, ranch);

    // 3. Define all Z-sorted renderable items
    final List<_RenderItem> renderItems = [];

    // Add constant Farmhouse
    renderItems.add(_RenderItem(
      depth: -100.0, // x = -50, y = -50
      draw: (canvas) => _drawFarmhouse(canvas, size),
    ));

    // Add upgradeable Barn
    renderItems.add(_RenderItem(
      depth: 0.0, // x = 40, y = -40
      draw: (canvas) => _drawBarn(canvas, size, ranch.barnLevel),
    ));

    // Add Medical Station if constructed
    if (ranch.hasMedicalStation) {
      renderItems.add(_RenderItem(
        depth: -35.0, // x = -50, y = 15
        draw: (canvas) => _drawMedicalStation(canvas, size),
      ));
    }

    // Add Quarantine Pen if constructed
    if (ranch.hasQuarantinePen) {
      renderItems.add(_RenderItem(
        depth: 65.0, // x = 40, y = 25
        draw: (canvas) => _drawQuarantinePen(canvas, size),
      ));
    }

    // Add Automated Waterers if installed
    if (ranch.hasAutomatedWaterers) {
      // Pasture 1 waterer
      renderItems.add(_RenderItem(
        depth: -30.0, // x = -30, y = 0
        draw: (canvas) => _drawWaterer(canvas, size, -30, 0),
      ));
      // Pasture 2 waterer
      renderItems.add(_RenderItem(
        depth: 30.0, // x = 30, y = 0
        draw: (canvas) => _drawWaterer(canvas, size, 30, 0),
      ));
    }

    // Add Goat Billboards
    for (var sprite in goatSprites) {
      renderItems.add(_RenderItem(
        depth: sprite.x + sprite.y,
        draw: (canvas) => _drawGoatSprite(canvas, size, sprite),
      ));
    }

    // Add Guard Donkey Billboard
    if (donkeySprite != null && gameState.hasGuardDonkey) {
      renderItems.add(_RenderItem(
        depth: donkeySprite!.x + donkeySprite!.y,
        draw: (canvas) => _drawDonkeySprite(canvas, size, donkeySprite!),
      ));
    }

    // 4. Sort render items by depth (Painter's Algorithm: back to front)
    renderItems.sort((a, b) => a.depth.compareTo(b.depth));

    // 5. Draw all items
    for (var item in renderItems) {
      item.draw(canvas);
    }
  }

  // --- Drawing Subroutines ---

  void _drawSkyEffects(Canvas canvas, Size size, String weather) {
    if (weather == 'Rainy') {
      final paint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.15)
        ..strokeWidth = 1.0;
      final rand = Random(42);
      for (int i = 0; i < 40; i++) {
        double rx = rand.nextDouble() * size.width;
        double ry = rand.nextDouble() * (size.height / 2);
        canvas.drawLine(Offset(rx, ry), Offset(rx - 5, ry + 15), paint);
      }
    } else if (weather == 'Drought') {
      // Draw a parched sun glow
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.orangeAccent.withValues(alpha: 0.25),
            Colors.transparent
          ],
        ).createShader(Rect.fromCircle(center: Offset(size.width / 2, 60), radius: 80));
      canvas.drawCircle(Offset(size.width / 2, 60), 80, paint);
    } else {
      // Sunny: Draw a small glowing sun
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.yellowAccent.withValues(alpha: 0.3),
            Colors.transparent
          ],
        ).createShader(Rect.fromCircle(center: Offset(size.width / 2, 50), radius: 50));
      canvas.drawCircle(Offset(size.width / 2, 50), 50, paint);
    }
  }

  void _drawPastures(Canvas canvas, Size size, RanchState ranch) {
    // Get colors matching weather and grass levels
    Color getPastureColor(double level, String weather) {
      if (weather == 'Drought') {
        return Color.lerp(const Color(0xFF8B7355), const Color(0xFFC2A677), level / 100.0)!; // Parched brown/yellow
      }
      // Rainy/Sunny
      final baseDry = const Color(0xFF6B705C);
      final baseGreen = weather == 'Rainy' ? const Color(0xFF2D6A4F) : const Color(0xFF40916C);
      return Color.lerp(baseDry, baseGreen, level / 100.0)!;
    }

    final p1Color = getPastureColor(ranch.grassLevel1, ranch.weather);
    final p2Color = getPastureColor(ranch.grassLevel2, ranch.weather);

    // Coordinate Boundaries:
    // Pasture 1: x in [-75, 0], y in [-75, 75]
    // Pasture 2: x in [0, 75], y in [-75, 75]
    
    // Pasture 1 ground polygon
    final path1 = Path()
      ..moveTo(project3D(-75, -75, 0, size).dx, project3D(-75, -75, 0, size).dy)
      ..lineTo(project3D(0, -75, 0, size).dx, project3D(0, -75, 0, size).dy)
      ..lineTo(project3D(0, 75, 0, size).dx, project3D(0, 75, 0, size).dy)
      ..lineTo(project3D(-75, 75, 0, size).dx, project3D(-75, 75, 0, size).dy)
      ..close();

    canvas.drawPath(path1, Paint()..color = p1Color);
    canvas.drawPath(path1, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Pasture 2 ground polygon
    final path2 = Path()
      ..moveTo(project3D(0, -75, 0, size).dx, project3D(0, -75, 0, size).dy)
      ..lineTo(project3D(75, -75, 0, size).dx, project3D(75, -75, 0, size).dy)
      ..lineTo(project3D(75, 75, 0, size).dx, project3D(75, 75, 0, size).dy)
      ..lineTo(project3D(0, 75, 0, size).dx, project3D(0, 75, 0, size).dy)
      ..close();

    canvas.drawPath(path2, Paint()..color = p2Color);
    canvas.drawPath(path2, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Fence lines
    final fencePaint = Paint()
      ..color = const Color(0xFF5C4033) // Dark brown wooden fence
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw boundary fences
    final outerFence = Path()
      ..moveTo(project3D(-75, -75, 0, size).dx, project3D(-75, -75, 0, size).dy)
      ..lineTo(project3D(75, -75, 0, size).dx, project3D(75, -75, 0, size).dy)
      ..lineTo(project3D(75, 75, 0, size).dx, project3D(75, 75, 0, size).dy)
      ..lineTo(project3D(-75, 75, 0, size).dx, project3D(-75, 75, 0, size).dy)
      ..close();
    canvas.drawPath(outerFence, fencePaint);

    // Draw dividing fence between Pasture 1 and 2
    canvas.drawLine(
      project3D(0, -75, 0, size),
      project3D(0, 75, 0, size),
      fencePaint..strokeWidth = 1.5,
    );

    // Render fence posts
    final postPaint = Paint()..color = const Color(0xFF3E2723)..strokeWidth = 4;
    final postCoords = [
      Offset(-75, -75), Offset(0, -75), Offset(75, -75),
      Offset(-75, 75), Offset(0, 75), Offset(75, 75),
      Offset(-75, 0), Offset(75, 0), Offset(0, 0)
    ];
    for (var post in postCoords) {
      final base = project3D(post.dx, post.dy, 0, size);
      final top = project3D(post.dx, post.dy, 8, size); // 8 units high post
      canvas.drawLine(base, top, postPaint);
    }
  }

  void _drawFarmhouse(Canvas canvas, Size size) {
    // Farmhouse: x in [-60, -40], y in [-60, -40]
    double px = -60, py = -60, pz = 0;
    double dx = 20, dy = 20, dz = 16;
    double roofH = 10;

    // Walls
    _drawIsometricBox(
      canvas,
      size,
      px: px, py: py, pz: pz,
      dx: dx, dy: dy, dz: dz,
      wallColor: const Color(0xFFFDFBF7), // Cream white
    );

    // Roof
    _drawIsometricRoof(
      canvas,
      size,
      px: px, py: py, pz: pz + dz,
      dx: dx, dy: dy, roofHeight: roofH,
      roofColor: const Color(0xFF7A1C1C), // Deep crimson roof
    );

    // Door on front-right face (X is constant at px + dx)
    final doorBaseLeft = project3D(px + dx, py + dy/3, 0, size);
    final doorBaseRight = project3D(px + dx, py + 2*dy/3, 0, size);
    final doorTopLeft = project3D(px + dx, py + dy/3, 8, size);
    final doorTopRight = project3D(px + dx, py + 2*dy/3, 8, size);
    
    final doorPath = Path()
      ..moveTo(doorBaseLeft.dx, doorBaseLeft.dy)
      ..lineTo(doorBaseRight.dx, doorBaseRight.dy)
      ..lineTo(doorTopRight.dx, doorTopRight.dy)
      ..lineTo(doorTopLeft.dx, doorTopLeft.dy)
      ..close();
    canvas.drawPath(doorPath, Paint()..color = const Color(0xFF4E342E)); // Brown door
  }

  void _drawBarn(Canvas canvas, Size size, int level) {
    // Barn location: x in [40, 65], y in [-60, -35]
    double px = 40, py = -60, pz = 0;

    if (level == 1) {
      // Level 1: Simple open shelter
      double dx = 18, dy = 18, dz = 12;
      final postPaint = Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 3;
      
      // Draw 4 corner posts
      canvas.drawLine(project3D(px, py, 0, size), project3D(px, py, dz, size), postPaint);
      canvas.drawLine(project3D(px + dx, py, 0, size), project3D(px + dx, py, dz, size), postPaint);
      canvas.drawLine(project3D(px, py + dy, 0, size), project3D(px, py + dy, dz, size), postPaint);
      canvas.drawLine(project3D(px + dx, py + dy, 0, size), project3D(px + dx, py + dy, dz, size), postPaint);

      // Flat roof
      final roofPath = Path()
        ..moveTo(project3D(px, py, dz, size).dx, project3D(px, py, dz, size).dy)
        ..lineTo(project3D(px + dx, py, dz, size).dx, project3D(px + dx, py, dz, size).dy)
        ..lineTo(project3D(px + dx, py + dy, dz, size).dx, project3D(px + dx, py + dy, dz, size).dy)
        ..lineTo(project3D(px, py + dy, dz, size).dx, project3D(px, py + dy, dz, size).dy)
        ..close();
      canvas.drawPath(roofPath, Paint()..color = const Color(0xFF6D4C41)); // Flat brown wood roof
      return;
    }

    // Higher levels are closed 3D boxes
    double dx = 22, dy = 22, dz = 18;
    Color wallColor = const Color(0xFF795548); // Level 2: brown wood
    Color roofColor = const Color(0xFF5D4037);

    if (level >= 3) {
      // Red Barn
      dx = 25; dy = 25; dz = 22;
      wallColor = const Color(0xFFB71C1C); // Classical Red
      roofColor = const Color(0xFFECEFF1); // Slate white/grey roof
    }

    if (level == 5) {
      // Level 5: Modern ranch
      wallColor = const Color(0xFF37474F); // Modern steel blue
      roofColor = const Color(0xFF006064); // Modern teal roof
    }

    // Main Barn Walls
    _drawIsometricBox(
      canvas,
      size,
      px: px, py: py, pz: pz,
      dx: dx, dy: dy, dz: dz,
      wallColor: wallColor,
    );

    // Barn Roof
    _drawIsometricRoof(
      canvas,
      size,
      px: px, py: py, pz: pz + dz,
      dx: dx, dy: dy, roofHeight: 12,
      roofColor: roofColor,
    );

    // Barn doors on front-left face (Y is constant at py + dy)
    final doorBaseLeft = project3D(px + dx/4, py + dy, 0, size);
    final doorBaseRight = project3D(px + 3*dx/4, py + dy, 0, size);
    final doorTopLeft = project3D(px + dx/4, py + dy, 10, size);
    final doorTopRight = project3D(px + 3*dx/4, py + dy, 10, size);
    
    final doorPath = Path()
      ..moveTo(doorBaseLeft.dx, doorBaseLeft.dy)
      ..lineTo(doorBaseRight.dx, doorBaseRight.dy)
      ..lineTo(doorTopRight.dx, doorTopRight.dy)
      ..lineTo(doorTopLeft.dx, doorTopLeft.dy)
      ..close();
    canvas.drawPath(doorPath, Paint()..color = const Color(0xFF3E2723)); // Dark barn doors
    canvas.drawPath(doorPath, Paint()..color = Colors.white70..style = PaintingStyle.stroke..strokeWidth = 1);

    // Level 4/5: Add Silo next to the barn
    if (level >= 4) {
      double siloX = px - 10;
      double siloY = py + 8;
      double siloR = 6;
      double siloH = 34;

      // Draw vertical cylinder
      _drawIsometricCylinder(
        canvas,
        size,
        px: siloX, py: siloY, pz: 0,
        radius: siloR, height: siloH,
        color: const Color(0xFF9E9E9E), // Steel grey
      );

      // Silo dome top (a simple blue/grey sphere dome)
      final domeCenter = project3D(siloX, siloY, siloH, size);
      final domePaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, const Color(0xFF757575)],
          center: Alignment.topLeft,
        ).createShader(Rect.fromCircle(center: domeCenter, radius: siloR * 0.866));
      canvas.drawCircle(domeCenter, siloR * 0.866 * 1.5, domePaint);
    }
  }

  void _drawMedicalStation(Canvas canvas, Size size) {
    // Medical Station location: x in [-60, -42], y in [15, 33]
    double px = -60, py = 15, pz = 0;
    double dx = 16, dy = 16, dz = 13;

    // Walls (White Clinic)
    _drawIsometricBox(
      canvas,
      size,
      px: px, py: py, pz: pz,
      dx: dx, dy: dy, dz: dz,
      wallColor: Colors.white,
    );

    // Roof (Green/teal clinic roof)
    _drawIsometricRoof(
      canvas,
      size,
      px: px, py: py, pz: pz + dz,
      dx: dx, dy: dy, roofHeight: 8,
      roofColor: Colors.teal.shade800,
    );

    // Red Cross on Front-Right face (X constant at px + dx)
    final crossCenter = project3D(px + dx, py + dy/2, dz/2, size);
    final crossPaint = Paint()..color = Colors.red..strokeWidth = 3;
    canvas.drawLine(crossCenter - const Offset(0, 5), crossCenter + const Offset(0, 5), crossPaint);
    canvas.drawLine(crossCenter - const Offset(5, 0), crossCenter + const Offset(5, 0), crossPaint);
  }

  void _drawQuarantinePen(Canvas canvas, Size size) {
    // Quarantine Pen: x in [45, 65], y in [25, 45]
    double px = 45, py = 25;
    double dx = 20, dy = 20;

    // Dirt patch polygon
    final path = Path()
      ..moveTo(project3D(px, py, 0, size).dx, project3D(px, py, 0, size).dy)
      ..lineTo(project3D(px + dx, py, 0, size).dx, project3D(px + dx, py, 0, size).dy)
      ..lineTo(project3D(px + dx, py + dy, 0, size).dx, project3D(px + dx, py + dy, 0, size).dy)
      ..lineTo(project3D(px, py + dy, 0, size).dx, project3D(px, py + dy, 0, size).dy)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.65)); // Brownish dirt
    
    // Warning fence lines
    final fencePaint = Paint()
      ..color = Colors.orange.shade800
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, fencePaint);

    // Posts at corners
    final postPaint = Paint()..color = Colors.black87..strokeWidth = 2.5;
    canvas.drawLine(project3D(px, py, 0, size), project3D(px, py, 6, size), postPaint);
    canvas.drawLine(project3D(px + dx, py, 0, size), project3D(px + dx, py, 6, size), postPaint);
    canvas.drawLine(project3D(px, py + dy, 0, size), project3D(px, py + dy, 6, size), postPaint);
    canvas.drawLine(project3D(px + dx, py + dy, 0, size), project3D(px + dx, py + dy, 6, size), postPaint);
  }

  void _drawWaterer(Canvas canvas, Size size, double x, double y) {
    // Waterer base box (X constant at x, Y constant at y)
    double dx = 10, dy = 6, dz = 4;
    _drawIsometricBox(
      canvas,
      size,
      px: x - dx/2, py: y - dy/2, pz: 0,
      dx: dx, dy: dy, dz: dz,
      wallColor: Colors.grey.shade700,
    );

    // Water level top
    final wTopLeft = project3D(x - dx/2 + 1, y - dy/2 + 1, dz, size);
    final wTopRight = project3D(x + dx/2 - 1, y - dy/2 + 1, dz, size);
    final wBotRight = project3D(x + dx/2 - 1, y + dy/2 - 1, dz, size);
    final wBotLeft = project3D(x - dx/2 + 1, y + dy/2 - 1, dz, size);

    final waterPath = Path()
      ..moveTo(wTopLeft.dx, wTopLeft.dy)
      ..lineTo(wTopRight.dx, wTopRight.dy)
      ..lineTo(wBotRight.dx, wBotRight.dy)
      ..lineTo(wBotLeft.dx, wBotLeft.dy)
      ..close();
    canvas.drawPath(waterPath, Paint()..color = Colors.blueAccent);
  }

  void _drawGoatSprite(Canvas canvas, Size size, AnimatedGoatSprite sprite) {
    final pos = project3D(sprite.x, sprite.y, 0, size);

    // Draw ground shadow ellipse
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 18, height: 8),
      shadowPaint,
    );

    // Draw Billboard emoji
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // Choose emoji based on state
    String emoji = '🐐';
    if (sprite.goat.isSick) {
      emoji = '🤒';
    } else if (sprite.goat.isPregnant) {
      emoji = '🤰';
    }

    textPainter.text = TextSpan(
      text: emoji,
      style: const TextStyle(fontSize: 20),
    );
    textPainter.layout();
    
    // Center it above the shadow (offset by height of billboard text)
    final textPos = pos - Offset(textPainter.width / 2, textPainter.height - 4);
    textPainter.paint(canvas, textPos);

    // Label with name in tiny text
    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    labelPainter.text = TextSpan(
      text: sprite.goat.name,
      style: const TextStyle(
        fontSize: 7,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      pos - Offset(labelPainter.width / 2, textPainter.height + labelPainter.height - 4),
    );
  }

  void _drawDonkeySprite(Canvas canvas, Size size, AnimatedDonkeySprite sprite) {
    final pos = project3D(sprite.x, sprite.y, 0, size);

    // Draw shadow
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 22, height: 10),
      shadowPaint,
    );

    // Draw Billboard
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = const TextSpan(
      text: '🫏',
      style: TextStyle(fontSize: 22),
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height - 4));
  }

  // --- Core Geometric 3D Projections ---

  void _drawIsometricBox(
    Canvas canvas,
    Size size, {
    required double px,
    required double py,
    required double pz,
    required double dx,
    required double dy,
    required double dz,
    required Color wallColor,
  }) {
    // Project all 8 vertices
    final v0 = project3D(px, py, pz, size);
    final v1 = project3D(px + dx, py, pz, size);
    final v3 = project3D(px, py + dy, pz, size);
    final v4 = project3D(px, py, pz + dz, size);
    final v5 = project3D(px + dx, py, pz + dz, size);
    final v6 = project3D(px + dx, py + dy, pz + dz, size);
    final v7 = project3D(px, py + dy, pz + dz, size);

    // 1. Draw Left Face (X is constant at px, vertices: v0, v3, v7, v4)
    final leftFace = Path()
      ..moveTo(v0.dx, v0.dy)
      ..lineTo(v3.dx, v3.dy)
      ..lineTo(v7.dx, v7.dy)
      ..lineTo(v4.dx, v4.dy)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = wallColor.withValues(alpha: 0.85)); // Shadowed side

    // 2. Draw Right Face (Y is constant at py, vertices: v0, v1, v5, v4)
    final rightFace = Path()
      ..moveTo(v0.dx, v0.dy)
      ..lineTo(v1.dx, v1.dy)
      ..lineTo(v5.dx, v5.dy)
      ..lineTo(v4.dx, v4.dy)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = wallColor.withValues(alpha: 0.95)); // Mid side

    // 3. Draw Top Face (Z is constant at pz + dz, vertices: v4, v5, v6, v7)
    final topFace = Path()
      ..moveTo(v4.dx, v4.dy)
      ..lineTo(v5.dx, v5.dy)
      ..lineTo(v6.dx, v6.dy)
      ..lineTo(v7.dx, v7.dy)
      ..close();
    canvas.drawPath(topFace, Paint()..color = wallColor); // Bright side

    // Outline borders
    final borderPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(leftFace, borderPaint);
    canvas.drawPath(rightFace, borderPaint);
    canvas.drawPath(topFace, borderPaint);
  }

  void _drawIsometricRoof(
    Canvas canvas,
    Size size, {
    required double px,
    required double py,
    required double pz,
    required double dx,
    required double dy,
    required double roofHeight,
    required Color roofColor,
  }) {
    // 4 base vertices
    final vBottomLeft = project3D(px, py, pz, size);
    final vBottomRight = project3D(px + dx, py, pz, size);
    final vBottomFront = project3D(px + dx, py + dy, pz, size);
    final vBottomBackLeft = project3D(px, py + dy, pz, size);

    // 2 peak vertices (centered along X axis)
    final vPeakBack = project3D(px + dx/2, py, pz + roofHeight, size);
    final vPeakFront = project3D(px + dx/2, py + dy, pz + roofHeight, size);

    // Draw Left Slanted Roof Face (vertices: vBottomLeft, vBottomBackLeft, vPeakFront, vPeakBack)
    final leftRoof = Path()
      ..moveTo(vBottomLeft.dx, vBottomLeft.dy)
      ..lineTo(vBottomBackLeft.dx, vBottomBackLeft.dy)
      ..lineTo(vPeakFront.dx, vPeakFront.dy)
      ..lineTo(vPeakBack.dx, vPeakBack.dy)
      ..close();
    canvas.drawPath(leftRoof, Paint()..color = roofColor.withValues(alpha: 0.85));

    // Draw Right Slanted Roof Face (vertices: vBottomRight, vBottomFront, vPeakFront, vPeakBack)
    final rightRoof = Path()
      ..moveTo(vBottomRight.dx, vBottomRight.dy)
      ..lineTo(vBottomFront.dx, vBottomFront.dy)
      ..lineTo(vPeakFront.dx, vPeakFront.dy)
      ..lineTo(vPeakBack.dx, vPeakBack.dy)
      ..close();
    canvas.drawPath(rightRoof, Paint()..color = roofColor);

    // Draw Front triangular face (vertices: vBottomFront, vBottomBackLeft? No, front side: vBottomBackLeft, vBottomFront, vPeakFront)
    // Actually, Gable roof front triangle matches X end: vBottomBackLeft, vBottomFront, vPeakFront (Wait, is it Y face?)
    // In our orientation:
    // Peak is aligned at X+dx/2. It spans from py to py+dy.
    // So the triangular faces are at py (back) and py+dy (front).
    // Back Triangle: vBottomLeft, vBottomRight, vPeakBack
    // Front Triangle: vBottomBackLeft, vBottomFront, vPeakFront
    
    final frontTriangle = Path()
      ..moveTo(vBottomBackLeft.dx, vBottomBackLeft.dy)
      ..lineTo(vBottomFront.dx, vBottomFront.dy)
      ..lineTo(vPeakFront.dx, vPeakFront.dy)
      ..close();
    canvas.drawPath(frontTriangle, Paint()..color = roofColor.withValues(alpha: 0.9));

    // Border lines
    final borderPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(leftRoof, borderPaint);
    canvas.drawPath(rightRoof, borderPaint);
    canvas.drawPath(frontTriangle, borderPaint);
  }

  void _drawIsometricCylinder(
    Canvas canvas,
    Size size, {
    required double px,
    required double py,
    required double pz,
    required double radius,
    required double height,
    required Color color,
  }) {
    // A vertical cylinder is represented by:
    // Base ellipse, top ellipse, and two vertical connecting sides
    final baseCenter = project3D(px, py, pz, size);
    final topCenter = project3D(px, py, pz + height, size);

    final screenR = radius * 0.866; // scaled for isometric X projection
    final screenH = screenR * 0.577; // height scaling for horizontal ellipse (sin30/cos30)

    // Body rectangle connecting base and top
    final rectPath = Path()
      ..moveTo(baseCenter.dx - screenR, baseCenter.dy)
      ..lineTo(baseCenter.dx + screenR, baseCenter.dy)
      ..lineTo(topCenter.dx + screenR, topCenter.dy)
      ..lineTo(topCenter.dx - screenR, topCenter.dy)
      ..close();
    canvas.drawPath(rectPath, Paint()..color = color.withValues(alpha: 0.9));

    // Base ellipse (only front half needs to be drawn if overlap is right, but solid drawing is safe)
    canvas.drawOval(Rect.fromCenter(center: baseCenter, width: screenR * 2, height: screenH * 2), Paint()..color = color.withValues(alpha: 0.85));

    // Top ellipse
    canvas.drawOval(Rect.fromCenter(center: topCenter, width: screenR * 2, height: screenH * 2), Paint()..color = color);

    // Border strokes
    final borderPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(rectPath, borderPaint);
    canvas.drawOval(Rect.fromCenter(center: topCenter, width: screenR * 2, height: screenH * 2), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RenderItem {
  final double depth; // depth sorting key
  final void Function(Canvas canvas) draw;

  _RenderItem({required this.depth, required this.draw});
}
