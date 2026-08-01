import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../models/goat_model.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final ranch = gameState.ranch;
    
    final theme = Theme.of(context);

    // Dynamic market items based on Day Count
    final marketGoats = [
      Goat(
        id: 'market_boer_buck_${ranch.dayCount}',
        name: 'Goliath',
        gender: 'buck',
        ageMonths: 12,
        weightLbs: 140.0,
        breed: 'Boer',
        parasiteResistance: 0.50, // lower worm resistance
        growthRate: 1.4, // high meat growth rate
        sireName: 'Boer Champion',
        damName: 'Boer Queen',
      ),
      Goat(
        id: 'market_kiko_doe_${ranch.dayCount}',
        name: 'Serena',
        gender: 'doe',
        ageMonths: 14,
        weightLbs: 90.0,
        breed: 'Kiko',
        parasiteResistance: 0.95, // outstanding parasite resistance
        growthRate: 0.95,
        sireName: 'Kiko Warrior',
        damName: 'Kiko Beauty',
      ),
      Goat(
        id: 'market_myotonic_doe_${ranch.dayCount}',
        name: 'Hazel',
        gender: 'doe',
        ageMonths: 10,
        weightLbs: 75.0,
        breed: 'Myotonic',
        parasiteResistance: 0.75,
        growthRate: 0.80,
        sireName: 'Fainting Rex',
        damName: 'Fainting Doll',
      ),
    ];

    final prices = [500.0, 450.0, 300.0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranch Supply & Livestock Market'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cash Indicator
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Available Cash', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '\$${ranch.cash.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ranch Feed & Fencing Upgrades
              Text('Supply Store', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined, color: Colors.teal, size: 32),
                      title: const Text('Bulk Commercial Feed (50 lbs)'),
                      subtitle: const Text('Essential for when pasture grass is depleted to prevent starvation.'),
                      trailing: ElevatedButton(
                        onPressed: ranch.cash >= 50.0
                            ? () {
                                ref.read(gameStateProvider.notifier).buyFeed(50.0, 50.0);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Purchased 50 lbs of feed.')),
                                );
                              }
                            : null,
                        child: const Text('Buy (\$50)'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: Colors.teal, size: 32),
                      title: const Text('Guard Donkey (Security Upgrade)'),
                      subtitle: const Text('100% blocks random coyote attacks on your pasture.'),
                      trailing: ElevatedButton(
                        onPressed: (ranch.cash >= 300.0 && !gameState.hasGuardDonkey)
                            ? () {
                                ref.read(gameStateProvider.notifier).buyGuardDonkey();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Guard Donkey purchased! Herd protected.')),
                                );
                              }
                            : null,
                        child: Text(gameState.hasGuardDonkey ? 'Owned 🫏' : 'Buy (\$300)'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Livestock Listings
              Text('Available Goats for Sale', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: marketGoats.length,
                itemBuilder: (context, index) {
                  final goat = marketGoats[index];
                  final price = prices[index];
                  final canAfford = ranch.cash >= price;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${goat.name} (${goat.genderDisplay})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '\$${price.toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Breed: ${goat.breed}', style: const TextStyle(color: Colors.grey)),
                              Text('Age: ${goat.ageMonths} mo', style: const TextStyle(color: Colors.grey)),
                              Text('Weight: ${goat.weightLbs.toStringAsFixed(0)} lbs', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PR (Worm Resistance): ${(goat.parasiteResistance * 100).toStringAsFixed(0)}%'),
                                  Text('Growth Rate: ${goat.growthRate.toStringAsFixed(2)}x'),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: canAfford
                                    ? () {
                                        ref.read(gameStateProvider.notifier).buyGoat(goat, price);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Purchased ${goat.name} for \$$price!')),
                                        );
                                      }
                                    : null,
                                child: const Text('Buy Goat'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
