surface.CreateFont("LitLogs::LoggerButtonFont", {
	font = "Verdana",
	extended = false,
	size = 14,
	weight = 500
})

surface.CreateFont("LitLogs::LogFont", {
	font = "News Gothic",
	extended = false,
	size = 13,
	weight = 500
})

surface.CreateFont("LitLogs::TitleFont", {
	font = "Verdana",
	extended = false,
	size = 18,
	weight = 500
})

surface.CreateFont("LitLogs::CloseButtonFont", {
	font = "Verdana",
	extended = false,
	size = 24,
	weight = 500
})

local frame, logView, pgTextEntry
local currentLogger, currentPage -- The logger that is currently open and current page for that logger
local lastSearchNeedle

local function formatTimestamp(timestamp, forceDate, appendTimezone)
	local isCurrentDay = os.date("%d/%m/%y", os.time()) == os.date("%d/%m/%y", timestamp)
	local fmt = (not forceDate and isCurrentDay) and "%H:%M:%S" or "%d/%m/%y  %H:%M:%S"

	fmt = fmt .. (appendTimezone and " (%z)" or "")

	return os.date(fmt, timestamp)
end

local function requestLogs(logger, page)
	logView:Clear()
	logView:AddLine(formatTimestamp(os.time()), "Loading...")

	RunConsoleCommand("litlogs", logger, tonumber(page))

	lastSearchNeedle = nil
end

local function requestSearch(logger, page, needle)
	logView:Clear()
	logView:AddLine(formatTimestamp(os.time()), "Loading...")

	RunConsoleCommand("litlogs", logger, tonumber(page), needle)

	lastSearchNeedle = needle
end

local function openMenu()
	frame:SetVisible(true)
end

local function closeMenu()
	frame:SetVisible(false)
end

local function showLogs(logData)
	local loggerName = logData.loggerName
	local logs = logData.logs
	local page = logData.page

	currentLogger = loggerName
	currentPage = page

	logView:Clear()
	pgTextEntry:SetValue(currentPage)

	if #logs <= 0 then
		logView:AddLine(formatTimestamp(os.time()), "Nothing to see here!")
	else
		for _, log in ipairs(logs) do
			local line = logView:AddLine(formatTimestamp(log.time), log.log)
			line.logTimestamp = log.time
		end
	end
end

local function createMenu(loggers)
	table.sort(loggers, function(a, b) return a < b end)

	local loggersPanel
	local logViewPanel

	frame = vgui.Create("DFrame")
	frame:SetSize(ScrW() / 1.2, 450)
	frame:Center()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame:MakePopup()
	frame.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(230, 230, 230, 255))

		draw.SimpleText("Lit Logs", "LitLogs::TitleFont", w / 2, 15, Color(42, 42, 42, 255), 1, 1)
		draw.SimpleText("https://github.com/lewez/litlogs", "LitLogs::TitleFont", w / 2, self:GetTall() - 16, Color(42, 42, 42, 255), 1, 1)

		surface.SetDrawColor(42, 42, 42, 255)
		surface.DrawRect(0, 0, w, 2)
		surface.DrawRect(0, h - 2, w, 2)

		-- loggersPanel
		do
			local x, y, w, h = loggersPanel:GetBounds()

			surface.DrawRect(x, y, x + w, 2)
			surface.DrawRect(0, y + h, x + w, 2)
			surface.DrawRect(x + w, y, x + 2, h + 2)
		end

		-- logViewPanel
		do
			local x, y, w, h = logViewPanel:GetBounds()

			surface.DrawRect(x, y, w, 2)
			surface.DrawRect(x, y + h, w, 2)
			surface.DrawRect(x, y, 2, h)
		end
	end

	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetSize(20, 16)
	closeBtn:SetPos(frame:GetWide() - 24, 7)
	closeBtn:SetFont("LitLogs::CloseButtonFont")
	closeBtn:SetText("X")
	closeBtn:SetTextColor(Color(222, 100, 100, 255))
	closeBtn.DoClick = function()
		closeMenu()
	end
	closeBtn.Paint = function(self)
		if self:IsHovered() then
			self:SetTextColor(Color(222, 100, 100, 255))
		else
			self:SetTextColor(Color(222, 140, 140, 255))
		end
	end

	--[[ Panel to all buttons of different loggers ]]--
	loggersPanel = vgui.Create("DScrollPanel", frame)
	loggersPanel:SetPos(0, 30)
	loggersPanel:SetSize(140, frame:GetTall() - 60)
	loggersPanel.VBar:SetSize(0, 0)
	loggersPanel.Paint = function(self, w, h) end

	--[[ Parent of logView list and logViewControls ]]--
	logViewPanel = vgui.Create("DPanel", frame)
	logViewPanel:SetPos(loggersPanel:GetWide() + 10, 30)
	logViewPanel:SetSize(frame:GetWide() - loggersPanel:GetWide() - 10, frame:GetTall() - 60)
	logViewPanel.Paint = function(self, w, h)
		-- Seperator between logView and logViewControl
		local height = logView:GetTall()

		surface.SetDrawColor(42, 42, 42, 255)
		surface.DrawRect(0, height + 2, w, 2)
	end

	--[[ Where the logs are displayed ]]--
	logView = vgui.Create("DListView", logViewPanel)
	logView:SetPos(2, 2)
	logView:SetSize(logViewPanel:GetWide() - 4, logViewPanel:GetTall() - 50)
	logView:AddColumn("When"):SetFixedWidth(100)
	logView:AddColumn("Log")
	logView:SetSortable(false)
	logView:SetMultiSelect(false)
	logView.VBar:Remove()
	logView.VBar = nil
	logView:SetHideHeaders(true)
	logView.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(222, 222, 222, 255))
	end
	logView.DoDoubleClick = function(self, lineId, line)
		SetClipboardText(string.format("[%s] %s", formatTimestamp(line.logTimestamp, true, true), line:GetColumnText(2)))
		chat.AddText("Log copied to clipboard.")
	end

	-- Re-paint the lines
	do
		local function logViewLinePaint(self, w, h)
			if self:IsHovered() then
				draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
			end
		end

		for _, line in ipairs(logView:GetLines()) do
			line.Paint = logViewLinePaint

			for _, v in ipairs(line.Columns) do
				v:SetFont("LitLogs::LogFont")
				v:SetTextColor(Color(42, 42, 42, 255))
			end
		end
	end

	--[[ Logger controls ]]--

	local logViewControl = vgui.Create("DPanel", logViewPanel)
	logViewControl:SetPos(2, logView:GetTall() + 4)
	logViewControl:SetSize(logViewPanel:GetWide(), logViewPanel:GetTall() - logView:GetTall() - 4)
	logViewControl.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(222, 222, 222, 255))
	end

	-- Specific controls
	do
		-- Pages

		local pgNextBtn = vgui.Create("DButton", logViewControl)
		pgNextBtn:SetSize(logViewControl:GetWide() / 6, 22)
		pgNextBtn:SetPos(logViewControl:GetWide() - pgNextBtn:GetWide() - 10, 0)
		pgNextBtn:CenterVertical()
		pgNextBtn:SetText("Next Page")
		pgNextBtn:SetTextColor(Color(42, 42, 42, 255))
		pgNextBtn:SetFont("LitLogs::LoggerButtonFont")
		pgNextBtn.Paint = function(self, w, h)
			if self:IsHovered() then
				draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 42, 255))
				draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(200, 200, 200, 255))
			else
				draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
			end
		end
		pgNextBtn.DoClick = function()
			if currentPage == nil or currentLogger == nil then return end

			if not lastSearchNeedle then
				requestLogs(currentLogger, currentPage + 1)
			else
				requestSearch(currentLogger, currentPage + 1, lastSearchNeedle)
			end
		end

		pgTextEntry = vgui.Create("DTextEntry", logViewControl)
		pgTextEntry:SetSize(44, 22)
		pgTextEntry:SetPos(select(1, pgNextBtn:GetPos()) - pgTextEntry:GetWide() - 10, 0)
		pgTextEntry:CenterVertical()
		pgTextEntry.Paint = function(self, w, h)
			if self:IsEditing() then
				draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 42, 255))
				draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(200, 200, 200, 255))
			else
				draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
			end

			draw.SimpleText(self:GetValue(), "LitLogs::LoggerButtonFont", 2, h / 2, Color(42, 42, 42, 255), 0, 1)
		end
		pgTextEntry.OnEnter = function(self)
			if currentPage == nil or currentLogger == nil then return end

			local page = tonumber(self:GetValue())
			if not page then return end

			if not lastSearchNeedle then
				requestLogs(currentLogger, page)
			else
				requestSearch(currentLogger, page, lastSearchNeedle)
			end
		end

		local pgPrevBtn = vgui.Create("DButton", logViewControl)
		pgPrevBtn:SetSize(logViewControl:GetWide() / 6, 22)
		pgPrevBtn:SetPos(select(1, pgTextEntry:GetPos()) - pgPrevBtn:GetWide() - 10, 0)
		pgPrevBtn:CenterVertical()
		pgPrevBtn:SetText("Previous Page")
		pgPrevBtn:SetTextColor(Color(42, 42, 42, 255))
		pgPrevBtn:SetFont("LitLogs::LoggerButtonFont")
		pgPrevBtn.Paint = function(self, w, h)
			if self:IsHovered() then
				draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 42, 255))
				draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(200, 200, 200, 255))
			else
				draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
			end
		end
		pgPrevBtn.DoClick = function()
			if currentPage == nil or currentLogger == nil then return end

			if not lastSearchNeedle then
				requestLogs(currentLogger, currentPage - 1)
			else
				requestSearch(currentLogger, currentPage - 1, lastSearchNeedle)
			end
		end

		--[[ Searching ]]--

		local searchEntry = vgui.Create("DTextEntry", logViewControl)
		searchEntry:SetSize(logViewControl:GetWide() / 3, 22)
		searchEntry:SetPos(10, 0)
		searchEntry:CenterVertical()
		searchEntry:SetValue("")
		searchEntry.Paint = function(self, w, h)
			if self:IsEditing() then
				draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 42, 255))
				draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(200, 200, 200, 255))
			else
				draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
			end

			local val = self:GetValue() or ""

			if #val <= 0 then
				draw.SimpleText("Search...", "LitLogs::LoggerButtonFont", 2, h / 2, Color(42, 42, 42, 255), 0, 1)
			else
				draw.SimpleText(self:GetValue(), "LitLogs::LoggerButtonFont", 2, h / 2, Color(42, 42, 42, 255), 0, 1)
			end
		end
		searchEntry.OnEnter = function(self)
			if currentPage == nil or currentLogger == nil then return end

			local needle = tostring(self:GetValue()) or ""
			if #needle == 0 then return end

			requestSearch(currentLogger, 0, needle) -- 0 to get last page (most recent)
		end
	end

	--[[ Create logger buttons ]]--
	do
		local yPos = 34

		local activeButton

		local function createLoggerButton(name)
			local buttonHeight = 22

			local button = vgui.Create("DButton", loggersPanel)
			button:SetSize(loggersPanel:GetWide(), buttonHeight)
			button:SetPos(0, yPos)
			button:SetText(name)
			button:SetTextColor(Color(42, 42, 42, 255))
			button:SetFont("LitLogs::LoggerButtonFont")
			button.Paint = function(self, w, h)
				if activeButton == self then
					draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
				end
			end
			button.DoClick = function(self)
				activeButton = self

				requestLogs(name, 0)
			end

			yPos = yPos + buttonHeight
		end

		local allLogsBtn = vgui.Create("DButton", loggersPanel)
		allLogsBtn:SetSize(loggersPanel:GetWide(), 22)
		allLogsBtn:SetPos(0, 2)
		allLogsBtn:SetText("All Logs")
		allLogsBtn:SetTextColor(Color(42, 42, 42, 255))
		allLogsBtn:SetFont("LitLogs::LoggerButtonFont")
		allLogsBtn.Paint = function(self, w, h)
			if activeButton == self then
				draw.RoundedBox(0, 0, 0, w, h, Color(200, 200, 200, 255))
			end
		end
		allLogsBtn.DoClick = function(self)
			activeButton = self
			requestLogs("All Logs", 0)
		end

		for _, name in ipairs(loggers) do
			createLoggerButton(name)
		end
	end
end

net.Receive("LitLogs", function()
	local len = net.ReadUInt(32)
	local data = util.JSONToTable(util.Decompress(net.ReadData(len)) or "{}")

	if data.loggers then
		createMenu(data.loggers)
		closeMenu()

		return -- don't reopen menu
	end

	if data.logData then
		showLogs(data.logData)
	end

	openMenu() -- re-open menu even if there aren't any logs to show
end)
