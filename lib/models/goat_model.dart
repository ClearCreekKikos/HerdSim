import 'dart:math';

class Goat {
  final String id;
  final String name;
  final String gender; // 'buck' or 'doe'
  final int ageMonths;
  final double weightLbs;
  final String breed;
  final double parasiteResistance; // 0.0 to 1.0 (higher = better)
  final double growthRate; // 0.5 to 1.5 (higher = grows faster)
  final bool isSick;
  final bool isPregnant;
  final int pregnancyDays;
  final String sireName;
  final String damName;

  Goat({
    required this.id,
    required this.name,
    required this.gender,
    required this.ageMonths,
    required this.weightLbs,
    required this.breed,
    required this.parasiteResistance,
    required this.growthRate,
    this.isSick = false,
    this.isPregnant = false,
    this.pregnancyDays = 0,
    required this.sireName,
    required this.damName,
  });

  String get genderDisplay => gender == 'buck' ? 'Buck' : 'Doe';
  
  String get statusDisplay {
    if (isSick) return 'Sick 🤒';
    if (isPregnant) return 'Pregnant 🤰 (${(pregnancyDays / 30).toStringAsFixed(1)}m)';
    return 'Healthy 🟢';
  }

  Goat copyWith({
    String? id,
    String? name,
    String? gender,
    int? ageMonths,
    double? weightLbs,
    String? breed,
    double? parasiteResistance,
    double? growthRate,
    bool? isSick,
    bool? isPregnant,
    int? pregnancyDays,
    String? sireName,
    String? damName,
  }) {
    return Goat(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageMonths: ageMonths ?? this.ageMonths,
      weightLbs: weightLbs ?? this.weightLbs,
      breed: breed ?? this.breed,
      parasiteResistance: parasiteResistance ?? this.parasiteResistance,
      growthRate: growthRate ?? this.growthRate,
      isSick: isSick ?? this.isSick,
      isPregnant: isPregnant ?? this.isPregnant,
      pregnancyDays: pregnancyDays ?? this.pregnancyDays,
      sireName: sireName ?? this.sireName,
      damName: damName ?? this.damName,
    );
  }

  // Generate a random newborn kid inheriting genetics with mutations
  factory Goat.newborn({
    required String id,
    required String name,
    required String gender,
    required Goat sire,
    required Goat dam,
  }) {
    final random = Random();
    
    // Average traits with +/- 10% random mutation
    final basePR = (sire.parasiteResistance + dam.parasiteResistance) / 2;
    final mutationPR = (random.nextDouble() * 0.2) - 0.1; // -10% to +10%
    final parasiteResistance = (basePR + mutationPR).clamp(0.1, 1.0);

    final baseGR = (sire.growthRate + dam.growthRate) / 2;
    final mutationGR = (random.nextDouble() * 0.2) - 0.1;
    final growthRate = (baseGR + mutationGR).clamp(0.5, 2.0);

    // Primary breed matches mother or father, or cross
    final breed = random.nextBool() ? sire.breed : dam.breed;

    return Goat(
      id: id,
      name: name,
      gender: gender,
      ageMonths: 0,
      weightLbs: 6.0 + (random.nextDouble() * 3), // Birth weight 6-9 lbs
      breed: breed,
      parasiteResistance: parasiteResistance,
      growthRate: growthRate,
      sireName: sire.name,
      damName: dam.name,
    );
  }
}
