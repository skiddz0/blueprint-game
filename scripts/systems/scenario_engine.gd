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
	if str(scenario.get("name", "")) == "UPSR Abolishment Implementation":
		return _apply_upsr_chain(scenario, scenarios_completed)
	return scenario


## UPSR callback chain implementation.
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

	# Deep clone via JSON round-trip
	var json_str := JSON.stringify(scenario)
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return scenario
	var modified: Dictionary = json.data

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
