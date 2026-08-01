import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goat_model.dart';
import '../models/ranch_model.dart';

class GameState {
  final RanchState ranch;
  final List<Goat> herd;
  final bool hasGuardDonkey;

  GameState({
    required this.ranch,
    required this.herd,
    this.hasGuardDonkey = false,
  });

  GameState copyWith({
    RanchState? ranch,
    List<Goat>? herd,
    bool? hasGuardDonkey,
  }) {
    return GameState(
      ranch: ranch ?? this.ranch,
      herd: herd ?? this.herd,
      hasGuardDonkey: hasGuardDonkey ?? this.hasGuardDonkey,
    );
  }
}

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(_initialState());

  static GameState _initialState() {
    final starterBuck = Goat(
      id: 'sire_starter',
      name: 'Titan',
      gender: 'buck',
      ageMonths: 18,
      weightLbs: 165.0,
      breed: 'Kiko',
      parasiteResistance: 0.85,
      growthRate: 1.2,
      sireName: 'Unknown',
      damName: 'Unknown',
    );

    final starterDoe1 = Goat(
      id: 'dam_starter_1',
      name: 'Bella',
      gender: 'doe',
      ageMonths: 16,
      weightLbs: 110.0,
      breed: 'Kiko',
      parasiteResistance: 0.75,
      growthRate: 1.0,
      sireName: 'Unknown',
      damName: 'Unknown',
    );

    final starterDoe2 = Goat(
      id: 'dam_starter_2',
      name: 'Luna',
      gender: 'doe',
      ageMonths: 14,
      weightLbs: 95.0,
      breed: 'Boer',
      parasiteResistance: 0.60,
      growthRate: 1.1,
      sireName: 'Unknown',
      damName: 'Unknown',
    );

    return GameState(
      ranch: RanchState(
        dayCount: 1,
        cash: 1200.0,
        feedLbs: 300.0,
        weather: 'Sunny',
        currentPasture: 1,
        grassLevel1: 80.0,
        grassLevel2: 100.0,
        ledger: [
          'Day 1: Welcome to HerdSim! You started your ranch with Buck Titan, Does Bella and Luna, and \$1,200 cash.',
        ],
      ),
      herd: [starterBuck, starterDoe1, starterDoe2],
      hasGuardDonkey: false,
    );
  }

  final _random = Random();

  void nextDay() {
    final nextDay = state.ranch.dayCount + 1;
    final List<String> currentLedger = List.from(state.ranch.ledger);
    
    // 1. Determine new weather
    final weatherRoll = _random.nextDouble();
    String newWeather = 'Sunny';
    if (weatherRoll < 0.15) {
      newWeather = 'Drought';
      currentLedger.insert(0, 'Day $nextDay: A severe drought has begun. Grass growth halted.');
    } else if (weatherRoll < 0.40) {
      newWeather = 'Rainy';
      currentLedger.insert(0, 'Day $nextDay: Rain today is helping the pastures recover.');
    }

    // 2. Consume and grow grass
    double grassGrown1 = 0.0;
    double grassGrown2 = 0.0;
    
    if (newWeather == 'Rainy') {
      grassGrown1 = 6.0;
      grassGrown2 = 6.0;
    } else if (newWeather == 'Sunny') {
      grassGrown1 = 2.0;
      grassGrown2 = 2.0;
    } // Drought is 0.0

    // Automated Waterer: Speeds up grass regrowth in the inactive pasture by 15%
    if (state.ranch.hasAutomatedWaterers) {
      if (state.ranch.currentPasture == 1) {
        grassGrown2 *= 1.15;
      } else {
        grassGrown1 *= 1.15;
      }
    }

    double grass1 = state.ranch.grassLevel1;
    double grass2 = state.ranch.grassLevel2;

    // Goats eat grass from current pasture (each eats 1.5% of pasture grass per day)
    final double consumptionPerGoat = 2.0;
    final double totalEating = state.herd.length * consumptionPerGoat;

    if (state.ranch.currentPasture == 1) {
      grass1 = (grass1 - totalEating + grassGrown1).clamp(0.0, 100.0);
      grass2 = (grass2 + grassGrown2).clamp(0.0, 100.0);
    } else {
      grass2 = (grass2 - totalEating + grassGrown2).clamp(0.0, 100.0);
      grass1 = (grass1 + grassGrown1).clamp(0.0, 100.0);
    }

    // 3. Feed stock consumption (if grass is depleted)
    double remainingFeed = state.ranch.feedLbs;
    bool isStarving = false;
    
    final activeGrass = state.ranch.currentPasture == 1 ? grass1 : grass2;
    if (activeGrass <= 0) {
      final double feedNeeded = state.herd.length * 2.0; // 2 lbs of feed per goat
      if (remainingFeed >= feedNeeded) {
        remainingFeed -= feedNeeded;
        currentLedger.insert(0, 'Day $nextDay: Pasture depleted. Herd ate $feedNeeded lbs from feed supply.');
      } else {
        remainingFeed = 0.0;
        isStarving = true;
        currentLedger.insert(0, 'Day $nextDay: ⚠️ Pasture depleted AND feed stock empty! Your goats are starving!');
      }
    }

    // 4. Parasite transmission setup
    bool parasiteSpreadEvent = false;
    if (!state.ranch.hasQuarantinePen && state.herd.any((g) => g.isSick)) {
      if (_random.nextDouble() < 0.10) {
        parasiteSpreadEvent = true;
      }
    }

    int infectTargetIndex = -1;
    if (parasiteSpreadEvent) {
      final healthyIndices = [];
      for (int i = 0; i < state.herd.length; i++) {
        if (!state.herd[i].isSick) {
          healthyIndices.add(i);
        }
      }
      if (healthyIndices.isNotEmpty) {
        infectTargetIndex = healthyIndices[_random.nextInt(healthyIndices.length)];
      }
    }

    // 5. Update Goats (Age, Weight, Sickness, Pregnancy)
    final List<Goat> updatedHerd = [];
    final List<Goat> newbornKids = [];

    for (int idx = 0; idx < state.herd.length; idx++) {
      final goat = state.herd[idx];
      
      // Monthly age tick (once every 30 days)
      int newAgeMonths = goat.ageMonths;
      if (nextDay % 30 == 0) {
        newAgeMonths += 1;
      }

      // Weight gain/loss
      double weightChange = 0.0;
      if (isStarving) {
        weightChange = -1.5; // Starvation weight loss
      } else {
        // Growth based on age and genetics
        if (goat.ageMonths < 24) {
          weightChange = 0.4 * goat.growthRate; // Kids grow faster
        } else {
          weightChange = 0.05; // Adults grow slower
        }
      }
      double newWeight = (goat.weightLbs + weightChange).clamp(5.0, 250.0);

      // Sickness check
      bool nowSick = goat.isSick;
      if (idx == infectTargetIndex) {
        nowSick = true;
        currentLedger.insert(0, 'Day $nextDay: ⚠️ Parasites spread! ${goat.name} caught worms from another sick herd member.');
      } else if (isStarving) {
        nowSick = true;
      } else if (!goat.isSick && _random.nextDouble() < (0.05 * (1.0 - goat.parasiteResistance))) {
        nowSick = true;
        currentLedger.insert(0, 'Day $nextDay: 🤒 ${goat.name} has contracted worms/parasites.');
      }

      // Medical Station auto-cure
      if (nowSick && state.ranch.hasMedicalStation && _random.nextDouble() < 0.15) {
        nowSick = false;
        currentLedger.insert(0, 'Day $nextDay: 💊 Medical Station care cured ${goat.name} of their parasites.');
      }

      // Sick goats have a chance of death unless treated
      if (nowSick) {
        final deathChance = state.ranch.hasMedicalStation ? 0.035 : 0.07;
        if (_random.nextDouble() < deathChance) {
          currentLedger.insert(0, 'Day $nextDay: 💀 RIP ${goat.name} passed away due to untreated illness.');
          continue; // Skip adding back to the herd list (death)
        }
      }

      // Pregnancy updates
      bool pregnant = goat.isPregnant;
      int pregDays = goat.pregnancyDays;

      if (pregnant) {
        pregDays += 1;
        if (pregDays >= 150) {
          pregnant = false;
          pregDays = 0;
          // Kidding! 1 or 2 kids
          final numKids = _random.nextDouble() < 0.4 ? 2 : 1;
          for (int i = 0; i < numKids; i++) {
            final kidGender = _random.nextBool() ? 'buck' : 'doe';
            final kidName = '${kidGender == 'buck' ? 'Buck' : 'Doe'}_${nextDay}_${_random.nextInt(100)}';
            newbornKids.add(Goat.newborn(
              id: 'kid_${nextDay}_${_random.nextInt(1000)}',
              name: kidName,
              gender: kidGender,
              sire: state.herd.firstWhere((g) => g.name == goat.sireName, orElse: () => state.herd.firstWhere((g) => g.gender == 'buck')),
              dam: goat,
            ));
          }
          currentLedger.insert(0, 'Day $nextDay: 🎉 ${goat.name} gave birth to $numKids kid(s)!');
        }
      }

      updatedHerd.add(goat.copyWith(
        ageMonths: newAgeMonths,
        weightLbs: newWeight,
        isSick: nowSick,
        isPregnant: pregnant,
        pregnancyDays: pregDays,
      ));
    }

    // Add newborns to the herd
    updatedHerd.addAll(newbornKids);

    // Enforce Barn limit check (warn player but let birth happen)
    if (updatedHerd.length > state.ranch.herdCapacity) {
      currentLedger.insert(0, 'Day $nextDay: ⚠️ OVER CAPACITY! Your herd of ${updatedHerd.length} goats exceeds your Barn limit of ${state.ranch.herdCapacity}. Upgrade your Barn or sell goats to avoid penalties!');
    }

    // 6. Random Events
    // Coyote/Predator attack (2% chance)
    if (_random.nextDouble() < 0.02) {
      if (state.hasGuardDonkey) {
        currentLedger.insert(0, 'Day $nextDay: 🫏 A coyote approached, but your Guard Donkey chased it away!');
      } else if (updatedHerd.isNotEmpty) {
        final killedGoat = updatedHerd.removeAt(_random.nextInt(updatedHerd.length));
        currentLedger.insert(0, 'Day $nextDay: 🐺 A predator attacked last night and killed ${killedGoat.name}!');
      }
    }

    state = state.copyWith(
      ranch: state.ranch.copyWith(
        dayCount: nextDay,
        feedLbs: remainingFeed,
        weather: newWeather,
        grassLevel1: grass1,
        grassLevel2: grass2,
        ledger: currentLedger,
      ),
      herd: updatedHerd,
    );
  }

  void rotatePastures() {
    final nextPasture = state.ranch.currentPasture == 1 ? 2 : 1;
    final List<String> currentLedger = List.from(state.ranch.ledger);
    currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Rotated herd to Pasture $nextPasture.');

    state = state.copyWith(
      ranch: state.ranch.copyWith(
        currentPasture: nextPasture,
        ledger: currentLedger,
      ),
    );
  }

  void buyFeed(double lbs, double cost) {
    if (state.ranch.cash < cost) return;
    
    final List<String> currentLedger = List.from(state.ranch.ledger);
    currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Purchased $lbs lbs of feed for \$$cost.');

    state = state.copyWith(
      ranch: state.ranch.copyWith(
        cash: state.ranch.cash - cost,
        feedLbs: state.ranch.feedLbs + lbs,
        ledger: currentLedger,
      ),
    );
  }

  void buyGuardDonkey() {
    const cost = 300.0;
    if (state.ranch.cash < cost || state.hasGuardDonkey) return;

    final List<String> currentLedger = List.from(state.ranch.ledger);
    currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Purchased a Guard Donkey for \$300 to protect the herd.');

    state = state.copyWith(
      hasGuardDonkey: true,
      ranch: state.ranch.copyWith(
        cash: state.ranch.cash - cost,
        ledger: currentLedger,
      ),
    );
  }

  void buyUpgrade(String upgradeId, double cost) {
    if (state.ranch.cash < cost) return;
    
    RanchState updatedRanch = state.ranch.copyWith(
      cash: state.ranch.cash - cost,
    );

    final List<String> currentLedger = List.from(state.ranch.ledger);

    switch (upgradeId) {
      case 'barn':
        updatedRanch = updatedRanch.copyWith(barnLevel: state.ranch.barnLevel + 1);
        currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Upgraded Barn to Level ${updatedRanch.barnLevel} (Capacity: ${updatedRanch.herdCapacity} goats) for \$${cost.toStringAsFixed(0)}.');
        break;
      case 'medical':
        updatedRanch = updatedRanch.copyWith(hasMedicalStation: true);
        currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Constructed a Medical Station for \$${cost.toStringAsFixed(0)}.');
        break;
      case 'waterer':
        updatedRanch = updatedRanch.copyWith(hasAutomatedWaterers: true);
        currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Installed Automated Waterers in pastures for \$${cost.toStringAsFixed(0)}.');
        break;
      case 'quarantine':
        updatedRanch = updatedRanch.copyWith(hasQuarantinePen: true);
        currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Built a Quarantine Pen to prevent parasite spread for \$${cost.toStringAsFixed(0)}.');
        break;
    }

    state = state.copyWith(
      ranch: updatedRanch.copyWith(ledger: currentLedger),
    );
  }

  void treatGoat(String id) {
    final cost = state.ranch.hasMedicalStation ? 10.0 : 25.0;
    if (state.ranch.cash < cost) return;

    final goatIndex = state.herd.indexWhere((g) => g.id == id);
    if (goatIndex == -1 || !state.herd[goatIndex].isSick) return;

    final List<Goat> updatedHerd = List.from(state.herd);
    final sickGoat = updatedHerd[goatIndex];
    updatedHerd[goatIndex] = sickGoat.copyWith(isSick: false);

    final List<String> currentLedger = List.from(state.ranch.ledger);
    currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Treated ${sickGoat.name} with dewormer for \$${cost.toStringAsFixed(0)}. Sick status cleared.');

    state = state.copyWith(
      herd: updatedHerd,
      ranch: state.ranch.copyWith(
        cash: state.ranch.cash - cost,
        ledger: currentLedger,
      ),
    );
  }

  void sellGoat(String id, double finalBid) {
    final goatIndex = state.herd.indexWhere((g) => g.id == id);
    if (goatIndex == -1) return;

    final soldGoat = state.herd[goatIndex];
    final List<Goat> updatedHerd = List.from(state.herd)..removeAt(goatIndex);

    final List<String> currentLedger = List.from(state.ranch.ledger);
    currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Sold ${soldGoat.name} at auction for \$${finalBid.toStringAsFixed(2)}.');

    state = state.copyWith(
      herd: updatedHerd,
      ranch: state.ranch.copyWith(
        cash: state.ranch.cash + finalBid,
        ledger: currentLedger,
      ),
    );
  }

  void buyGoat(Goat newGoat, double cost) {
    if (state.ranch.cash < cost) return;
    if (state.herd.length >= state.ranch.herdCapacity) return;

    final List<Goat> updatedHerd = List.from(state.herd)..add(newGoat);
    final List<String> currentLedger = List.from(state.ranch.ledger);
    currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Purchased ${newGoat.name} for \$$cost.');

    state = state.copyWith(
      herd: updatedHerd,
      ranch: state.ranch.copyWith(
        cash: state.ranch.cash - cost,
        ledger: currentLedger,
      ),
    );
  }

  void breedGoats(String sireId, String damId) {
    if (state.herd.length >= state.ranch.herdCapacity) return;

    final sire = state.herd.firstWhere((g) => g.id == sireId);
    final dam = state.herd.firstWhere((g) => g.id == damId);

    if (sire.gender != 'buck' || dam.gender != 'doe' || dam.isPregnant) return;

    final List<Goat> updatedHerd = List.from(state.herd);
    final damIndex = updatedHerd.indexWhere((g) => g.id == damId);
    updatedHerd[damIndex] = dam.copyWith(
      isPregnant: true,
      pregnancyDays: 0,
      sireName: sire.name,
      damName: dam.name,
    );

    final List<String> currentLedger = List.from(state.ranch.ledger);
    currentLedger.insert(0, 'Day ${state.ranch.dayCount}: Breed buck ${sire.name} to doe ${dam.name}. 150 days to kiddings.');

    state = state.copyWith(
      herd: updatedHerd,
      ranch: state.ranch.copyWith(
        ledger: currentLedger,
      ),
    );
  }
}

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});
