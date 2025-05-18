-- Turnip Time
-- Nicci M

local loaded = false
local dbg = false
local status = "inactive"
local lastTarget = nil
local msgLim = 0.75
local msgTime = os.time()
local update = nil
local upInterval = os.time()
local spLim = 6
local spCnt = 0
local report = true
local targetMethod = "pvp"
local moving = nil
local nomove = nil

notify = 0

local Jobs = {
	[0] = "UNK",
	[1] = "-1-",
	[2] = "-2-",
	[3] = "MRD",
	[4] = "LNC",
	[5] = "ARC",
	[6] = "CNJ",
	[7] = "THM",
	[8] = "CRP",
	[9] = "BSM",
	[10] = "ARM",
	[11] = "GSM",
	[12] = "LTW",
	[13] = "WVR",
	[14] = "ALC",
	[15] = "CUL",
	[16] = "MIN",
	[17] = "BOT",
	[18] = "FSH",
	[19] = "PGL",
	[20] = "MNK",	
	[21] = "WAR",
	[22] = "DRG",
	[23] = "BRD",
	[24] = "WHM",
	[25] = "BLM",
	[26] = "ACN",
	[27] = "SMN",
	[28] = "SCH",
	[29] = "ROG",
	[30] = "NIN",
	[31] = "MCH",
	[32] = "DRK",
	[33] = "AST",
	[34] = "SAM",
	[35] = "RDM",
	[36] = "BLU",
	[37] = "GNB",
	[38] = "DNC",
	[39] = "RPR",
	[40] = "SGE",
	[41] = "VPR",
	[42] = "PCT",	


}

local function shiftWord(text, wordTransformer)
	if type(text) ~= "string" then text = tostring(text) end
	local word, rest = text:match("([%w-]+)(.*)")
	word = (word or ""):match("^%s*(.-)%s*$")
	rest = (rest or ""):match("^%s*(.-)%s*$")
	if type(wordTransformer) == "function" then word = wordTransformer(word) end
	return word, rest
end

local function distTarget()
	trgt = Game.Player.Target
	if trgt.Name then
		disA = math.abs(trgt.PosX - Game.Player.PosX)
		disB = math.abs(trgt.PosY - Game.Player.PosY)
		disC = math.sqrt(disA^2 + disB^2)
		--Game.SendChat("/e TT: distance check :: " .. tostring(disC))
		return disC
	end
	return 999
end

local function playerReady()
	if Game.Player.InCutscene or Game.Player.Casting or not Game.Player.MapZone or ((Game.Player.Job.Id > 7 and Game.Player.Job.Id < 19) and targetMethod == "pvp") then
		return nil
	else
		return true
	end
end

local function Mark(name)
	local actStr = "/mk Attack" .. tostring(turnipName[name].id)
end

local function FaceTarget()
	local actStr = "/facetarget"
	Game.SendChat(actStr)
end

function MoveToTarget()
	local trgt = Game.Player.Target
	if trgt and not moving and distTarget() > 7	then
		moving = true
		Game.SendChat("/vnav movetarget")
	end
end

function StopMoving()
	Game.SendChat("/vnav stop")
	Script.QueueDelay(2.250)
	Script.QueueAction(Interact)
end

function Interact()
	Game.SendChat("/pinteract")
end

function message(msg)
	Game.PrintMessage(msg)
end

local function ValidateTarget(trgt)
	if distTarget() < 27 then
		return true
	end
	return nil
end

function MonitorTarget()
	local trgt = Game.Player.Target
	if not trgt.Name then
		notify = 0
		lastTarget = nil
		status = "Searching"
		update = true
		return
	end
	if (trgt and targetMethod == "npc" and not moving and not nomove) then
		MoveToTarget()
	end
	if ValidateTarget(trgt) then
		local trgtName = Game.Player.Target.Name
		local trgtJobId = Game.Player.Target.Job.Id
		--local trgtHp = Game.Player.Target.Hp
		--local trgtMaxHp = Game.Player.Target.MaxHp
		local trgtJob = Jobs[trgtJobId] or 0
		local trgtDist = distTarget()
		local trgtType = Game.Player.Target.Type
		trgtDist = math.floor(trgtDist * 10)/10
		status = "TargetActive"
		local tmp = os.time() - msgTime
		if moving and trgtDist < 3 then
			StopMoving()
		end
		if tmp > msgLim then
			--tmp = distTarget()
			if trgtDist < 25 and notify == 0 then
				if trgtName then
					--if trgtJob.Id then
						if trgtName ~= lastTarget then
							--tarDis = Game.Player.Target.Distance
							lastTarget = trgtName
							if report then
								if trgtJob == "UNK" then
									Game.SendChat("/echo Target: [" .. trgtType .. "] - " .. trgtName .. " (" .. tostring(trgtDist) .. ")")
								else
									Game.SendChat("/echo Target: [" .. trgtJob .. "] - " .. trgtName .. " (" .. tostring(trgtDist) .. ")")
								end
							end
							--Game.SendChat("/echo Target HP: " .. tmp .. "%! <se.3>")
							--Game.SendChat("/echo Target Name: " .. trgtName)
							--Game.SendChat("/echo Target Distance: " .. tarDis)
							msgTime = os.time()
							notify = 1
						else
							notify = 0
						end
					--end
				end
				return
			end
		end
	end
	notify = 0
	status = "Searching"
end

function AquireTarget()
	local trgt = Game.Player.Target
	if trgt.Name then
		if status == "Searching" then
			moving = nil
			if ValidateTarget(trgt) then
				status = "TargetActive"
				return
			end
		end
	end
	status = "Searching"
	if playerReady() then
		if targetMethod == "npc" then
			--Game.SendChat("/e TT: npc")
			Game.SendChat("/targetnpc")
		elseif targetMethod == "pc" then
			Game.SendChat("/targetpc")
		else
			Game.SendChat("/targetenemy")
		end
	end
end

function TargetHandler()
	if status == "Searching" then
		AquireTarget()
	elseif status == "TargetActive" then
		MonitorTarget()
	end
	if Script.QueueSize < 4 then
		Script.QueueDelay(250)
		Script.QueueAction(Update)
	else
		Script.QueueDelay(1500)
		Script.QueueAction(Update)
	end
end

function Update()
	TargetHandler()
end

local function doLoad()
	loaded = true
	update = true
	status = "inactive"
	Script.QueueDelay(2000)
	Script.QueueAction(message, "Turnip Time loaded!")
	Script.QueueAction(Update)
end

local function DumpInfo()
	local trgt = Game.Player.Target
	if trgt then
		if trgt.Name then
			Script.QueueAction(message, "Name: " .. trgt.Name)
			Script.QueueDelay(100)
			if trgt.Job then
				if trgt.Job.Id then
					Script.QueueAction(message, "Target Job.Id: " .. trgt.Job.Id)
					Script.QueueDelay(100)
				end
			end
		end
	end
	Script.QueueAction(Update)
end

Script.QueueAction(doLoad)

local function onInvoke(textline)
	local action, args = shiftWord(textline, string.lower)
	if not loaded and Game.Player.Loaded then
		doLoad()
	end
	if action == "save" then
		--
	elseif action == "toggle" then
		if status == "inactive" then
			status = "Searching"
			rtgCount = 0
			Script.QueueAction(message, "Searching for Turnips!")
			Script.QueueDelay(500)
		else
			status = "inactive"
			Script.QueueAction(message, "Turnip search is paused.")
			Script.QueueDelay(500)
		end
	elseif action == "off" or action == "kill" or action == "stop" then
		status = "inactive"
		Script.QueueAction(message, "Turnip search is paused.")
		Script.QueueDelay(500)
	elseif action == "pc" then
		status = "Searching"
		targetMethod = "pc"
		Script.QueueAction(message, "Turnip search set to PC targeting method.")
		Script.QueueDelay(500)
	elseif action == "nomove" then
		nomove = true
		StopMoving()
	elseif action == "nmove" or action == "no" or action == "nomove" then
		nomove = nil
	elseif action == "npc" then
		status = "Searching"
		targetMethod = "npc"
		Script.QueueAction(message, "Turnip search set to NPC targeting method.")
		Script.QueueDelay(500)
	elseif action == "pvp" or action == "hostile" then
		status = "Searching"
		targetMethod = "pvp"
		Script.QueueAction(message, "Turnip search set to PVP targeting method.")
		Script.QueueDelay(500)
	elseif action == "info" then
		DumpInfo()
	--elseif action == "special" then
		--status = "special"
	elseif action == "status" then
		message("Status Check: " .. status)
	elseif action == "silent" or action == "shh" or action == "quiet" then
		report = nil
	elseif action == "msg" or action == "show" or action == "report" then
		report = true
	else
		status = "Searching"
		rtgCount = 0
		Script.QueueAction(message, "Searching for Turnips!")
		Script.QueueDelay(500)
	end
end
Script(onInvoke)