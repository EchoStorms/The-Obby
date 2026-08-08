local boolValue = script.Parent

boolValue:GetPropertyChangedSignal("Value"):Connect(function()
	print("--------------------------------------------------")
	print("Value changed to:", boolValue.Value)
	print("Change detected from this location:")
	-- This prints the entire call stack showing who caused the change
	print(debug.traceback()) 
	print("--------------------------------------------------")
end)
