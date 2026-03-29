## Resource System — Pure functions for budget and political capital calculations.
## See: design/gdd/resource-system.md
class_name ResourceSystem


## Calculate which wave a year belongs to.
static func get_wave(year: int) -> int:
	if year <= 2015:
		return 1
	elif year <= 2020:
		return 2
	else:
		return 3


## Get base budget for a wave from config.
static func get_base_budget(wave: int, config: Dictionary) -> float:
	var waves: Dictionary = config.get("waves", {})
	var key := "wave_" + str(wave)
	return float(waves.get(key, {}).get("base_budget", 100))


## Look up performance modifier based on average KPI.
static func get_performance_modifier(avg_kpi: float, config: Dictionary) -> float:
	var mods: Dictionary = config.get("performance_modifiers", {})
	if avg_kpi < 45.0:
		return float(mods.get("avg_below_45", -0.25))
	elif avg_kpi < 55.0:
		return float(mods.get("avg_45_to_54", -0.10))
	elif avg_kpi < 65.0:
		return float(mods.get("avg_55_to_64", 0.0))
	elif avg_kpi < 75.0:
		return float(mods.get("avg_65_to_74", 0.10))
	else:
		return float(mods.get("avg_75_plus", 0.25))


## Calculate next year's budget.
static func calculate_next_year_budget(
	wave: int,
	avg_kpi: float,
	has_october_penalty: bool,
	config: Dictionary
) -> float:
	var base: float = get_base_budget(wave, config)
	var modifier: float = get_performance_modifier(avg_kpi, config)
	var budget: float = base * (1.0 + modifier)

	if has_october_penalty:
		var penalty_pct: float = float(config.get("resources", {}).get("october_penalty_percent", 20))
		budget *= (1.0 - penalty_pct / 100.0)

	return maxf(10.0, budget)


## Calculate adjusted initiative cost with minister discount and efficiency penalty.
static func calculate_initiative_cost(
	base_cost_rm: float,
	efficiency_kpi: float,
	minister_discount: float,
	config: Dictionary
) -> float:
	var cost := base_cost_rm

	# Minister category discount (e.g., -10 means 10% cheaper)
	if minister_discount < 0.0:
		cost *= (1.0 + minister_discount / 100.0)

	# Efficiency crisis: <40 = +50% cost
	var threshold: float = float(config.get("efficiency", {}).get("penalty_threshold", 40))
	var increase: float = float(config.get("efficiency", {}).get("penalty_cost_increase", 50))
	if efficiency_kpi < threshold:
		cost *= (1.0 + increase / 100.0)

	return maxf(1.0, snappedf(cost, 0.1))


## Get minister cost discount for a given initiative category.
static func get_minister_discount(
	cost_modifiers: Variant,
	initiative_category: String
) -> float:
	if cost_modifiers == null or not (cost_modifiers is Dictionary):
		return 0.0
	var key := initiative_category + "_initiatives"
	return float(cost_modifiers.get(key, 0))


## Calculate PC regeneration from Unity KPI at year-end.
static func calculate_pc_regen(unity_kpi: float) -> int:
	return int(floorf(unity_kpi / 5.0))


## Get bureaucracy penalty per initiative.
static func get_bureaucracy_penalty(year: int, config: Dictionary) -> float:
	var eff_config: Dictionary = config.get("efficiency", {})
	if year >= 2024:
		return float(eff_config.get("bureaucracy_penalty_after_du", -0.25))
	return float(eff_config.get("bureaucracy_penalty_per_initiative", -0.5))
