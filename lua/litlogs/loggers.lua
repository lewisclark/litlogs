
--[[ -------------------------------------------- ]]--

local chatLogger = LitLogs.Logger("Chat")
LitLogs.AddLogger(chatLogger)

chatLogger:HookEvent("PlayerSay", function(ply, text, teamChat)
	local log = "%s said '%s'"
	log = log .. (teamChat and " in team chat" or "")

	chatLogger:Log(log, ply, text)
end)

--[[ -------------------------------------------- ]]--

local toolLogger = LitLogs.Logger("Toolgun")
LitLogs.AddLogger(toolLogger)

toolLogger:HookEvent("CanTool", function(ply, tr, tool)
	toolLogger:Log("%s used tool %s on %s", ply, tool, tr.Entity)
end)

--[[ -------------------------------------------- ]]--

local propSpawnLogger = LitLogs.Logger("Prop Spawning")
LitLogs.AddLogger(propSpawnLogger)

propSpawnLogger:HookEvent("PlayerSpawnedProp", function(ply, propModel)
	propSpawnLogger:Log("%s spawned prop '%s'", ply, propModel)
end)

--[[ -------------------------------------------- ]]--

local deathLogger = LitLogs.Logger("Kills/Deaths")
LitLogs.AddLogger(deathLogger)

deathLogger:HookEvent("PlayerDeath", function(victim, inflictor, attacker)
	local log = {}

	if attacker == victim then
		log = {"%s commited suicide", victim}
	elseif attacker:IsPlayer() then
		log = {"%s killed %s using %s", attacker, victim, IsValid(attacker:GetActiveWeapon()) and attacker:GetActiveWeapon() or "?"}
	else
		log = {"%s killed %s", attacker, victim}
	end

	deathLogger:Log(unpack(log))
end)

--[[ -------------------------------------------- ]]--

local playerDamageLogger = LitLogs.Logger("Damage (Player)")
LitLogs.AddLogger(playerDamageLogger)

playerDamageLogger:HookEvent("EntityTakeDamage", function(target, dmg)
	if not target:IsPlayer() then return end

	local attacker = dmg:GetAttacker()

	local log = {}

	if attacker:IsPlayer() then
		local attackerWep = IsValid(attacker:GetActiveWeapon()) and attacker:GetActiveWeapon() or "?"

		log = {"%s damaged %s with %s for %s health", attacker, target, attackerWep, dmg:GetDamage()}
	else
		log = {"%s damaged %s for %s", attacker, target, dmg:GetDamage()}
	end

	playerDamageLogger:Log(unpack(log))
end)

--[[ -------------------------------------------- ]]--

local connectionsLogger = LitLogs.Logger("Connections")
LitLogs.AddLogger(connectionsLogger)

connectionsLogger:HookEvent("PlayerInitialSpawn", function(ply)
	timer.Simple(5, function() -- Wait for player to initialize (:Nick() to be set to player's rpname)
		if not IsValid(ply) then return end

		connectionsLogger:Log("%s connected", ply)
	end)
end)

--[[ -------------------------------------------- ]]--

local disconnectionsLogger = LitLogs.Logger("Disconnections")
LitLogs.AddLogger(disconnectionsLogger)

disconnectionsLogger:HookEvent("PlayerDisconnected", function(ply)
	disconnectionsLogger:Log("%s disconnected", ply)
end)

--[[ -------------------------------------------- ]]--

local nameChangesLogger = LitLogs.Logger("Name Changes")
LitLogs.AddLogger(nameChangesLogger)

nameChangesLogger:HookEvent("onPlayerChangedName", function(ply, oldName, newName)
	nameChangesLogger:Log("%s changed their name to '%s'", ply, newName)
end)

--[[ -------------------------------------------- ]]--

local hitsLogger = LitLogs.Logger("Hits")
LitLogs.AddLogger(hitsLogger)

hitsLogger:HookEvent("onHitCompleted", function(hitman, target, customer)
	hitsLogger:Log("%s completed a hit on %s, requested by %s", hitman, target, customer)
end)

hitsLogger:HookEvent("onHitFailed", function(hitman, target, reason)
	hitsLogger:Log("%s failed a hit on %s (%s)", hitman, target, reason)
end)

hitsLogger:HookEvent("onHitAccepted", function(hitman, target, customer)
	hitsLogger:Log("%s accepted a hit on %s, requested by %s", hitman, target, customer)
end)

--[[ -------------------------------------------- ]]--

local jobChangeLogger = LitLogs.Logger("Job Changes")
LitLogs.AddLogger(jobChangeLogger)

jobChangeLogger:HookEvent("OnPlayerChangedTeam", function(ply, oldTeam, newTeam)
	local teams = RPExtraTeams
	local oldJobName, newJobName = teams[oldTeam].name, teams[newTeam].name

	jobChangeLogger:Log("%s changed to %s from %s", ply, newJobName, oldJobName)
end)

--[[ -------------------------------------------- ]]--

local economyLogger = LitLogs.Logger("Economy")
LitLogs.AddLogger(economyLogger)

economyLogger:HookEvent("playerPickedUpMoney", function(ply, amount)
	economyLogger:Log("%s picked up %s", ply, DarkRP.formatMoney(amount))
end)

economyLogger:HookEvent("playerDroppedMoney", function(ply, amount)
	economyLogger:Log("%s dropped %s", ply, DarkRP.formatMoney(amount))
end)

economyLogger:HookEvent("playerGaveMoney", function(giver, receiver, amount)
	economyLogger:Log("%s gave %s to %s", giver, DarkRP.formatMoney(amount), receiver)
end)

economyLogger:HookEvent("playerPickedUpCheque", function(receiver, intended, amount, allowed)
	if not allowed then return end

	economyLogger:Log("%s picked up a cheque for %s", receiver, DarkRP.formatMoney(amount))
end)

economyLogger:HookEvent("playerDroppedCheque", function(dropper, receiver, amount)
	economyLogger:Log("%s dropped a cheque for %s, intended for %s", dropper, DarkRP.formatMoney(amount), receiver)
end)

--[[ -------------------------------------------- ]]--

local doorLogger = LitLogs.Logger("Doors")
LitLogs.AddLogger(doorLogger)

doorLogger:HookEvent("playerBoughtDoor", function(ply, door, cost)
	doorLogger:Log("%s bought a door for %s", ply, DarkRP.formatMoney(cost))
end)

doorLogger:HookEvent("playerKeysSold", function(ply, ent, amtSoldFor)
	if not ent:isDoor() then return end

	doorLogger:Log("%s sold a door for %s", ply, DarkRP.formatMoney(amtSoldFor))
end)

--[[ -------------------------------------------- ]]--

local wantedLogger = LitLogs.Logger("Wanted")
LitLogs.AddLogger(wantedLogger)

wantedLogger:HookEvent("playerWanted", function(criminal, actor, reason)
	wantedLogger:Log("%s made %s wanted for reason: '%s'", actor, criminal, reason)
end)

--[[ -------------------------------------------- ]]--

local warrantLogger = LitLogs.Logger("Warrant")
LitLogs.AddLogger(warrantLogger)

warrantLogger:HookEvent("playerWarranted", function(criminal, actor, reason)
	warrantLogger:Log("%s warranted %s for reason: '%s'", actor, criminal, reason)
end)

--[[ -------------------------------------------- ]]--

local arrestLogger = LitLogs.Logger("Arrest/Unarrest")
LitLogs.AddLogger(arrestLogger)

arrestLogger:HookEvent("playerArrested", function(criminal, time, actor)
	arrestLogger:Log("%s arrested %s", actor, criminal)
end)

arrestLogger:HookEvent("playerUnArrested", function(criminal, actor)
	local wasConsole = not IsValid(actor)

	if wasConsole then
		arrestLogger:Log("%s was unarrested automatically", criminal)
	else
		arrestLogger:Log("%s unarrested %s", actor, criminal)
	end
end)

--[[ -------------------------------------------- ]]--

local purchaseLogger = LitLogs.Logger("Purchases")
LitLogs.AddLogger(purchaseLogger)

purchaseLogger:HookEvent("playerBoughtCustomEntity", function(ply, entTab)
	purchaseLogger:Log("%s purchased '%s' for %s", ply, entTab.name, DarkRP.formatMoney(entTab.price))
end)

--[[ -------------------------------------------- ]]--

local kickBansLogger = LitLogs.Logger("Kicks/Bans")
LitLogs.AddLogger(kickBansLogger)

kickBansLogger:HookEvent("ULibPostTranslatedCommand", function(ply, commandName, args)
	-- args[1] is always the caller (ply)
	cmd = commandName:lower():Split(" ")[2]:Trim()
	local target = args[2] == ply and "Themself" or args[2]

	if cmd == "kick" then
		kickBansLogger:Log("%s kicked %s with reason: '%s'", ply, target, args[3])
	elseif cmd == "ban" or cmd == "banid" then
		kickBansLogger:Log("%s banned %s for %s with reason: '%s'", ply, target, args[3], args[4])
	end
end)

--[[ -------------------------------------------- ]]--

local awarnLogger = LitLogs.Logger("Warns")
LitLogs.AddLogger(awarnLogger)

awarnLogger:HookEvent("AWarnPlayerWarned", function(target, ply, reason)
	awarnLogger:Log("%s warned %s with reason: '%s'", ply, target, reason)
end)

awarnLogger:HookEvent("AWarnPlayerIDWarned", function(target, ply, reason)
	awarnLogger:Log("%s warned ID %s with reason: '%s'", ply, target, reason)
end)

--[[ -------------------------------------------- ]]--

local ulxLogger = LitLogs.Logger("ULX")
LitLogs.AddLogger(ulxLogger)

ulxLogger:HookEvent("ULibPostTranslatedCommand", function(ply, commandName, args)
	cmd = commandName:lower():Split(" ")[2]

	local newArgs = {} -- args[1] is always the player that called the command, so we're safe to strip that
	for i = 2, #args do
		newArgs[i] = args[i]
	end

	ulxLogger:Log("%s used command %s with arguments: %s", ply, cmd, newArgs)
end)

--[[ -------------------------------------------- ]]--

local bankLogger = LitLogs.Logger("Bank")
LitLogs.AddLogger(bankLogger)

bankLogger:HookEvent("BankClerk_DepositMoney", function(ply, amount)
	bankLogger:Log("%s deposited %s", ply, DarkRP.formatMoney(amount))
end)

bankLogger:HookEvent("BankClerk_WithdrawMoney", function(ply, amount)
	bankLogger:Log("%s withdrew %s", ply, DarkRP.formatMoney(amount))
end)

bankLogger:HookEvent("BankClerk_TransferMoney", function(ply, ply2, amount)
	bankLogger:Log("%s transferred %s to %s", ply, ply2, DarkRP.formatMoney(amount))
end)

--[[ -------------------------------------------- ]]--

local cfLogger = LitLogs.Logger("Coin Flips")
LitLogs.AddLogger(cfLogger)

cfLogger:HookEvent("CFCreate", function(ply, amount)
	cfLogger:Log("%s created a coinflip for %s", ply, DarkRP.formatMoney(amount))
end)

cfLogger:HookEvent("CFRemove", function(ply, amount)
	cfLogger:Log("%s removed their coin fip for %s", ply, DarkRP.formatMoney(amount))
end)

cfLogger:HookEvent("CFWin", function(ply, ply2, amount)
	cfLogger:Log("%s won a coin flip against %s for %s", ply, ply2, DarkRP.formatMoney(amount))
end)
