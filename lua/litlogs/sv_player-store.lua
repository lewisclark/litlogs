local function recordExists(sid64, callback)
	local strQuery = string.format("SELECT id FROM litlogs_players WHERE sid64 = '%s';", sid64)

	LitLogs.Query(strQuery, function(data)
		local exists = (istable(data) and data[1] and isnumber(data[1].id)) and true or false

		callback(exists)
	end)
end

hook.Add("PlayerInitialSpawn", "LitLogs::PlayerStore", function(ply)
	timer.Simple(10, function() -- delay because the rpname darkrpvar isn't set instantly in this hook
		if not IsValid(ply) then return end

		local name = LitLogs.EscapeSQL(ply:getDarkRPVar("rpname") or ply:Nick())
		local sid64 = ply:SteamID64()
		local ip = ply:IPAddress():Split(":")[1]

		recordExists(sid64, function(exists)
			local strQuery

			if not exists then
				strQuery = string.format("INSERT INTO litlogs_players (sid64, lastname, lastip) VALUES ('%s', '%s', '%s');",
					sid64, name, ip)
			else
				strQuery = string.format("UPDATE litlogs_players SET lastname = '%s', lastip = '%s' WHERE sid64 = '%s';",
					name, ip, sid64)
			end

			LitLogs.Query(strQuery)
		end)
	end)
end)
