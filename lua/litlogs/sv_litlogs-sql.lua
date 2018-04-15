require("mysqloo")

local dbConn
local getAllLogCounts

local function initDbConn()
	dbConn = mysqloo.connect("host", "username", "password", "database")

	function dbConn:onConnected()
		print("LitLogs connected to the database successfully.")

		LitLogs.Query("CREATE TABLE IF NOT EXISTS litlogs_archive (id int PRIMARY KEY AUTO_INCREMENT, time int, logger varchar(32), log longtext);")
		LitLogs.Query("CREATE TABLE IF NOT EXISTS litlogs_players (id int PRIMARY KEY AUTO_INCREMENT, sid64 varchar(32), lastname varchar(64), lastip varchar(39));")

		timer.Simple(5, getAllLogCounts)
	end

	function dbConn:onConnectionFailed(err)
		print("LitLogs failed to connect to the database!", err)
	end

	dbConn:connect()
end

function getAllLogCounts()
	local strQuery = "SELECT logger, COUNT(logger) AS count FROM litlogs_archive GROUP BY logger;"

	LitLogs.Query(strQuery, function(data)
		for _, row in ipairs(data) do
			local logger = LitLogs.GetLogger(row.logger)
			if not logger then continue end

			logger:SetLogCount(row.count)
		end
	end)
end

function LitLogs.Query(strQuery, callback)
	local query = dbConn:query(strQuery)

	function query:onSuccess(data)
		if callback then callback(data) end
	end

	function query:onError(err, sql)
		if err:lower():find("lost connection") then
			timer.Simple(1, function()
				LitLogs.Query(strQuery, callback)
			end)
		else
			error("LitLogs Query Failed: " .. err)
		end
	end

	query:start()
end

function LitLogs.EscapeSQL(sql)
	return dbConn:escape(sql)
end

initDbConn()
