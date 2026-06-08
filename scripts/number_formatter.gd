extends RefCounted

const SUFFIXES: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]


static func compact_int(value: int) -> String:
	return compact_float(float(value))


static func compact_float(value: float) -> String:
	var sign := "-" if value < 0.0 else ""
	var abs_v: float = absf(value)
	if abs_v < 1000.0:
		return sign + str(int(round(abs_v)))

	var tier: int = 0
	while abs_v >= 1000.0 and tier < SUFFIXES.size() - 1:
		abs_v /= 1000.0
		tier += 1

	var txt: String
	if abs_v >= 100.0:
		txt = "%.0f" % abs_v
	elif abs_v >= 10.0:
		txt = "%.1f" % abs_v
	else:
		txt = "%.2f" % abs_v

	txt = _trim_decimal_zeros(txt)
	if txt == "1000" and tier < SUFFIXES.size() - 1:
		txt = "1.00"
		tier += 1

	return sign + txt + SUFFIXES[tier]


static func _trim_decimal_zeros(txt: String) -> String:
	if not txt.contains("."):
		return txt
	if txt.ends_with(".00"):
		var base := txt.substr(0, txt.length() - 3)
		if base.length() >= 3:
			return base
		return txt
	if txt.ends_with("0"):
		return txt.substr(0, txt.length() - 1)
	return txt
