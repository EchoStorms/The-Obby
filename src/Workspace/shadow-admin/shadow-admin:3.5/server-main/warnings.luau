local warnings = {}
function start(plr)
	warnings[plr] = {}
end
function add(plr,warning)
	table.insert(warnings[plr],{warningnumber = warning.Number,reason = warning.Reason})
end
return warnings
