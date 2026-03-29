## KPI System — Pure functions for KPI calculations.
## See: design/gdd/kpi-system.md
class_name KPISystem


## Clamp a KPI value to [0, 100].
static func clamp_kpi(value: float) -> float:
	return clampf(value, 0.0, 100.0)


## Calculate average of all 5 KPIs.
static func calculate_average(kpis: Dictionary) -> float:
	var total := 0.0
	var count := 0
	for kpi_name: String in kpis:
		total += float(kpis[kpi_name]["value"])
		count += 1
	if count == 0:
		return 0.0
	return total / count


## Apply natural decay at year-end. Returns dict of { kpi_name: delta }.
static func get_decay_deltas(config: Dictionary) -> Dictionary:
	var decay_rates: Dictionary = config.get("kpis", {}).get("decay_rates", {})
	var deltas := {}
	# access_per_year and quality_per_year are the only decays
	if decay_rates.has("access_per_year"):
		deltas["access"] = float(decay_rates["access_per_year"])
	if decay_rates.has("quality_per_year"):
		deltas["quality"] = float(decay_rates["quality_per_year"])
	return deltas


## Check stagnation for each KPI. Returns dict of { kpi_name: penalty }.
## Skipped in year 2013 (no baseline).
static func get_stagnation_deltas(
	current_kpis: Dictionary,
	start_of_year_kpis: Dictionary,
	config: Dictionary,
	year: int
) -> Dictionary:
	if year <= 2013:
		return {}
	var penalty: float = float(config.get("kpis", {}).get("stagnant_penalty", -0.5))
	var deltas := {}
	for kpi_name: String in current_kpis:
		var current_val: float = float(current_kpis[kpi_name]["value"])
		var start_val: float = float(start_of_year_kpis[kpi_name]["value"])
		if absf(current_val - start_val) < 0.001:
			deltas[kpi_name] = penalty
	return deltas


## Get color zone for a KPI value: "red", "orange", or "green".
static func get_color_zone(value: float) -> String:
	if value < 45.0:
		return "red"
	elif value < 65.0:
		return "orange"
	else:
		return "green"


## Create initial KPI dictionary from config starting values.
static func create_initial_kpis(config: Dictionary) -> Dictionary:
	var starting: Dictionary = config.get("kpis", {}).get("starting_values", {})
	var kpis := {}
	var descriptions := {
		"quality": "International Standards",
		"equity": "Achievement Gap",
		"access": "Enrollment & Infrastructure",
		"unity": "Public Satisfaction",
		"efficiency": "Cost-Effectiveness",
	}
	for kpi_name: String in ["quality", "equity", "access", "unity", "efficiency"]:
		kpis[kpi_name] = {
			"name": kpi_name,
			"value": float(starting.get(kpi_name, 50)),
			"description": descriptions.get(kpi_name, ""),
		}
	return kpis
