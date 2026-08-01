import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../models/goat_model.dart';
import 'auction_dialog.dart';
import 'ranch_3d_painter.dart';
import 'pasture_screen.dart'; // Imports sprite classes

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
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
        // Create new sprite in active pasture
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
        newSprite.forcePastureCheck(_random, currentPasture);
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
      _donkeySprite!.forcePastureCheck(_random, currentPasture);
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

    // Sync sprites
    _syncSpritesWithHerd(herd, gameState.hasGuardDonkey, ranch.currentPasture);

    // Weather Icon helper
    IconData getWeatherIcon(String weather) {
      switch (weather) {
        case 'Rainy':
          return Icons.grain_outlined;
        case 'Drought':
          return Icons.warning_amber_rounded;
        default:
          return Icons.wb_sunny_outlined;
      }
    }

    Color getWeatherColor(String weather) {
      switch (weather) {
        case 'Rainy':
          return Colors.blue;
        case 'Drought':
          return Colors.orange;
        default:
          return Colors.amber;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('HerdSim Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showTutorial(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 0. Visual 3D Ranch Viewport Header
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.brown.shade800, width: 4), // Wooden Fence Border
                  ),
                  child: CustomPaint(
                    painter: Ranch3DPainter(
                      gameState: gameState,
                      goatSprites: _sprites,
                      donkeySprite: _donkeySprite,
                    ),
                    size: const Size(double.infinity, 180),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 1. Core Tycoon Stats Bar
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Ranch Cash',
                      value: '\$${ranch.cash.toStringAsFixed(2)}',
                      icon: Icons.monetization_on_outlined,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Feed Inventory',
                      value: '${ranch.feedLbs.toStringAsFixed(0)} lbs',
                      icon: Icons.grass,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Current Weather',
                      value: ranch.weather,
                      icon: getWeatherIcon(ranch.weather),
                      color: getWeatherColor(ranch.weather),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Day Counter',
                      value: 'Day ${ranch.dayCount}',
                      icon: Icons.calendar_today_outlined,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Pasture Rotation Panel
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pasture Grass Levels & Rotations',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPastureIndicator(
                              context,
                              title: 'Pasture 1',
                              level: ranch.grassLevel1,
                              isActive: ranch.currentPasture == 1,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildPastureIndicator(
                              context,
                              title: 'Pasture 2',
                              level: ranch.grassLevel2,
                              isActive: ranch.currentPasture == 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.autorenew_outlined),
                        label: const Text('Rotate Herd to Other Pasture'),
                        onPressed: () {
                          ref.read(gameStateProvider.notifier).rotatePastures();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Quick Actions
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Quick Ranch Controls',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: ranch.cash >= 50
                                  ? () => ref.read(gameStateProvider.notifier).buyFeed(50.0, 50.0)
                                  : null,
                              child: const Text('Buy Feed (50 lbs / \$50)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (ranch.cash >= 300 && !gameState.hasGuardDonkey)
                                  ? () => ref.read(gameStateProvider.notifier).buyGuardDonkey()
                                  : null,
                              child: Text(gameState.hasGuardDonkey ? 'Donkey Guarded 🫏' : 'Buy Donkey (\$300)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Simulate Next Day (Advance Time)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ref.read(gameStateProvider.notifier).nextDay();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ranch Upgrades Status Panel
              _buildUpgradesPanel(context, gameState),
              const SizedBox(height: 16),

              // 4. Herd List
              Text(
                'Active Herd (${herd.length} / ${ranch.herdCapacity} Goats - Barn Lvl ${ranch.barnLevel})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (herd.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('Your herd has died out! Restart the app to play again.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: herd.length,
                  itemBuilder: (context, index) {
                    final goat = herd[index];
                    final treatCost = ranch.hasMedicalStation ? 10.0 : 25.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        onTap: () => _showGoatDetailModal(context, goat, ref),
                        leading: CircleAvatar(
                          backgroundColor: goat.gender == 'buck' ? Colors.blue.shade100 : Colors.pink.shade100,
                          child: Text(
                            goat.gender == 'buck' ? '♂️' : '♀️',
                            style: TextStyle(color: goat.gender == 'buck' ? Colors.blue : Colors.pink),
                          ),
                        ),
                        title: Text('${goat.name} [${goat.breed}]', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Age: ${goat.ageMonths} mo | Weight: ${goat.weightLbs.toStringAsFixed(0)} lbs\n'
                          'PR (Worm Resistance): ${(goat.parasiteResistance * 100).toStringAsFixed(0)}%\n'
                          'Status: ${goat.statusDisplay}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (goat.isSick)
                              TextButton(
                                onPressed: ranch.cash >= treatCost
                                    ? () => ref.read(gameStateProvider.notifier).treatGoat(goat.id)
                                    : null,
                                child: Text('Treat (\$${treatCost.toStringAsFixed(0)})', style: const TextStyle(color: Colors.red)),
                              )
                            else
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AuctionDialog(goat: goat),
                                  );
                                },
                                child: const Text('Sell at Auction', style: TextStyle(color: Colors.green)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // 5. Ranch Log / Ledger
              Text(
                'Recent Ranch Activity Log',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                padding: const EdgeInsets.all(12),
                child: ListView.builder(
                  itemCount: ranch.ledger.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        ranch.ledger[index],
                        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastureIndicator(BuildContext context, {required String title, required double level, required bool isActive}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.teal.withValues(alpha: 0.08) : Colors.transparent,
        border: Border.all(color: isActive ? Colors.teal : Colors.grey.shade300, width: isActive ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
              if (isActive)
                const Icon(Icons.check_circle, size: 16, color: Colors.teal),
            ],
          ),
          const SizedBox(height: 4),
          Text('${level.toStringAsFixed(0)}% Grass', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildUpgradesPanel(BuildContext context, GameState gameState) {
    final theme = Theme.of(context);
    final ranch = gameState.ranch;
    
    final activeUpgrades = <Widget>[];

    if (gameState.hasGuardDonkey) {
      activeUpgrades.add(_buildUpgradeChip(context, Icons.security, "Guard Donkey 🫏", Colors.amber));
    }
    if (ranch.hasMedicalStation) {
      activeUpgrades.add(_buildUpgradeChip(context, Icons.local_hospital_outlined, "Medical Station 💊", Colors.redAccent));
    }
    if (ranch.hasAutomatedWaterers) {
      activeUpgrades.add(_buildUpgradeChip(context, Icons.water_drop_outlined, "Auto Waterers 💧", Colors.blueAccent));
    }
    if (ranch.hasQuarantinePen) {
      activeUpgrades.add(_buildUpgradeChip(context, Icons.gavel_outlined, "Quarantine Pen 🚧", Colors.orangeAccent));
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ranch Upgrades & Facilities',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (activeUpgrades.isEmpty)
              Text(
                'No upgrades purchased yet. Visit the Ranch Construction tab in the Market to upgrade!',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeUpgrades,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _showGoatDetailModal(BuildContext context, Goat goat, WidgetRef ref) {
    final theme = Theme.of(context);
    final cash = ref.read(gameStateProvider).ranch.cash;
    final treatCost = ref.read(gameStateProvider).ranch.hasMedicalStation ? 10.0 : 25.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "${goat.name} Details",
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Genetic stats card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildDetailRow("Breed", goat.breed),
                      _buildDetailRow("Gender", goat.genderDisplay),
                      _buildDetailRow("Age", "${goat.ageMonths} months"),
                      _buildDetailRow("Weight", "${goat.weightLbs.toStringAsFixed(1)} lbs"),
                      _buildDetailRow("Parasite Resistance", "${(goat.parasiteResistance * 100).toStringAsFixed(0)}%"),
                      _buildDetailRow("Growth Rate", "${goat.growthRate.toStringAsFixed(2)}x"),
                      _buildDetailRow("Status", goat.statusDisplay),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Pedigree Visual Tree
              Text(
                "Pedigree (3 Generations)",
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Target Goat
                  Expanded(
                    child: _buildPedigreeNode(context, goat.name, "${goat.breed} (${goat.genderDisplay.substring(0,1)})", isTarget: true),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  // Parents
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPedigreeNode(context, goat.sireName, "Sire (PR: ${(goat.sirePR * 100).toStringAsFixed(0)}%)"),
                        const SizedBox(height: 8),
                        _buildPedigreeNode(context, goat.damName, "Dam (PR: ${(goat.damPR * 100).toStringAsFixed(0)}%)"),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  // Grandparents
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPedigreeNode(context, goat.sireSireName, "G-Sire (Sire)"),
                        const SizedBox(height: 2),
                        _buildPedigreeNode(context, goat.sireDamName, "G-Dam (Sire)"),
                        const SizedBox(height: 8),
                        _buildPedigreeNode(context, goat.damSireName, "G-Sire (Dam)"),
                        const SizedBox(height: 2),
                        _buildPedigreeNode(context, goat.damDamName, "G-Dam (Dam)"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (goat.isSick)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: cash >= treatCost
                  ? () {
                      ref.read(gameStateProvider.notifier).treatGoat(goat.id);
                      Navigator.pop(ctx);
                    }
                  : null,
              child: Text("Treat (\$${treatCost.toStringAsFixed(0)})"),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPedigreeNode(BuildContext context, String name, String label, {bool isTarget = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isTarget ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isTarget ? theme.colorScheme.primary : theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: isTarget ? theme.colorScheme.onPrimaryContainer : Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 8, color: isTarget ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8) : Colors.grey),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTutorial(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How to Play HerdSim'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Goal:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Breed healthy goats, inherit premium parasite resistance, grow your herd, and increase your ranch cash flow!\n'),
              Text('2. Pasture Rotation:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Your goats eat grass. If a pasture hits 0% grass, rotate them to the other pasture to allow the grass to regrow. If both hit 0%, your goats will eat bought feed.\n'),
              Text('3. Feed Stock:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Always keep feed in stock to prevent starvation when pastures are empty. Buying feed costs cash.\n'),
              Text('4. Parasite Check:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Goats with low worm resistance will get sick. You must treat sick goats immediately for \$25, or they might die!\n'),
              Text('5. Guard Animals:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Coyotes can attack at random. Purchase a Guard Donkey to protect your goats!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Let\'s Play'),
          ),
        ],
      ),
    );
  }
}
