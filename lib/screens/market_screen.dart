import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';
import '../models/goat_model.dart';
import 'auction_dialog.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameStateProvider);
    final ranch = gameState.ranch;

    // Dynamic market items based on Day Count
    final marketGoats = [
      Goat(
        id: 'market_boer_buck_${ranch.dayCount}',
        name: 'Goliath',
        gender: 'buck',
        ageMonths: 12,
        weightLbs: 140.0,
        breed: 'Boer',
        parasiteResistance: 0.50,
        growthRate: 1.4,
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
        parasiteResistance: 0.95,
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ranch Market & Construction'),
          bottom: TabBar(
            indicatorColor: Colors.teal.shade300,
            labelColor: Colors.teal.shade300,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.storefront), text: 'Livestock Market'),
              Tab(icon: Icon(Icons.build), text: 'Ranch Upgrades'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLivestockMarketTab(context, ref, gameState, marketGoats, prices),
            _buildUpgradesTab(context, ref, gameState),
          ],
        ),
      ),
    );
  }

  Widget _buildCashCard(ThemeData theme, double cash) {
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Available Cash', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(
              '\$${cash.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivestockMarketTab(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
    List<Goat> marketGoats,
    List<double> prices,
  ) {
    final theme = Theme.of(context);
    final ranch = gameState.ranch;
    final herd = gameState.herd;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCashCard(theme, ranch.cash),
            const SizedBox(height: 16),

            // Herd Capacity warning if near limit
            if (herd.length >= ranch.herdCapacity)
              Card(
                color: Colors.red.withValues(alpha: 0.15),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Barn at maximum capacity! You must upgrade your Barn or sell goats to acquire new ones.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            Text(
              'Available Goats for Purchase',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: marketGoats.length,
              itemBuilder: (context, index) {
                final goat = marketGoats[index];
                final price = prices[index];
                final isAtCapacity = herd.length >= ranch.herdCapacity;
                final canAfford = ranch.cash >= price && !isAtCapacity;

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
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                '\$${price.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Breed: ${goat.breed}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('Age: ${goat.ageMonths} mo', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('Weight: ${goat.weightLbs.toStringAsFixed(0)} lbs', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                                Text('PR (Worm Resistance): ${(goat.parasiteResistance * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12)),
                                Text('Growth Rate: ${goat.growthRate.toStringAsFixed(2)}x', style: const TextStyle(fontSize: 12)),
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
            const SizedBox(height: 24),

            // Sell section listing current herd
            Text(
              'Auction Off Your Herd Members',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (herd.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No goats in your herd to sell.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: herd.length,
                itemBuilder: (context, index) {
                  final goat = herd[index];
                  // Don't sell the last buck or doe if it leaves herd completely empty, but game allows it.
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
                      subtitle: Text('Weight: ${goat.weightLbs.toStringAsFixed(0)} lbs | PR: ${(goat.parasiteResistance * 100).toStringAsFixed(0)}%'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AuctionDialog(goat: goat),
                          );
                        },
                        child: const Text('Auction'),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradesTab(BuildContext context, WidgetRef ref, GameState gameState) {
    final theme = Theme.of(context);
    final ranch = gameState.ranch;

    // Upgrades listings
    final double barnCost = ranch.barnLevel * 150.0;
    final bool isBarnMaxed = ranch.barnLevel >= 5;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCashCard(theme, ranch.cash),
            const SizedBox(height: 16),

            Text(
              'Ranch Construction & Feed Supply',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Upgrade list cards
            Card(
              child: Column(
                children: [
                  // 1. Bulk Feed
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined, color: Colors.teal, size: 32),
                    title: const Text('Bulk Commercial Feed (50 lbs)'),
                    subtitle: const Text('Feed supply when pasture grass drops to 0%. Prevent starvation!'),
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

                  // 2. Guard Donkey
                  ListTile(
                    leading: const Icon(Icons.security, color: Colors.teal, size: 32),
                    title: const Text('Guard Donkey (Security)'),
                    subtitle: const Text('100% blocks random predator coyote attacks on pastures.'),
                    trailing: ElevatedButton(
                      onPressed: (ranch.cash >= 300.0 && !gameState.hasGuardDonkey)
                          ? () {
                              ref.read(gameStateProvider.notifier).buyGuardDonkey();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Guard Donkey purchased!')),
                              );
                            }
                          : null,
                      child: Text(gameState.hasGuardDonkey ? 'Owned 🫏' : 'Buy (\$300)'),
                    ),
                  ),
                  const Divider(height: 1),

                  // 3. Barn Upgrade
                  ListTile(
                    leading: const Icon(Icons.home_outlined, color: Colors.teal, size: 32),
                    title: Text('Barn Expansion (Lvl ${ranch.barnLevel} -> ${isBarnMaxed ? 5 : ranch.barnLevel + 1})'),
                    subtitle: Text('Increases herd limit from ${ranch.herdCapacity} to ${_getCapacityForLevel(ranch.barnLevel + 1)} goats.'),
                    trailing: ElevatedButton(
                      onPressed: (!isBarnMaxed && ranch.cash >= barnCost)
                          ? () {
                              ref.read(gameStateProvider.notifier).buyUpgrade('barn', barnCost);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Upgraded Barn to Level ${ranch.barnLevel + 1}!')),
                              );
                            }
                          : null,
                      child: Text(isBarnMaxed ? 'Max Lvl 5' : 'Upgrade (\$${barnCost.toStringAsFixed(0)})'),
                    ),
                  ),
                  const Divider(height: 1),

                  // 4. Medical Station
                  ListTile(
                    leading: const Icon(Icons.local_hospital_outlined, color: Colors.teal, size: 32),
                    title: const Text('Medical Station (Veterinary Clinic)'),
                    subtitle: const Text('Reduces dewormer treatments to \$10. 15% daily auto-cure. Halves sickness deaths.'),
                    trailing: ElevatedButton(
                      onPressed: (!ranch.hasMedicalStation && ranch.cash >= 250.0)
                          ? () {
                              ref.read(gameStateProvider.notifier).buyUpgrade('medical', 250.0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Constructed Medical Station!')),
                              );
                            }
                          : null,
                      child: Text(ranch.hasMedicalStation ? 'Active 💊' : 'Build (\$250)'),
                    ),
                  ),
                  const Divider(height: 1),

                  // 5. Automated Waterers
                  ListTile(
                    leading: const Icon(Icons.water_drop_outlined, color: Colors.teal, size: 32),
                    title: const Text('Automated Waterers (Irrigation)'),
                    subtitle: const Text('Speeds up grass regrowth in the inactive pasture by 15% daily.'),
                    trailing: ElevatedButton(
                      onPressed: (!ranch.hasAutomatedWaterers && ranch.cash >= 200.0)
                          ? () {
                              ref.read(gameStateProvider.notifier).buyUpgrade('waterer', 200.0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Installed Automated Waterers!')),
                              );
                            }
                          : null,
                      child: Text(ranch.hasAutomatedWaterers ? 'Active 💧' : 'Install (\$200)'),
                    ),
                  ),
                  const Divider(height: 1),

                  // 6. Quarantine Pen
                  ListTile(
                    leading: const Icon(Icons.gavel_outlined, color: Colors.teal, size: 32),
                    title: const Text('Quarantine Pen (Biosecurity)'),
                    subtitle: const Text('Completely blocks the 10% daily risk of sick goats spreading worms to others.'),
                    trailing: ElevatedButton(
                      onPressed: (!ranch.hasQuarantinePen && ranch.cash >= 150.0)
                          ? () {
                              ref.read(gameStateProvider.notifier).buyUpgrade('quarantine', 150.0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Built Quarantine Pen!')),
                              );
                            }
                          : null,
                      child: Text(ranch.hasQuarantinePen ? 'Active 🚧' : 'Build (\$150)'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCapacityForLevel(int level) {
    switch (level) {
      case 1:
        return 6;
      case 2:
        return 12;
      case 3:
        return 25;
      case 4:
        return 50;
      case 5:
      default:
        return 100;
    }
  }
}
