--module

local datastores = {}
local datastoreService = game:GetService("DataStoreService")
local attemps = 3


function datastores.save(UserId, Data, store)
	for i = 1, attemps do
		local Success, Err = pcall(function()

			store:SetAsync(UserId, Data)

		end)



		if Success then
			print(Data)
			break 
		else
			warn("ERROR YOUR DATA DID NOT SAVE :C",Err)
		end
		task.wait(1)
	end
end

function datastores.load(UserId, store)
	local Success, Data = pcall(function()
		return store:GetAsync(UserId) end)
	if Success then
		return Data
	else
		warn("ERROR",Data)
	end
end
return datastores

