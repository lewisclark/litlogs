if SERVER then
	include("litlogs/sv_litlogs.lua")
	AddCSLuaFile("litlogs/cl_litlogs.lua")
else
	include("litlogs/cl_litlogs.lua")
end