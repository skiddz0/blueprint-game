## Minister System — Pure functions for minister lookup and agenda checking.
## See: design/gdd/minister-system.md
class_name MinisterSystem


## Check if minister agenda is met. Returns reward_pc or 0.
static func check_agenda(minister: Dictionary, kpis: Dictionary) -> int:
	var agenda: Variant = minister.get("agenda")
	if not (agenda is Dictionary):
		return 0
	var target_kpi: String = str(agenda.get("kpi", ""))
	var target_val: float = float(agenda.get("target", 999))
	if kpis.has(target_kpi):
		if float(kpis[target_kpi]["value"]) >= target_val:
			return int(agenda.get("reward_pc", 0))
	return 0
