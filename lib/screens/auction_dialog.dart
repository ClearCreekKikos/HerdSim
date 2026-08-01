import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goat_model.dart';
import '../providers/game_provider.dart';

class AuctionDialog extends ConsumerStatefulWidget {
  final Goat goat;

  const AuctionDialog({super.key, required this.goat});

  @override
  ConsumerState<AuctionDialog> createState() => _AuctionDialogState();
}

class _AuctionDialogState extends ConsumerState<AuctionDialog> {
  final List<String> _bidHistory = [];
  double _currentBid = 0.0;
  String _currentBidder = "No bids yet";
  bool _isBiddingActive = true;
  Timer? _biddingTimer;
  int _bidCount = 0;
  final Random _random = Random();

  // Bidders with their preferences
  late final List<_BidderProfile> _bidders;

  @override
  void initState() {
    super.initState();
    _calculateBidders();
    _startAuction();
  }

  @override
  void dispose() {
    _biddingTimer?.cancel();
    super.dispose();
  }

  void _calculateBidders() {
    final goat = widget.goat;
    double baseValue = goat.weightLbs * 1.5;
    baseValue += goat.parasiteResistance * 150.0;
    baseValue += goat.growthRate * 100.0;
    if (goat.isSick) baseValue *= 0.4;

    _bidders = [
      _BidderProfile(
        name: "Commercial Meat Buyer 🍖",
        maxMultiplier: goat.isSick ? 0.3 : 1.15,
        preferenceBonus: goat.weightLbs > 120 ? 40.0 : 0.0,
        dialogues: [
          "Nice heavy frame on this one!",
          "Look at that market weight.",
          "Good choice for a commercial meat herd."
        ],
        baseValue: baseValue,
      ),
      _BidderProfile(
        name: "Seedstock Breeder 🧬",
        maxMultiplier: goat.parasiteResistance > 0.8 && !goat.isSick ? 1.45 : 0.8,
        preferenceBonus: goat.parasiteResistance > 0.85 ? 75.0 : 0.0,
        dialogues: [
          "Superb parasite resistance genes!",
          "This pedigree would be great for my breeding line.",
          "Stellar genetics here."
        ],
        baseValue: baseValue,
      ),
      _BidderProfile(
        name: "Hobby Farmer 🏡",
        maxMultiplier: goat.isSick ? 0.6 : 1.25,
        preferenceBonus: goat.ageMonths < 6 ? 30.0 : 10.0, // Loves kids
        dialogues: [
          "What a cute goat, would look great on my farm!",
          "Looks very healthy and well-behaved.",
          "I'd love to add this one to my homestead."
        ],
        baseValue: baseValue,
      ),
    ];

    // Starting bid is 60% of base value
    _currentBid = (baseValue * 0.6).clamp(10.0, double.infinity);
    _bidHistory.add("Auctioneer: Starting the bidding at \$${_currentBid.toStringAsFixed(0)}...");
  }

  void _startAuction() {
    _biddingTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) return;

      // Randomly select a bidder who wants to raise the bid
      final availableBidders = _bidders.where((b) => b.maxBid > _currentBid).toList();

      if (availableBidders.isEmpty || _bidCount >= 7 || (_bidCount >= 3 && _random.nextDouble() < 0.25)) {
        // Bidding ends
        setState(() {
          _isBiddingActive = false;
          _biddingTimer?.cancel();
          _bidHistory.insert(0, "Auctioneer: Going once... Going twice... Sold!");
        });
        return;
      }

      final activeBidder = availableBidders[_random.nextInt(availableBidders.length)];
      
      // Calculate raise amount (between 5% and 12% of base value, or smaller towards the end)
      double raise = (activeBidder.baseValue * (0.05 + _random.nextDouble() * 0.07)).clamp(5.0, 50.0);
      double nextBid = _currentBid + raise;

      // Clamp to bidder's absolute max
      if (nextBid > activeBidder.maxBid) {
        nextBid = activeBidder.maxBid;
      }

      if (nextBid > _currentBid) {
        setState(() {
          _currentBid = nextBid;
          _currentBidder = activeBidder.name;
          _bidCount++;
          
          // Random dialogue
          final dialogue = activeBidder.dialogues[_random.nextInt(activeBidder.dialogues.length)];
          _bidHistory.insert(0, "${activeBidder.name}: Bid \$${_currentBid.toStringAsFixed(0)}! \"$dialogue\"");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.gavel, color: Colors.amber, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text("Livestock Auction: ${widget.goat.name}")),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goat info summary card
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      "${widget.goat.breed} | ${widget.goat.genderDisplay} | ${widget.goat.ageMonths} mo",
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Weight: ${widget.goat.weightLbs.toStringAsFixed(0)} lbs | PR: ${(widget.goat.parasiteResistance * 100).toStringAsFixed(0)}%",
                      style: theme.textTheme.bodySmall,
                    ),
                    if (widget.goat.isSick) ...[
                      const SizedBox(height: 4),
                      Text("🤒 SICK DISCOUNT APPLIED", style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold, fontSize: 11)),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live bid amount display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text("CURRENT HIGHEST BID", style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(
                    "\$${_currentBid.toStringAsFixed(2)}",
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isBiddingActive)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isBiddingActive ? "Bidder: $_currentBidder" : "Winning Bidder: $_currentBidder",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _isBiddingActive ? FontWeight.normal : FontWeight.bold,
                          color: _isBiddingActive ? Colors.white70 : Colors.teal.shade200,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bid history log list
            Text("Auction Log", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.dividerColor),
              ),
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _bidHistory.length,
                itemBuilder: (context, index) {
                  final text = _bidHistory[index];
                  bool isAuctioneer = text.startsWith("Auctioneer");
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isAuctioneer ? Colors.amber.shade200 : Colors.white70,
                        fontWeight: isAuctioneer ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _biddingTimer?.cancel();
            Navigator.pop(context);
          },
          child: Text(_isBiddingActive ? "Cancel Auction" : "Reject Bid", style: const TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: _isBiddingActive
              ? null
              : () {
                  ref.read(gameStateProvider.notifier).sellGoat(widget.goat.id, _currentBid);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Sold ${widget.goat.name} for \$${_currentBid.toStringAsFixed(2)}!")),
                  );
                },
          child: const Text("Accept Bid & Sell"),
        ),
      ],
    );
  }
}

class _BidderProfile {
  final String name;
  final double baseValue;
  final double maxMultiplier;
  final double preferenceBonus;
  final List<String> dialogues;

  _BidderProfile({
    required this.name,
    required this.baseValue,
    required this.maxMultiplier,
    required this.preferenceBonus,
    required this.dialogues,
  });

  double get maxBid => (baseValue * maxMultiplier) + preferenceBonus;
}
