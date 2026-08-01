import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final ranch = gameState.ranch;
    final herd = gameState.herd;
    
    final theme = Theme.of(context);

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

              // 4. Herd List
              Text(
                'Active Herd (${herd.length} Goats)',
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
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
                                onPressed: ranch.cash >= 25
                                    ? () => ref.read(gameStateProvider.notifier).treatGoat(goat.id)
                                    : null,
                                child: const Text('Treat (\$25)', style: TextStyle(color: Colors.red)),
                              )
                            else
                              TextButton(
                                onPressed: () => ref.read(gameStateProvider.notifier).sellGoat(goat.id),
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
              if (isActive) const Text('GRAZING', style: TextStyle(fontSize: 9, color: Colors.teal, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: level / 100.0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(level > 40 ? Colors.green : Colors.brown),
          ),
          const SizedBox(height: 4),
          Text('${level.toStringAsFixed(0)}% Grass', style: theme.textTheme.bodySmall),
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
