## Shift System — Pure functions for shift XP and leveling.
## See: design/gdd/shift-system.md
class_name ShiftSystem


## Calculate total shift bonus for a given KPI across all shifts.
static func get_total_kpi_bonus(shifts: Dictionary, kpi_name: String) -> float:
	var total := 0.0
	for shift_id: int in shifts:
		var shift: Dictionary = shifts[shift_id]
		if shift.get("targetKpi", "") == kpi_name:
			total += float(shift.get("level", 0))
	return total
