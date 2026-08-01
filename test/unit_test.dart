import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herdsim/providers/game_provider.dart';
import 'package:herdsim/models/goat_model.dart';

void main() {
  group('HerdSim Upgrades & Pedigree Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state contains correct values', () {
      final state = container.read(gameStateProvider);
      expect(state.ranch.dayCount, 1);
      expect(state.ranch.cash, 1200.0);
      expect(state.ranch.barnLevel, 1);
      expect(state.ranch.herdCapacity, 6);
      expect(state.herd.length, 3);
      expect(state.ranch.hasMedicalStation, false);
      expect(state.ranch.hasAutomatedWaterers, false);
      expect(state.ranch.hasQuarantinePen, false);
    });

    test('Upgrading barn increases capacity and subtracts cash', () {
      final notifier = container.read(gameStateProvider.notifier);
      
      notifier.buyUpgrade('barn', 150.0);
      
      final state = container.read(gameStateProvider);
      expect(state.ranch.barnLevel, 2);
      expect(state.ranch.herdCapacity, 12);
      expect(state.ranch.cash, 1200.0 - 150.0);
    });

    test('Upgrades are correctly toggled and cash is deducted', () {
      final notifier = container.read(gameStateProvider.notifier);
      
      notifier.buyUpgrade('medical', 250.0);
      notifier.buyUpgrade('waterer', 200.0);
      notifier.buyUpgrade('quarantine', 150.0);
      
      final state = container.read(gameStateProvider);
      expect(state.ranch.hasMedicalStation, true);
      expect(state.ranch.hasAutomatedWaterers, true);
      expect(state.ranch.hasQuarantinePen, true);
      expect(state.ranch.cash, 1200.0 - 250.0 - 200.0 - 150.0);
    });

    test('Enforces barn limits when buying goats', () {
      final notifier = container.read(gameStateProvider.notifier);
      
      // Barn level 1 capacity is 6. Initial herd is 3.
      final newGoat = Goat(
        id: 'test_goat',
        name: 'Testy',
        gender: 'doe',
        ageMonths: 12,
        weightLbs: 100.0,
        breed: 'Boer',
        parasiteResistance: 0.5,
        growthRate: 1.0,
        sireName: 'Unknown',
        damName: 'Unknown',
      );

      // Buy 3 goats (reaches capacity 6)
      notifier.buyGoat(newGoat.copyWith(id: 'tg1'), 100.0);
      notifier.buyGoat(newGoat.copyWith(id: 'tg2'), 100.0);
      notifier.buyGoat(newGoat.copyWith(id: 'tg3'), 100.0);
      
      var state = container.read(gameStateProvider);
      expect(state.herd.length, 6);

      // Attempting to buy a 7th goat should fail due to capacity limit
      notifier.buyGoat(newGoat.copyWith(id: 'tg4'), 100.0);
      
      state = container.read(gameStateProvider);
      expect(state.herd.length, 6); // Still 6
    });

    test('Pedigree snapshotting correctly inherits traits on birth', () {
      final sire = Goat(
        id: 'sire_test',
        name: 'GrandSire',
        gender: 'buck',
        ageMonths: 24,
        weightLbs: 180.0,
        breed: 'Kiko',
        parasiteResistance: 0.9,
        growthRate: 1.3,
        sireName: 'GreatSireSire',
        damName: 'GreatSireDam',
      );

      final dam = Goat(
        id: 'dam_test',
        name: 'GrandDam',
        gender: 'doe',
        ageMonths: 20,
        weightLbs: 120.0,
        breed: 'Boer',
        parasiteResistance: 0.8,
        growthRate: 1.1,
        sireName: 'GreatDamSire',
        damName: 'GreatDamDam',
      );

      final kid = Goat.newborn(
        id: 'kid_test',
        name: 'BabyKid',
        gender: 'doe',
        sire: sire,
        dam: dam,
      );

      expect(kid.sireName, 'GrandSire');
      expect(kid.damName, 'GrandDam');
      
      // Check grandparent names snapshotted from parents
      expect(kid.sireSireName, 'GreatSireSire');
      expect(kid.sireDamName, 'GreatSireDam');
      expect(kid.damSireName, 'GreatDamSire');
      expect(kid.damDamName, 'GreatDamDam');

      // Check parents' PR snapshotted
      expect(kid.sirePR, 0.9);
      expect(kid.damPR, 0.8);
    });
  });
}
