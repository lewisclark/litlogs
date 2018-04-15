LitLogs = {}
LitLogs.LOGS_PER_PAGE = 20

include("litlogs/sv_litlogs-sql.lua")
include("litlogs/sv_data-retrieval.lua")
include("litlogs/sv_player-store.lua")
include("litlogs/sv_logger.lua")

timer.Simple(0, function() -- Load loggers last
	include("litlogs/loggers.lua")

	local loggers = file.Find("litlogs/loggers--[[.lua", "LUA")

	for _, fileName in ipairs(loggers) do
		include("litlogs/loggers/" .. fileName)
	end
end)

util.AddNetworkString("LitLogs")

do
	local loggers = {}

	function LitLogs.GetLoggers()
		return loggers
	end

	function LitLogs.AddLogger(logger)
		loggers[#loggers + 1] = logger
	end
end

function LitLogs.GetLoggersInfo() -- Returns a table of all loggers infos
	local t = {}

	for _, v in ipairs(LitLogs.GetLoggers()) do
		t[#t + 1] = v:GetName()
	end

	return t
end

function LitLogs.GetLogger(loggerName)
	for _, logger in ipairs(LitLogs.GetLoggers()) do
		if logger:GetName() == loggerName then
			return logger
		end
	end

	return false
end

function LitLogs.HasAccess(ply)
	return ply:IsAdmin()
end

local seperator = ", "
function LitLogs.Format(val)
	if istable(val) then
		local s = "["

		for k, v in pairs(val) do
			s = s .. LitLogs.Format(v) .. seperator
		end

		s = s:sub(1, #s - #seperator) -- trim ending seperator
		s = s .. "]"

		return s
	elseif isentity(val) then
		if val:IsWorld() then
			return "World"
		end

		if IsValid(val) then
			if val:IsPlayer() then
				return string.format("%s (%s - %s)", val:Nick(), val:SteamID(), RPExtraTeams[val:Team()] and RPExtraTeams[val:Team()].name or "Unassigned")
			elseif val:IsWeapon() then
				return string.format("%s (%s)", val:GetPrintName(), val:GetClass())
			elseif val:IsVehicle() then
				return string.format("Vehicle (%s)", val:GetModel())
			else
				return string.format("%s", val:GetClass())
			end
		else
			return "<invalid entity>"
		end
	end

	return tostring(val) -- No formatting to do
end


------------------------------------------------------/

-- Send loggers, settings, etc
local hasSentInitialData, sendInitialData
do
	local sent = {}
	function hasSentInitialData(ply)
		return sent[ply] ~= nil
	end

	function sendInitialData(ply)
		if not IsValid(ply) or not LitLogs.HasAccess(ply) or hasSentInitialData(ply) then return end
		sent[ply] = true

		for k in pairs(sent) do
			if not IsValid(k) then
				sent[k] = nil
			end
		end

		local toSend = { ["loggers"] = LitLogs.GetLoggersInfo() }
		local data = util.Compress(util.TableToJSON(toSend))
		local len = #data

		net.Start("LitLogs")
			net.WriteUInt(len, 32)
			net.WriteData(data, len)
		net.Send(ply)
	end
end

function LitLogs.Open(ply, loggerName, pageRequested, searchNeedle)
	local function callback(logs, page)
		if not logs or not page then 	-- Open empty menu for client
			net.Start("LitLogs")
			net.Send(ply)

			return
		end

		local logData = {
			["logData"] = {
				["loggerName"] = loggerName,
				["logs"] = logs,
				["page"] = page
			}
		}

		local logsJson = util.Compress(util.TableToJSON(logData))
		local len = #logsJson

		net.Start("LitLogs")
			net.WriteUInt(len, 32)
			net.WriteData(logsJson, len)
		net.Send(ply)
	end

	local logger = LitLogs.GetLogger(loggerName)

	if not loggerName then
		callback()

		return
	end

	if logger then
		if searchNeedle then
			logger:Search(pageRequested, searchNeedle, callback)
		else
			logger:GetLogsForPage(pageRequested, callback)
		end
	elseif loggerName == "All Logs" then
		if searchNeedle then
			LitLogs.SearchAllLogs(pageRequested, searchNeedle, callback)
		else
			LitLogs.GetAllLogs(pageRequested, callback)
		end
	end
end

concommand.Add("litlogs", function(ply, cmd, args)
	if not LitLogs.HasAccess(ply) then
		ply:ChatPrint("You don't have access to view logs.")

		return
	end

	if not hasSentInitialData(ply) then
		sendInitialData(ply)

		timer.Simple(1, function()
			ply:ConCommand("litlogs", unpack(args))
		end)
	else
		local loggerName = args[1]
		local page = tonumber(args[2]) or 0
		local needle = args[3]

		LitLogs.Open(ply, loggerName, page, needle)
	end
end)

hook.Add("PlayerSay", "LitLogs::ChatCommand", function(ply, text)
	text = text:lower():Trim()

	if text == "!logs" or text == "!litlogs" then
		ply:ConCommand("litlogs")
	end
end)

local function archiveAllLogs()
	for _, logger in ipairs(LitLogs.GetLoggers()) do
		logger:SendLogsToArchive()
	end
end
timer.Create("LitLogs::ArchiveAllLogs", 5, 0, archiveAllLogs)
