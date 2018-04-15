function LitLogs.Logger(name)
	local logger = {}

	logger.name = name
	logger.logCount = 0
	logger.logs = {}
	logger.hooks = {}

	function logger:GetName()
		return self.name
	end

	function logger:GetLogs()
		return self.logs
	end

	function logger:GetLogCount() -- Total amount of logs for this logger (self.logs table and archive)
		return self.logCount
	end

	function logger:GetPageCount() -- Total amount of pages for this logger (self.logs table and archive)
		return math.ceil(self:GetLogCount() / LitLogs.LOGS_PER_PAGE)
	end

	function logger:SetLogCount(i)
		self.logCount = i
	end

	function logger:GetLogsForPage(page, callback)
		LitLogs.GetLogsFromLogger(self, page, callback)
	end

	function logger:Search(page, needle, callback)
		LitLogs.SearchLogger(self, page, needle, callback)
	end

	function logger:HookEvent(event, callback)
		local identifier = "LitLogs::" .. self:GetName()

		hook.Add(event, identifier, callback)
		self.hooks[event] = callback
	end

	function logger:Log(format, ...)
		local args = {...}

		for k, v in ipairs(args) do
			args[k] = LitLogs.Format(v) or "nil"
		end

		self:__InsertLog(string.format(format, unpack(args)))
	end

	function logger:SendLogsToArchive(callback)
		local logs = self:GetLogs()

		if #logs <= 0 then
			if callback then callback() end

			return
		end

		local queryFmt = "('" .. self:GetName() .. "', %s, '%s'), "
		local strQuery = "INSERT INTO litlogs_archive (logger, time, log) VALUES "

		for _, log in ipairs(logs) do
			strQuery = strQuery .. string.format(queryFmt, log.time, LitLogs.EscapeSQL(log.log))
		end

		strQuery = string.sub(strQuery, 1, #strQuery - 2) -- Strip ') ' and append ;
		strQuery = strQuery .. ";"

		self:SetLogCount(self:GetLogCount() + #logs)
		self:__ClearLogs()

		LitLogs.Query(strQuery, function()
			if callback then callback() end
		end)
	end

	function logger:__ClearLogs()
		self.logs = {}
	end

	function logger:__InsertLog(log)
		self.logs[#self.logs + 1] = {
			["time"] = os.time(),
			["log"] = log
		}
	end

	function logger:GetInfo()
		return {
			["name"] = self.name
		}
	end

	return logger
end
