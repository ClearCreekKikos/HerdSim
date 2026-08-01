import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../models/goat_model.dart';
import 'ranch_3d_painter.dart';

class PastureScreen extends ConsumerStatefulWidget {
  const PastureScreen({super.key});

  @override
  ConsumerState<PastureScreen> createState() => _PastureScreenState();
}

class _PastureScreenState extends ConsumerState<PastureScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<AnimatedGoatSprite> _sprites = [];
  AnimatedDonkeySprite? _donkeySprite;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _controller.addListener(_updateSpritePositions);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncSpritesWithHerd(List<Goat> herd, bool hasDonkey, int currentPasture) {
    // 1. Remove sprites that are no longer in the herd
    final herdIds = herd.map((g) => g.id).toSet();
    _sprites.removeWhere((sprite) => !herdIds.contains(sprite.id));

    // 2. Add or update sprites
    for (var goat in herd) {
      final index = _sprites.indexWhere((s) => s.id == goat.id);
      if (index != -1) {
        _sprites[index].goat = goat;
        _sprites[index].forcePastureCheck(_random, currentPasture);
      } else {
        // Create new sprite in the active pasture
        double startX, startY;
        if (currentPasture == 1) {
          startX = -60 + _random.nextDouble() * 50;
        } else {
          startX = 10 + _random.nextDouble() * 50;
        }
        startY = -60 + _random.nextDouble() * 120;

        final newSprite = AnimatedGoatSprite(
          id: goat.id,
          goat: goat,
          x: startX,
          y: startY,
          targetX: startX,
          targetY: startY,
        );
        newSprite._setNewTarget(_random, currentPasture);
        _sprites.add(newSprite);
      }
    }

    // 3. Donkey sprite sync
    if (hasDonkey && _donkeySprite == null) {
      double startX = currentPasture == 1 ? -30 : 30;
      _donkeySprite = AnimatedDonkeySprite(
        x: startX,
        y: 0,
        targetX: startX,
        targetY: 0,
      );
      _donkeySprite!._setNewTarget(_random, currentPasture);
    } else if (hasDonkey && _donkeySprite != null) {
      _donkeySprite!.forcePastureCheck(_random, currentPasture);
    } else if (!hasDonkey) {
      _donkeySprite = null;
    }
  }

  void _updateSpritePositions() {
    if (!mounted) return;
    final gameState = ref.read(gameStateProvider);
    setState(() {
      for (var sprite in _sprites) {
        sprite.updatePosition(_random, gameState.ranch.currentPasture);
      }
      _donkeySprite?.updatePosition(_random, gameState.ranch.currentPasture);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final ranch = gameState.ranch;
    final herd = gameState.herd;
    final theme = Theme.of(context);

    // Keep sprites in sync
    _syncSpritesWithHerd(herd, gameState.hasGuardDonkey, ranch.currentPasture);

    final double currentPastureGrass = ranch.currentPasture == 1 ? ranch.grassLevel1 : ranch.grassLevel2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasture Simulator'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Pasture Header Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active: Pasture ${ranch.currentPasture}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Grass Health: ${currentPastureGrass.toStringAsFixed(0)}%',
                            style: TextStyle(color: currentPastureGrass > 40 ? Colors.green : Colors.brown, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Rotate Pasture'),
                        onPressed: () {
                          ref.read(gameStateProvider.notifier).rotatePastures();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visual 3D Simulated Field Canvas
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 360,
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.brown.shade800, width: 6), // Wooden Fence Border
                    ),
                    child: CustomPaint(
                      painter: Ranch3DPainter(
                        gameState: gameState,
                        goatSprites: _sprites,
                        donkeySprite: _donkeySprite,
                      ),
                      size: const Size(360, 280),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Legend Card
              Card(
                elevation: 1.5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pasture Legend & Info',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Text('🐐 Healthy Goat', style: TextStyle(fontSize: 13)),
                          Spacer(),
                          Text('🤒 Sick Goat', style: TextStyle(fontSize: 13)),
                          Spacer(),
                          Text('🤰 Pregnant Doe', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'Pastures recover and support grazing dynamically. Upgrades like Automated Waterers speed up grass growth. '
                        'Rotate your herd regularly to prevent starvation!',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedGoatSprite {
  final String id;
  Goat goat;
  double x;
  double y;
  double targetX;
  double targetY;

  AnimatedGoatSprite({
    required this.id,
    required this.goat,
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
  });

  void updatePosition(Random random, int currentPasture) {
    const double speed = 0.4;
    final double dx = targetX - x;
    final double dy = targetY - y;
    final double distance = sqrt(dx * dx + dy * dy);

    if (distance > speed) {
      x += (dx / distance) * speed;
      y += (dy / distance) * speed;
    } else {
      _setNewTarget(random, currentPasture);
    }
  }

  void _setNewTarget(Random random, int currentPasture) {
    if (currentPasture == 1) {
      targetX = -60 + random.nextDouble() * 50; // Pasture 1 boundary X: [-60, -10]
    } else {
      targetX = 10 + random.nextDouble() * 50;  // Pasture 2 boundary X: [10, 60]
    }
    targetY = -60 + random.nextDouble() * 120;  // Boundary Y: [-60, 60]
  }

  void forcePastureCheck(Random random, int currentPasture) {
    bool isOutside = false;
    if (currentPasture == 1 && x > 0) {
      isOutside = true;
    } else if (currentPasture == 2 && x < 0) {
      isOutside = true;
    }
    
    if (isOutside) {
      _setNewTarget(random, currentPasture);
    }
  }
}

class AnimatedDonkeySprite {
  double x;
  double y;
  double targetX;
  double targetY;

  AnimatedDonkeySprite({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
  });

  void updatePosition(Random random, int currentPasture) {
    const double speed = 0.3;
    final double dx = targetX - x;
    final double dy = targetY - y;
    final double distance = sqrt(dx * dx + dy * dy);

    if (distance > speed) {
      x += (dx / distance) * speed;
      y += (dy / distance) * speed;
    } else {
      _setNewTarget(random, currentPasture);
    }
  }

  void _setNewTarget(Random random, int currentPasture) {
    if (currentPasture == 1) {
      targetX = -50 + random.nextDouble() * 40;
    } else {
      targetX = 10 + random.nextDouble() * 40;
    }
    targetY = -50 + random.nextDouble() * 100;
  }

  void forcePastureCheck(Random random, int currentPasture) {
    bool isOutside = false;
    if (currentPasture == 1 && x > 0) {
      isOutside = true;
    } else if (currentPasture == 2 && x < 0) {
      isOutside = true;
    }
    
    if (isOutside) {
      _setNewTarget(random, currentPasture);
    }
  }
}
