## Scenario Engine — Pure functions for scenario triggering and callback chains.
## See: design/gdd/scenario-engine.md
class_name ScenarioEngine


## Check if any scenario should trigger for the given year and display month (1-12).
## Returns the scenario dict (possibly modified by callbacks) or null.
static func check_for_scenario(
	year: int,
	month_0indexed: int,
	scenarios: Array,
	scenarios_completed: Dictionary
) -> Variant:
	var display_month: int = month_0indexed + 1
	for scenario: Dictionary in scenarios:
		var sid: String = str(scenario.get("id", ""))
		if sid == "" or scenarios_completed.has(sid):
			continue
		if int(scenario.get("year", 0)) == year and int(scenario.get("month", 0)) == display_month:
			return apply_callback_chains(scenario, scenarios_completed)
	return null


## Check if the player can afford at least one choice.
static func can_afford_any_choice(
	scenario: Dictionary,
	budget: float,
	pc: int
) -> bool:
	for choice: Dictionary in scenario.get("choices", []):
		if can_afford_choice(choice, budget, pc):
			return true
	return false


## Check if the player can afford a specific choice.
static func can_afford_choice(
	choice: Dictionary,
	budget: float,
	pc: int
) -> bool:
	var costs: Dictionary = choice.get("costs", {})
	var budget_cost: float = float(costs.get("budget", 0))
	var pc_cost: int = int(costs.get("pc", 0))
	return budget >= budget_cost and pc >= pc_cost


## Apply callback chains to modify a scenario based on prior choices.
static func apply_callback_chains(
	scenario: Dictionary,
	scenarios_completed: Dictionary
) -> Dictionary:
	var scenario_id: String = str(scenario.get("id", ""))
	match scenario_id:
		"scenario_017":  # Primary Exam Reform Implementation ← scenario_011 debate
			return _apply_upsr_chain(scenario, scenarios_completed)
		"scenario_015":  # School Reopening ← scenario_014 COVID response
			return _apply_covid_chain(scenario, scenarios_completed)
		"scenario_016":  # Learning Loss ← scenario_014 COVID + scenario_015 Reopening
			return _apply_learning_loss_chain(scenario, scenarios_completed)
		"scenario_020":  # PT3 Reform ← scenario_009 Exam Leak
			return _apply_exam_reform_chain(scenario, scenarios_completed)
		"scenario_024":  # AI in Education ← scenario_012 Digital Divide
			return _apply_digital_chain(scenario, scenarios_completed)
	return scenario


## Primary exam reform callback chain implementation.
static func _apply_upsr_chain(
	scenario: Dictionary,
	scenarios_completed: Dictionary
) -> Dictionary:
	# Find the debate choice
	var debate_choice: Variant = null
	for sid: String in scenarios_completed:
		var choice_id: String = str(scenarios_completed[sid])
		if choice_id.begins_with("upsr_"):
			debate_choice = choice_id
			break

	var modified := _deep_clone(scenario)
	if modified.is_empty():
		return scenario

	var choices: Array = modified.get("choices", [])
	for choice: Dictionary in choices:
		var effects: Dictionary = choice.get("effects", {})
		var costs: Dictionary = choice.get("costs", {})

		if debate_choice == "upsr_a":
			effects["unity"] = float(effects.get("unity", 0)) + 2
			if costs.has("pc"):
				costs["pc"] = maxi(0, int(costs["pc"]) - 5)
		elif debate_choice == "upsr_c":
			effects["unity"] = float(effects.get("unity", 0)) - 2
			if costs.has("pc"):
				costs["pc"] = int(costs["pc"]) + 5
		elif debate_choice == "cannot_afford" or debate_choice == null:
			effects["unity"] = float(effects.get("unity", 0)) - 1
			if costs.has("pc"):
				costs["pc"] = int(costs["pc"]) + 3
		# upsr_b = default, no modification

		choice["effects"] = effects
		choice["costs"] = costs

	return modified


## COVID response chain: how you handled COVID affects school reopening.
static func _apply_covid_chain(
	scenario: Dictionary,
	scenarios_completed: Dictionary
) -> Dictionary:
	var covid_choice: String = str(scenarios_completed.get("scenario_014", ""))
	if covid_choice == "":
		return scenario

	var modified := _deep_clone(scenario)
	if modified.is_empty():
		return scenario

	for choice: Dictionary in modified.get("choices", []):
		var effects: Dictionary = choice.get("effects", {})
		var costs: Dictionary = choice.get("costs", {})

		if covid_choice == "covid_a":
			# Heavy investment → reopening is easier and cheaper
			effects["access"] = float(effects.get("access", 0)) + 2
			if costs.has("budget"):
				costs["budget"] = maxi(0, int(costs["budget"]) - 5)
		elif covid_choice == "covid_c":
			# Minimal response → reopening is harder
			effects["access"] = float(effects.get("access", 0)) - 2
			effects["equity"] = float(effects.get("equity", 0)) - 2
		# covid_b = balanced, no modification

	return modified


## Learning loss chain: prior COVID + reopening choices compound.
static func _apply_learning_loss_chain(
	scenario: Dictionary,
	scenarios_completed: Dictionary
) -> Dictionary:
	var covid_choice: String = str(scenarios_completed.get("scenario_014", ""))
	var reopen_choice: String = str(scenarios_completed.get("scenario_015", ""))
	if covid_choice == "" and reopen_choice == "":
		return scenario

	var modified := _deep_clone(scenario)
	if modified.is_empty():
		return scenario

	for choice: Dictionary in modified.get("choices", []):
		var effects: Dictionary = choice.get("effects", {})
		var costs: Dictionary = choice.get("costs", {})

		# COVID impact
		if covid_choice == "covid_a":
			effects["quality"] = float(effects.get("quality", 0)) + 2
		elif covid_choice == "covid_c" or covid_choice == "cannot_afford":
			effects["quality"] = float(effects.get("quality", 0)) - 2

		# Reopening impact
		if reopen_choice == "reopen_c":
			# Comprehensive reopening → less learning loss
			effects["quality"] = float(effects.get("quality", 0)) + 2
			if costs.has("budget"):
				costs["budget"] = maxi(0, int(costs["budget"]) - 5)
		elif reopen_choice == "reopen_b":
			# Urban-first → equity suffers
			effects["equity"] = float(effects.get("equity", 0)) - 2

	return modified


## Exam reform chain: how you handled the leak affects PT3 reform appetite.
static func _apply_exam_reform_chain(
	scenario: Dictionary,
	scenarios_completed: Dictionary
) -> Dictionary:
	var leak_choice: String = str(scenarios_completed.get("scenario_009", ""))
	if leak_choice == "":
		return scenario

	var modified := _deep_clone(scenario)
	if modified.is_empty():
		return scenario

	for choice: Dictionary in modified.get("choices", []):
		var effects: Dictionary = choice.get("effects", {})
		var costs: Dictionary = choice.get("costs", {})

		if leak_choice == "leak_a":
			# Full investigation built trust → reform is easier
			effects["unity"] = float(effects.get("unity", 0)) + 3
			if costs.has("pc"):
				costs["pc"] = maxi(0, int(costs["pc"]) - 5)
		elif leak_choice == "leak_c":
			# Downplayed → public distrusts exam changes
			effects["unity"] = float(effects.get("unity", 0)) - 3
			if costs.has("pc"):
				costs["pc"] = int(costs["pc"]) + 5
		# leak_b = moderate, no modification

	return modified


## Digital chain: prior digital divide response affects AI adoption readiness.
static func _apply_digital_chain(
	scenario: Dictionary,
	scenarios_completed: Dictionary
) -> Dictionary:
	var digital_choice: String = str(scenarios_completed.get("scenario_012", ""))
	if digital_choice == "":
		return scenario

	var modified := _deep_clone(scenario)
	if modified.is_empty():
		return scenario

	for choice: Dictionary in modified.get("choices", []):
		var effects: Dictionary = choice.get("effects", {})
		var costs: Dictionary = choice.get("costs", {})

		if digital_choice == "digital_a":
			# Heavy infra investment → AI adoption smoother
			effects["quality"] = float(effects.get("quality", 0)) + 2
			effects["equity"] = float(effects.get("equity", 0)) + 2
		elif digital_choice == "digital_c":
			# PPP approach → strong foundation
			effects["quality"] = float(effects.get("quality", 0)) + 3
		elif digital_choice == "cannot_afford":
			# Never addressed digital divide → AI widens gap
			effects["equity"] = float(effects.get("equity", 0)) - 3
		# digital_b = moderate, no modification

	return modified


## Deep clone a dictionary via JSON round-trip.
static func _deep_clone(source: Dictionary) -> Dictionary:
	var json_str := JSON.stringify(source)
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return {}
	return json.data
