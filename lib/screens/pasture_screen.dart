import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class PastureScreen extends ConsumerStatefulWidget {
  const PastureScreen({super.key});

  @override
  ConsumerState<PastureScreen> createState() => _PastureScreenState();
}

class _PastureScreenState extends ConsumerState<PastureScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_GoatSprite> _sprites = [];
  _GoatSprite? _donkeySprite;
  final _random = Random();
  
  // Dimensions of the pasture canvas bounds
  final double _pastureWidth = 350.0;
  final double _pastureHeight = 250.0;

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

  void _syncSpritesWithHerd(int herdSize, bool hasDonkey) {
    // If list sizes don't match, rebuild/adjust sprites list
    if (_sprites.length != herdSize) {
      if (_sprites.length < herdSize) {
        // Add new sprites
        final count = herdSize - _sprites.length;
        for (int i = 0; i < count; i++) {
          _sprites.add(_GoatSprite(
            x: _random.nextDouble() * (_pastureWidth - 40) + 20,
            y: _random.nextDouble() * (_pastureHeight - 40) + 20,
            targetX: _random.nextDouble() * (_pastureWidth - 40) + 20,
            targetY: _random.nextDouble() * (_pastureHeight - 40) + 20,
            emoji: '🐐',
          ));
        }
      } else {
        // Remove excess sprites
        _sprites.removeRange(herdSize, _sprites.length);
      }
    }

    // Handle Guard Donkey sprite
    if (hasDonkey && _donkeySprite == null) {
      _donkeySprite = _GoatSprite(
        x: _random.nextDouble() * (_pastureWidth - 40) + 20,
        y: _random.nextDouble() * (_pastureHeight - 40) + 20,
        targetX: _random.nextDouble() * (_pastureWidth - 40) + 20,
        targetY: _random.nextDouble() * (_pastureHeight - 40) + 20,
        emoji: '🫏',
      );
    } else if (!hasDonkey) {
      _donkeySprite = null;
    }
  }

  void _updateSpritePositions() {
    setState(() {
      for (var sprite in _sprites) {
        sprite.updatePosition(_pastureWidth, _pastureHeight, _random);
      }
      _donkeySprite?.updatePosition(_pastureWidth, _pastureHeight, _random);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final ranch = gameState.ranch;
    final herd = gameState.herd;
    
    final theme = Theme.of(context);

    _syncSpritesWithHerd(herd.length, gameState.hasGuardDonkey);

    final currentPastureGrass = ranch.currentPasture == 1 ? ranch.grassLevel1 : ranch.grassLevel2;

    // Grass Color shifting based on grass level
    Color getGrassColor(double grassLevel) {
      if (grassLevel > 70) return Colors.green.shade700;
      if (grassLevel > 40) return Colors.green.shade500;
      if (grassLevel > 15) return Colors.green.shade300;
      return Colors.brown.shade300; // Brown pasture if grass is low
    }

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

              // Visual 2D Simulated Field Canvas
              Center(
                child: Container(
                  width: _pastureWidth,
                  height: _pastureHeight,
                  decoration: BoxDecoration(
                    color: getGrassColor(currentPastureGrass),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.brown.shade800, width: 6), // Wooden Fence Border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Draw animated sprites (goats)
                      for (int i = 0; i < _sprites.length; i++)
                        Positioned(
                          left: _sprites[i].x,
                          top: _sprites[i].y,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Label with goat name in small text
                              if (i < herd.length)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    herd[i].name,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              Text(
                                herd[i].isSick ? '🤒' : (herd[i].isPregnant ? '🤰' : '🐐'),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ],
                          ),
                        ),

                      // Draw Guard Donkey
                      if (_donkeySprite != null)
                        Positioned(
                          left: _donkeySprite!.x,
                          top: _donkeySprite!.y,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🫏 Guard',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, backgroundColor: Colors.teal),
                              ),
                              Text(
                                '🫏',
                                style: TextStyle(fontSize: 24),
                              ),
                            ],
                          ),
                        ),

                      // Draw Automated Waterer Visual Feedback
                      if (ranch.hasAutomatedWaterers)
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.water_drop, color: Colors.white, size: 10),
                                SizedBox(width: 3),
                                Text(
                                  'Irrigation Active 💧',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
                        'Pasture Legend & Actions',
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
                        'Keeping your pasture rotation active is key. Grazed grass depletes by ${herd.length * 2} points daily. '
                        'Resting pastures recover by 2-6 points daily depending on rain.',
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

class _GoatSprite {
  double x;
  double y;
  double targetX;
  double targetY;
  String emoji;

  _GoatSprite({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.emoji,
  });

  void updatePosition(double boundsWidth, double boundsHeight, Random random) {
    // Speed towards target
    const double speed = 0.5;
    
    final double dx = targetX - x;
    final double dy = targetY - y;
    final double distance = sqrt(dx * dx + dy * dy);

    if (distance > speed) {
      x += (dx / distance) * speed;
      y += (dy / distance) * speed;
    } else {
      // Reached target, set a new random target in bounds
      targetX = random.nextDouble() * (boundsWidth - 45) + 15;
      targetY = random.nextDouble() * (boundsHeight - 45) + 15;
    }
  }
}
