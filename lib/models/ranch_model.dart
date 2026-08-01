class RanchState {
  final int dayCount;
  final double cash;
  final double feedLbs;
  final String weather; // 'Sunny', 'Rainy', 'Drought'
  final int currentPasture; // 1 or 2
  final double grassLevel1; // 0.0 to 100.0
  final double grassLevel2; // 0.0 to 100.0
  final List<String> ledger;
  final int barnLevel;
  final bool hasMedicalStation;
  final bool hasAutomatedWaterers;
  final bool hasQuarantinePen;

  RanchState({
    required this.dayCount,
    required this.cash,
    required this.feedLbs,
    required this.weather,
    required this.currentPasture,
    required this.grassLevel1,
    required this.grassLevel2,
    required this.ledger,
    this.barnLevel = 1,
    this.hasMedicalStation = false,
    this.hasAutomatedWaterers = false,
    this.hasQuarantinePen = false,
  });

  // Herd limit based on barn level
  int get herdCapacity {
    switch (barnLevel) {
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

  RanchState copyWith({
    int? dayCount,
    double? cash,
    double? feedLbs,
    String? weather,
    int? currentPasture,
    double? grassLevel1,
    double? grassLevel2,
    List<String>? ledger,
    int? barnLevel,
    bool? hasMedicalStation,
    bool? hasAutomatedWaterers,
    bool? hasQuarantinePen,
  }) {
    return RanchState(
      dayCount: dayCount ?? this.dayCount,
      cash: cash ?? this.cash,
      feedLbs: feedLbs ?? this.feedLbs,
      weather: weather ?? this.weather,
      currentPasture: currentPasture ?? this.currentPasture,
      grassLevel1: grassLevel1 ?? this.grassLevel1,
      grassLevel2: grassLevel2 ?? this.grassLevel2,
      ledger: ledger ?? this.ledger,
      barnLevel: barnLevel ?? this.barnLevel,
      hasMedicalStation: hasMedicalStation ?? this.hasMedicalStation,
      hasAutomatedWaterers: hasAutomatedWaterers ?? this.hasAutomatedWaterers,
      hasQuarantinePen: hasQuarantinePen ?? this.hasQuarantinePen,
    );
  }
}
