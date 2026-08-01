extends Control

# UI Node paths (Assuming standard Control-based setup)
@onready var info_label = $VBoxContainer/InfoLabel
@onready var bid_amount_label = $VBoxContainer/BidDisplay/AmountLabel
@onready var bidder_name_label = $VBoxContainer/BidDisplay/BidderLabel
@onready var log_text = $VBoxContainer/LogText
@onready var accept_button = $VBoxContainer/ActionButtons/AcceptButton
@onready var reject_button = $VBoxContainer/ActionButtons/RejectButton
@onready var bidding_timer = $BiddingTimer

var goat: Goat
var current_bid: float = 0.0
var current_bidder: String = "No bids yet"
var is_bidding_active: bool = true
var bid_count: int = 0
var bid_history: Array[String] = []

class BidderProfile:
	var name: String
	var base_value: float
	var max_multiplier: float
	var preference_bonus: float
	var dialogues: Array[String]

	func _init(p_name: String, p_base: float, p_max: float, p_bonus: float, p_dial: Array[String]):
		name = p_name
		base_value = p_base
		max_multiplier = p_max
		preference_bonus = p_bonus
		dialogues = p_dial

	func get_max_bid() -> float:
		return (base_value * max_multiplier) + preference_bonus

var bidders: Array[BidderProfile] = []

func setup(p_goat: Goat):
	goat = p_goat
	_calculate_bidders()
	
	# Start timer
	bidding_timer.wait_time = 1.2
	bidding_timer.one_shot = false
	bidding_timer.timeout.connect(_on_bidding_timer_timeout)
	bidding_timer.start()

func _calculate_bidders():
	var base_value = goat.weight_lbs * 1.5
	base_value += goat.parasite_resistance * 150.0
	base_value += goat.growth_rate * 100.0
	if goat.is_sick:
		base_value *= 0.4

	bidders = [
		BidderProfile.new(
			"Commercial Meat Buyer 🍖",
			base_value,
			0.3 if goat.is_sick else 1.15,
			40.0 if goat.weight_lbs > 120 else 0.0,
			[
				"Nice heavy frame on this one!",
				"Look at that market weight.",
				"Good choice for a commercial meat herd."
			]
		),
		BidderProfile.new(
			"Seedstock Breeder 🧬",
			base_value,
			1.45 if (goat.parasite_resistance > 0.8 and not goat.is_sick) else 0.8,
			75.0 if goat.parasite_resistance > 0.85 else 0.0,
			[
				"Superb parasite resistance genes!",
				"This pedigree would be great for my breeding line.",
				"Stellar genetics here."
			]
		),
		BidderProfile.new(
			"Hobby Farmer 🏡",
			base_value,
			0.6 if goat.is_sick else 1.25,
			30.0 if goat.age_months < 6 else 10.0,
			[
				"What a cute goat, would look great on my farm!",
				"Looks very healthy and well-behaved.",
				"I'd love to add this one to my homestead."
			]
		)
	]

	current_bid = clampf(base_value * 0.6, 10.0, 9999.0)
	_add_log("Auctioneer: Starting the bidding at $%0.0f..." % current_bid)
	_update_ui()

func _on_bidding_timer_timeout():
	# Find bidders who can raise the bid
	var available_bidders: Array[BidderProfile] = []
	for b in bidders:
		if b.get_max_bid() > current_bid:
			available_bidders.append(b)

	if available_bidders.size() == 0 or bid_count >= 7 or (bid_count >= 3 and randf() < 0.25):
		# End auction
		is_bidding_active = false
		bidding_timer.stop()
		_add_log("Auctioneer: Going once... Going twice... Sold!")
		_update_ui()
		return

	# Raise bid
	var active_bidder = available_bidders[randi() % available_bidders.size()]
	var raise = clampf(active_bidder.base_value * (0.05 + randf() * 0.07), 5.0, 50.0)
	var next_bid = current_bid + raise

	if next_bid > active_bidder.get_max_bid():
		next_bid = active_bidder.get_max_bid()

	if next_bid > current_bid:
		current_bid = next_bid
		current_bidder = active_bidder.name
		bid_count += 1
		
		var dialogue = active_bidder.dialogues[randi() % active_bidder.dialogues.size()]
		_add_log("%s: Bid $%0.0f! \"%s\"" % [active_bidder.name, current_bid, dialogue])
		_update_ui()

func _add_log(msg: String):
	bid_history.insert(0, msg)
	# Update RichTextLabel or TextEdit
	if log_text:
		log_text.text = "\n".join(bid_history)

func _update_ui():
	if not is_inside_tree(): return
	info_label.text = "%s | %s | %d mo | %0.0f lbs" % [goat.breed, goat.get_gender_display(), goat.age_months, goat.weight_lbs]
	bid_amount_label.text = "$%0.2f" % current_bid
	bidder_name_label.text = "Bidder: " + current_bidder if is_bidding_active else "Winning Bidder: " + current_bidder
	
	accept_button.disabled = is_bidding_active
	reject_button.text = "Cancel" if is_bidding_active else "Reject"

func _on_accept_button_pressed():
	GameManager.sell_goat(goat.id, current_bid)
	queue_free()

func _on_reject_button_pressed():
	queue_free()
