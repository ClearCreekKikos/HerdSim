import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_provider.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  String? _selectedSireId;
  String? _selectedDamId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final gameState = ref.watch(gameStateProvider);
        final herd = gameState.herd;

        final bucks = herd.where((g) => g.gender == 'buck').toList();
        final does = herd.where((g) => g.gender == 'doe' && !g.isPregnant).toList();

        // Safe initializations
        if (_selectedSireId == null && bucks.isNotEmpty) {
          _selectedSireId = bucks.first.id;
        }
        if (_selectedDamId == null && does.isNotEmpty) {
          _selectedDamId = does.first.id;
        }

        final selectedSire = herd.any((g) => g.id == _selectedSireId) 
            ? herd.firstWhere((g) => g.id == _selectedSireId) 
            : (bucks.isNotEmpty ? bucks.first : null);
            
        final selectedDam = herd.any((g) => g.id == _selectedDamId) 
            ? herd.firstWhere((g) => g.id == _selectedDamId) 
            : (does.isNotEmpty ? does.first : null);

        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Breeding Pen'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Breeding Graphic/Banner
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade700, Colors.teal.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Genetic Selection & Breeding',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Select your best performing sire and dam. Kids inherit an average of parent genetics with random mutation rates.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Breeding Selection Columns
                  Row(
                    children: [
                      // Sire Selector
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('SELECT SIRE (BUCK)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                const SizedBox(height: 8),
                                if (bucks.isEmpty)
                                  const Text('No adult bucks available!', style: TextStyle(color: Colors.red, fontSize: 13))
                                else
                                  DropdownButton<String>(
                                    value: _selectedSireId ?? (bucks.isNotEmpty ? bucks.first.id : null),
                                    isExpanded: true,
                                    items: bucks.map((b) {
                                      return DropdownMenuItem(
                                        value: b.id,
                                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedSireId = val;
                                      });
                                    },
                                  ),
                                if (selectedSire != null) ...[
                                  const SizedBox(height: 8),
                                  Text('Weight: ${selectedSire.weightLbs.toStringAsFixed(0)} lbs'),
                                  Text('PR (Worms): ${(selectedSire.parasiteResistance * 100).toStringAsFixed(0)}%'),
                                  Text('Growth Rate: ${selectedSire.growthRate.toStringAsFixed(1)}x'),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dam Selector
                      Expanded(
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('SELECT DAM (DOE)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.pink)),
                                const SizedBox(height: 8),
                                if (does.isEmpty)
                                  const Text('No eligible open does!', style: TextStyle(color: Colors.red, fontSize: 13))
                                else
                                  DropdownButton<String>(
                                    value: _selectedDamId ?? (does.isNotEmpty ? does.first.id : null),
                                    isExpanded: true,
                                    items: does.map((d) {
                                      return DropdownMenuItem(
                                        value: d.id,
                                        child: Text(d.name, overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedDamId = val;
                                      });
                                    },
                                  ),
                                if (selectedDam != null) ...[
                                  const SizedBox(height: 8),
                                  Text('Weight: ${selectedDam.weightLbs.toStringAsFixed(0)} lbs'),
                                  Text('PR (Worms): ${(selectedDam.parasiteResistance * 100).toStringAsFixed(0)}%'),
                                  Text('Growth Rate: ${selectedDam.growthRate.toStringAsFixed(1)}x'),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Expected Kid Stats Comparison
                  if (selectedSire != null && selectedDam != null) ...[
                    Card(
                      elevation: 1.5,
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Expected Offspring Traits',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _buildStatCompareRow(
                              context,
                              title: 'Parasite Resistance (PR)',
                              sireVal: selectedSire.parasiteResistance,
                              damVal: selectedDam.parasiteResistance,
                              unit: '%',
                              multiply: 100,
                            ),
                            const Divider(height: 20),
                            _buildStatCompareRow(
                              context,
                              title: 'Growth Rate Trait',
                              sireVal: selectedSire.growthRate,
                              damVal: selectedDam.growthRate,
                              unit: 'x',
                              multiply: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        ref.read(gameStateProvider.notifier).breedGoats(selectedSire.id, selectedDam.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Buck ${selectedSire.name} bred to Doe ${selectedDam.name}! Pregnancy started.')),
                        );
                        // Reset selections
                        setState(() {
                          _selectedDamId = null;
                        });
                      },
                      child: const Text('Confirm Breeding Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    Card(
                      color: Colors.red.withValues(alpha: 0.15),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'You must have at least one adult Buck and one open (non-pregnant) Doe in your herd to breed.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCompareRow(BuildContext context, {required String title, required double sireVal, required double damVal, required String unit, double multiply = 1.0}) {
    final expectedVal = (sireVal + damVal) / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Sire: ${(sireVal * multiply).toStringAsFixed(0)}$unit', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)),
            Text('Expected: ${(expectedVal * multiply).toStringAsFixed(0)}$unit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
            Text('Dam: ${(damVal * multiply).toStringAsFixed(0)}$unit', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.pink)),
          ],
        ),
      ],
    );
  }
}
