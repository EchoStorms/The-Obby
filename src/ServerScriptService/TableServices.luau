local TableServices = {}
function TableServices.DictionaryToArray(dictionary : {})
	local array : {} = {}
	for key,v in pairs(dictionary) do
		table.insert(array,v)
	end
	return array
end
function TableServices.ArrayToDictionary(Array : {})
	local dictionary : {} = {}
	for i,v in Array do
		dictionary["slot_"..tostring(i)] = v
	end
	return dictionary
end
return TableServices
