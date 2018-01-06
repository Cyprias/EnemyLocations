--[[******************************************************************************
	Addon:      Enemy Locations
	Author:     Cyprias
	License:    MIT License	(http://opensource.org/licenses/MIT)
**********************************************************************************]]


local folder, core = ...
_G._EL = core

core.title		= GetAddOnMetadata(folder, "Title")
core.version	= GetAddOnMetadata(folder, "Version")
core.titleFull	= core.title.." v"..core.version
core.addonDir   = "Interface\\AddOns\\"..folder.."\\"

LibStub("AceAddon-3.0"):NewAddon(core, folder, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0", "AceHook-3.0")

core.defaultSettings = {}

do
	local OnInitialize = core.OnInitialize
	function core:OnInitialize()
		if OnInitialize then OnInitialize(self) end
		self.db = LibStub("AceDB-3.0"):New("EnemyLocations_DB", self.defaultSettings, true) --'Default'

		self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
		self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
		self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
		self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileChanged")
		
		self:RegisterChatCommand("el", "ChatCommand");

		
		self:RegisterEvent("ZONE_CHANGED")
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		--self:RegisterEvent("ZONE_CHANGED_INDOORS")
	end
end

function core:ZONE_CHANGED(event)
	core:Debug(event);
	core:ResetEnemyLocations()
end

function core:ZONE_CHANGED_NEW_AREA(event)
	core:Debug(event);
	core:ResetEnemyLocations()
end

function core:ZONE_CHANGED_INDOORS(event)
	core:Debug(event);
	core:ResetEnemyLocations()
end

function core:ChatCommand(input)

	if not input or input:trim() == "" then
		self:OpenOptionsFrame()
	end
end

do
	function core:OpenOptionsFrame()
		LibStub("AceConfigDialog-3.0"):Open(core.title)
	end
end

function core:OnProfileChanged(...)	
	self:Disable() -- Shut down anything left from previous settings
	self:Enable() -- Enable again with the new settings
end

do 
	local OnEnable = core.OnEnable
	function core:OnEnable()
		if OnEnable then OnEnable(self) end

		self:HookScript(WorldMapFrame, "OnShow", "WorldMapFrameOnShow")
		self:HookScript(WorldMapFrame, "OnHide", "WorldMapFrameOnHide")
		
		
		
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

do
	local OnDisable = core.OnDisable
	function core:OnDisable(...)
		if OnDisable then OnDisable(self, ...) end
	end
end

function core:dump_table(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. core:dump_table(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local strWhiteBar		= "|cffffff00 || |r" -- a white bar to seperate the debug info.
local echo
do
	local colouredName		= "|cff008000EL:|r "

	local tostring = tostring
	local select = select
	local _G = _G

	local msg
	local part
	
	local cf
	function echo(...)
		msg = tostring(select(1, ...))
		for i = 2, select("#", ...) do
			part = select(i, ...)
			msg = msg..strWhiteBar..tostring(part)
		end
		
		cf = _G["ChatFrame1"]
		if cf then
			cf:AddMessage(colouredName..msg,.7,.7,.7)
		end
	end
	core.echo = echo

	local strDebugFrom		= "|cffffff00[%s]|r" --Yellow function name. help pinpoint where the debug msg is from.
	
	local select = select
	local tostring = tostring
	
	local msg
	local part
	local function Debug(from, ...)
		if core.db.profile.debugMessages ~= true then
			return
		end
		
		msg = "nil"
		if select(1, ...) then
			msg = tostring(select(1, ...))
			for i = 2, select("#", ...) do
				part = select(i, ...)
				msg = msg..strWhiteBar..tostring(part)
			end
		end
		--from
		echo(strDebugFrom:format("D").." "..msg)
	end
	core.Debug = Debug
end

do
	local math_floor = math.floor

	function core.Round(num, zeros)
		local zeros = zeros or 0
		return math_floor( num * 10 ^ zeros + 0.5 ) / 10 ^ zeros
	end
	

	function core.RoundToNearest(n, b)
		return b * core.Round(n/b);
	end
end

do
	local timer;
	
	local createdFrames = false;
	function core:WorldMapFrameOnShow(frame) 
		--core.Debug("WorldMapFrameOnShow", "<WorldMapFrameOnShow>");
		--core:PopulateMap();
		
		
		 timer = core:ScheduleRepeatingTimer("UpdateMapCounts", 1);
		 core:PopulateMap();
	end
	
	function core:WorldMapFrameOnHide(frame) 
		core:HideAllCounts({parent=WorldMapDetailFrame});
		core:CancelTimer(timer)
	end
	
	function core:UpdateMapCounts() 
		core:Debug("UpdateMapCounts");
		
		core:HideAllCounts({parent=WorldMapDetailFrame});
		core:PopulateMap();
	end
end

do
	function core:PopulateMap()
		--core.Debug("PopulateMap", "<PopulateMap>");
		local enemies = core:GetEnemyLocations();
		
		--core.Debug("PopulateMap", core:dump_table(enemies));
		
		local locations = {};
		
		local elapsed;
		local locStr;
		for name, data in pairs( enemies ) do 
			elapsed = GetTime() - data.time;
			--core.Debug("PopulateMap", "PopulateMap name: " .. tostring(name) .. ", elapsed: " .. tostring(elapsed));
			
			if (elapsed < 30) then
			
				locStr = data.x .. ":" .. data.y;
				
				locations[ locStr ] = locations[ locStr ] or {x=data.x, y=data.y, count=0};
				locations[ locStr ].count = locations[ locStr ].count + 1;
			end
		end
		
		local frame;
		for locStr, data in pairs( locations ) do 
			core:Debug("locStr: " .. tostring(locStr) .. ", x: " .. tostring(data.x) .. ", y: " .. tostring(data.y) .. ", count: " .. tostring(data.count));

			frame = core:GetLocationFrame({
				x = data.x,
				y = data.y,
				parent = WorldMapDetailFrame
			});
			
			frame.text:SetText(data.count)
			frame:Show();
		end
		
	end
end

do
	local fontLocation	= "Fonts\\FRIZQT__.TTF"
	local fontSize = 14;
	
	local GetTime = GetTime;
	
	function core:CreateCountFrame(params) 
		local x         = params.x;
		local y         = params.y;
		local text      = params.text;
		local parent    = params.parent;
		
		local f = CreateFrame("Frame", nil, parent);
		
		local scale = parent:GetScale();
		
		x = x * parent:GetWidth();
		y = -y * parent:GetHeight();
		f:SetPoint("CENTER", parent, "TOPLEFT", x, y);

		f:SetWidth( fontSize )
		f:SetHeight( fontSize )
		
		f.text = f:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
		f.text:SetPoint("CENTER")
		f.text:SetFont(fontLocation, fontSize, "OUTLINE")
		--f.text:SetText("?")

		f:SetFrameStrata("FULLSCREEN");
		
		parent:HookScript("OnHide", function( self ) 
			f:Hide();
		end)
		
		f:SetScript("OnUpdate", function( self, elapsed ) 
			local a = GetTime() % 1
			if a > 0.5 then 
				a = 1 - a
			end

			self:SetAlpha( a * 3 )
		end)
		
		return f;
	end
end

do
	local frames = {};
	function core:GetLocationFrame(params)
		local x         = params.x;
		local y         = params.y;
		local parent    = params.parent;
		
		frames[parent] = frames[parent] or {};
		frames[parent][x] = frames[parent][x] or {};
		if (not frames[parent][x][y]) then
		
			frames[parent][x][y] = core:CreateCountFrame({
				x       = x,
				y       = y,
				parent  = parent,
			});
			--core.Debug("GetLocationFrame", "Created frame.");


		end
		
		return frames[parent][x][y];
	end
	
	function core:HideAllCounts( params )
		local parent = params.parent;
		
		local fs = frames[ parent ];
		if (fs) then
			for x, ys in pairs( fs ) do 
			
				for y, f in pairs( ys ) do 
					f:Hide();
				end
			end
		end
		
	end
end

	
do
	local enemies = {};
	function core:SaveEnemyLocation(params)
		local name  = params.name;
		local x     = params.x;
		local y     = params.y;
		
		x = core.RoundToNearest(x, 0.02);
		y = core.RoundToNearest(y, 0.02);
		enemies[ name ] = {
			x       = x, 
			y       = y,
			time    = GetTime()
		};
		
		--core.Debug("<SaveEnemyLocation>", "SaveEnemyLocation name: " .. tostring(name) .. ", x: " .. tostring(x) .. ", y: " .. tostring(y));
	end
	
	function core:GetEnemyLocation(params)
		local name = params.name;
		return enemies[ name ];
	end
	
	function core:GetEnemyLocations()
		return enemies;
	end
	
	function core:ResetEnemyLocations()
		enemies = {};
	end
	
	function core:RemoveEnemyLocation(params)
		enemies[ params.name ] = nil;
	end
end

do
	
	local function FlagIsPlayer(flags)
		return bit.band(flags, COMBATLOG_OBJECT_TYPE_PLAYER) == COMBATLOG_OBJECT_TYPE_PLAYER
	end
	
	local function FlagIsEnemy(flags)
		return bit.band(flags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE
	end
	
	local function FlagIsPet(flags)
		return bit.band(flags, COMBATLOG_OBJECT_CONTROL_PLAYER) == COMBATLOG_OBJECT_CONTROL_PLAYER and 
		(bit.band(flags, COMBATLOG_OBJECT_TYPE_PET) == COMBATLOG_OBJECT_TYPE_PET or 
		bit.band(flags, COMBATLOG_OBJECT_TYPE_GUARDIAN) == COMBATLOG_OBJECT_TYPE_GUARDIAN)
	end
	
	function FlagIsGroup(flags)
		return bit.band(flags, COMBATLOG_OBJECT_AFFILIATION_PARTY) == COMBATLOG_OBJECT_AFFILIATION_PARTY or
			bit.band(flags, COMBATLOG_OBJECT_AFFILIATION_RAID) == COMBATLOG_OBJECT_AFFILIATION_RAID or 
			bit.band(flags, COMBATLOG_OBJECT_AFFILIATION_MINE) == COMBATLOG_OBJECT_AFFILIATION_MINE
	end
	
	local function FlagIsFriendly(flags)
		return bit.band(flags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == COMBATLOG_OBJECT_REACTION_FRIENDLY
	end
	
	function core:PlayersInteracting( params )--	/script _EL:PlayersInteracting({friend=UnitName("player"), enemy="Bob"});
		
		local friend = params.friend;
		local enemy = params.enemy;
		
		if (UnitIsDeadOrGhost( friend )) then
			return;
		end
		
		local x, y = GetPlayerMapPosition(friend);
		--core.Debug("PlayersInteracting", "friend: " .. tostring(friend) .. ", enemy: " .. tostring(enemy) .. ", x: " .. tostring(x));
		
		if (enemy and x) then
			core:SaveEnemyLocation({
				name	= enemy,
				x       = x,
				y       = y,
			});
		end
	end
	
	function core:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
		local timestamp, eventType, hideCaster, srcGUID, srcName, srcFlags, sourceRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags = select(1, ...);
		local _, _, eventPrefix, eventSuffix = eventType:find("(.-)_(.+)")
		
		if FlagIsPlayer(srcFlags) and FlagIsPlayer(dstFlags) then --Both are players.
			if srcName ~= dstName then--person's not healing them self, ect.

				if (eventType ~= "SPELL_AURA_REMOVED" and not eventType:find("PERIODIC") ) then -- Ignore removed, they could have left a battleground and had debuffs.
					--[[
					if FlagIsEnemy(srcFlags) and FlagIsEnemy(dstFlags) then
						--self:EnemyAtEnemyLocation(srcName, dstName)
						local enemyLoc = core:GetEnemyLocation({name=srcName});
						
						if (enemyLoc and GetTime() - enemyLoc.time < 5) then
							--core:Debug(tostring(srcName) .. " and " .. tostring(dstName) .. " are interacting together.");
						
							-- Refresh loc for source.
							core:SaveEnemyLocation({
								name	= srcName,
								x       = enemyLoc.x,
								y       = enemyLoc.y,
							});
							
							-- Set loc for dest.
							core:SaveEnemyLocation({
								name	= dstName,
								x       = enemyLoc.x,
								y       = enemyLoc.y,
							});
							
						end
					else
					]]
					if FlagIsEnemy(srcFlags) and FlagIsFriendly(dstFlags) then
						core:PlayersInteracting({
							friend = dstName, -- UnitName("player")
							enemy = srcName
						});
					elseif FlagIsEnemy(dstFlags) and FlagIsFriendly(srcFlags) then
						core:PlayersInteracting({
							friend = srcName, -- UnitName("player")
							enemy = dstName
						});
					end
				end
			end
		end
		
		if (eventType == "UNIT_DIED") then
			core:Debug("eventType: " .. eventType .. ", srcName: " .. tostring(srcName) .. ", dstName: " .. tostring(dstName));
			if (FlagIsPlayer(dstFlags) and FlagIsEnemy(dstFlags)) then
				core:RemoveEnemyLocation({ name = dstName })
			end
		end
		
	end
	
end