class RanchState {
  final int dayCount;
  final double cash;
  final double feedLbs;
  final String weather; // 'Sunny', 'Rainy', 'Drought'
  final int currentPasture; // 1 or 2
  final double grassLevel1; // 0.0 to 100.0
  final double grassLevel2; // 0.0 to 100.0
  final List<String> ledger;

  RanchState({
    required this.dayCount,
    required this.cash,
    required this.feedLbs,
    required this.weather,
    required this.currentPasture,
    required this.grassLevel1,
    required this.grassLevel2,
    required this.ledger,
  });

  RanchState copyWith({
    int? dayCount,
    double? cash,
    double? feedLbs,
    String? weather,
    int? currentPasture,
    double? grassLevel1,
    double? grassLevel2,
    List<String>? ledger,
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
    );
  }
}
