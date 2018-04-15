local function getIndiciesFromPage(page)
	local startIdx = (page - 1) * LitLogs.LOGS_PER_PAGE + 1
	--local endIdx = startIdx + LitLogs.LOGS_PER_PAGE - 1

	return startIdx
end

local function getLastPage(count)
	return math.ceil(count / LitLogs.LOGS_PER_PAGE)
end

-- Searching the logs
do
	local function getSearchResultCount(logger, needle, callback)
		local strQuery = string.format("SELECT COUNT(1) AS count FROM litlogs_archive WHERE log LIKE '%%%s%%';", needle)
		if logger ~= nil then
			strQuery = string.format("SELECT COUNT(1) AS count FROM litlogs_archive WHERE logger = '%s' AND log LIKE '%%%s%%';",
				logger:GetName(), needle)
		end

		LitLogs.Query(strQuery, function(data)
			local count = (istable(data) and data[1] and data[1].count) and data[1].count or 0

			callback(count)
		end)
	end

	function LitLogs.SearchAllLogs(pageRequested, needle, callback)
		getSearchResultCount(nil, needle, function(count)
			if count <= 0 then
				callback({}, 0)

				return
			end

			local page = pageRequested > 0 and pageRequested or getLastPage(count)
			local logStartIndex = getIndiciesFromPage(page)

			local strQuery = string.format("SELECT time, log FROM litlogs_archive WHERE log LIKE '%%%s%%' ORDER BY id LIMIT %s, %s;",
				LitLogs.EscapeSQL(needle), logStartIndex - 1, LitLogs.LOGS_PER_PAGE)

			LitLogs.Query(strQuery, function(data)
				callback(data, page)
			end)
		end)
	end

	function LitLogs.SearchLogger(logger, pageRequested, needle, callback)
		getSearchResultCount(logger, needle, function(count)
			if count <= 0 then
				callback({}, 0)

				return
			end

			local page = pageRequested > 0 and pageRequested or getLastPage(count)
			local logStartIndex = getIndiciesFromPage(page)

			local strQuery = string.format("SELECT time, log FROM litlogs_archive WHERE logger = '%s' AND log LIKE '%%%s%%' ORDER BY id LIMIT %s, %s;",
				logger:GetName(), LitLogs.EscapeSQL(needle), logStartIndex - 1, LitLogs.LOGS_PER_PAGE)

			LitLogs.Query(strQuery, function(data)
				callback(data, page)
			end)
		end)
	end
end

-- Normal log retrieval
do
	local function getTotalLogCount()
		local i = 0

		for _, logger in ipairs(LitLogs.GetLoggers()) do
			i = i + logger:GetLogCount()
		end

		return i
	end

	function LitLogs.GetAllLogs(pageRequested, callback)
		local count = getTotalLogCount()

		if count <= 0 then
			callback({}, 0)

			return
		end

		local page = pageRequested > 0 and pageRequested or getLastPage(count)
		local logStartIndex = getIndiciesFromPage(page)

		local strQuery = string.format("SELECT time, log FROM litlogs_archive ORDER BY id LIMIT %s, %s;",
			logStartIndex - 1, LitLogs.LOGS_PER_PAGE)

		LitLogs.Query(strQuery, function(data)
			callback(data, page)
		end)
	end

	function LitLogs.GetLogsFromLogger(logger, pageRequested, callback)
		logger:SendLogsToArchive(function() -- Send remaining logs to the archive before we pull from the archive
			if logger:GetLogCount() <= 0 then
				callback({}, 0)

				return
			end

			local page = pageRequested > 0 and pageRequested or logger:GetPageCount()
			local logStartIndex = getIndiciesFromPage(page)

			local strQuery = string.format("SELECT time, log FROM litlogs_archive WHERE logger = '%s' ORDER BY id LIMIT %s, %s;",
				logger:GetName(), logStartIndex - 1, LitLogs.LOGS_PER_PAGE)

			LitLogs.Query(strQuery, function(data)
				callback(data, page)
			end)
		end)
	end
end
