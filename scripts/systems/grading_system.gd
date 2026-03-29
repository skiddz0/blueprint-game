## Grading System — Pure function for grade calculation.
## See: design/gdd/grading-system.md
class_name GradingSystem


## Calculate final grade from average KPI using config thresholds.
static func calculate_grade(avg_kpi: float, config: Dictionary) -> String:
	var thresholds: Dictionary = config.get("kpis", {}).get("grade_thresholds", {})
	if avg_kpi >= float(thresholds.get("s_rank", 80)):
		return "S"
	elif avg_kpi >= float(thresholds.get("a_rank", 75)):
		return "A"
	elif avg_kpi >= float(thresholds.get("b_rank", 65)):
		return "B"
	elif avg_kpi >= float(thresholds.get("c_rank", 55)):
		return "C"
	elif avg_kpi >= float(thresholds.get("d_rank", 45)):
		return "D"
	else:
		return "F"
