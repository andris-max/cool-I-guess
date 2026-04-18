--[[
	Universal Aimbot Module - Optimized
]]

--// Luraph Macros
if LPH_OBFUSCATED == nil then
	LPH_NO_VIRTUALIZE = function(...) return ... end
end

--// Cache
local game, workspace = game, workspace
local getrawmetatable, pcall, next, tick, getgenv = getrawmetatable, pcall, next, tick, getgenv
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing and Drawing.new, TweenInfo.new
local mousemoverel, mousemoveabs, tablefind, tableremove, stringlower, stringsub, mathclamp = mousemoverel or (Input and Input.MouseMove), mousemoveabs, table.find, table.remove, string.lower, string.sub, math.clamp
local mouse1press, mouse1release, taskwait = mouse1press, mouse1release, task.wait
local clonefunction, cloneref = clonefunction or LPH_NO_VIRTUALIZE(function(...) return ... end), cloneref or LPH_NO_VIRTUALIZE(function(...) return ... end)

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	__index = LPH_NO_VIRTUALIZE(function(self, Index) return self[Index] end),
	__newindex = LPH_NO_VIRTUALIZE(function(self, Index, Value) self[Index] = Value end)
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex
local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex

local _GetService = __index(game, "GetService")
local GetService = function(Service)
	return cloneref(_GetService(game, Service))
end

--// Services
local RunService = GetService("RunService")
local UserInputService = GetService("UserInputService")
local TweenService = GetService("TweenService")
local Players = GetService("Players")

--// Service Methods
local LocalPlayer = __index(Players, "LocalPlayer")
local Camera = __index(workspace, "CurrentCamera")
local FindFirstChild, FindFirstChildOfClass = __index(game, "FindFirstChild"), __index(game, "FindFirstChildOfClass")
local GetDescendants = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetPlayers = __index(Players, "GetPlayers")
local GetPlayerFromCharacter = __index(Players, "GetPlayerFromCharacter")
local Mouse = __index(LocalPlayer, "GetMouse")(LocalPlayer)
local CameraViewportSize = __index(Camera, "ViewportSize")

--// Variables
local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
local Connect, Disconnect = __index(game, "DescendantAdded").Connect

do
	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
	Disconnect = TemporaryConnection.Disconnect
	Disconnect(TemporaryConnection)
end

--// Environment
getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed = 1,
		DisableWarnings = false
	},

	Settings = {
		Enabled = true,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = true, -- ENABLED VISIBLE CHECK

		OffsetToMoveDirection = false,
		OffsetIncrement = 15,

		Sensitivity = 0,
		Sensitivity2 = 1,

		LockMode = 1, -- 1 = CFrame; 2 = mousemoverel; 3 = mousemoveabs
		LockPart = "Head",

		TriggerKey = Enum.KeyCode.K, -- CHANGED TO LETTER K
		Toggle = false
	},

	Triggerbot = {
		Enabled = false,
		TeamCheck = false,
		AliveCheck = true,
		AimLockedCheck = false,
		Delay = 0
	},

	ClosestPlayerTracer = {
		Enabled = true,
		Position = 3,
		Transparency = 0.5,
		Thickness = 1,
		RainbowColor = false,
		Color = Color3fromRGB(150, 150, 255)
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,
		Radius = 180,
		NumSides = 60,
		Thickness = 1,
		Transparency = 1,
		Filled = false,
		RainbowColor = false,
		RainbowOutlineColor = false,
		Color = Color3fromRGB(255, 255, 255),
		OutlineColor = Color3fromRGB(0, 0, 0),
		LockedColor = Color3fromRGB(255, 150, 150)
	},

	Blacklisted = {},
	FOVCircleOutline = Drawingnew("Circle"),
	FOVCircle = Drawingnew("Circle"),
	Tracer = Drawingnew("Line")
}

local Environment, _warn = getgenv().ExunysDeveloperAimbot, clonefunction(warn)
warn = function(...)
	return not Environment.DeveloperSettings.DisableWarnings and _warn(...)
end

repeat taskwait(0) until Environment and Environment.FOVCircle and Environment.FOVCircleOutline

setrenderproperty(Environment.FOVCircle, "Visible", false)
setrenderproperty(Environment.FOVCircleOutline, "Visible", false)

--// Core Functions
local FixUsername = LPH_NO_VIRTUALIZE(function(String)
	for _, Value in next, GetPlayers(Players) do
		local Name = __index(Value, "Name")
		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
			return Name
		end
	end
end)

local GetRainbowColor = LPH_NO_VIRTUALIZE(function()
	local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed
	return Color3fromHSV(tick() % RainbowSpeed / RainbowSpeed, 1, 1)
end)

local ConvertVector = LPH_NO_VIRTUALIZE(function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end)

local CancelLock = LPH_NO_VIRTUALIZE(function()
	Environment.Locked = nil
	setrenderproperty(Environment.FOVCircle, "Color", Environment.FOVSettings.Color)
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
	if Animation then Animation:Cancel() end
	setrenderproperty(Environment.Tracer, "Visible", Environment.ClosestPlayerTracer.Enabled)
end)

local GetClosestPlayer = LPH_NO_VIRTUALIZE(function(Aux)
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked or Aux then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000
		local Required3DDistance = 10000

		for _, Value in next, GetPlayers(Players) do
			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")

			if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and FindFirstChild(Character, LockPart) and Humanoid then
				local PartPosition, TeamCheckOption = __index(Character[LockPart], "Position"), Environment.DeveloperSettings.TeamCheckOption

				if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then continue end
				if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then continue end

				if Settings.WallCheck then
					local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
					for _, _Value in next, GetDescendants(Character) do
						BlacklistTable[#BlacklistTable + 1] = _Value
					end
					if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then continue end
				end

				local Vector, OnScreen, Distance = WorldToViewportPoint(Camera, PartPosition)
				Vector = ConvertVector(Vector)
				Distance = (GetMouseLocation(UserInputService) - Vector).Magnitude
				local _3DDistance = (__index(Camera, "CFrame").Position - PartPosition).Magnitude

				if Distance < RequiredDistance and _3DDistance < Required3DDistance and OnScreen then
					RequiredDistance, Required3DDistance = Distance, _3DDistance
					if not Aux then Environment.Locked = Value elseif not Running and not Environment.Locked then return Value end
				end
			end
		end
	elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera, __index(__index(__index(Environment.Locked, "Character"), LockPart), "Position")))).Magnitude > RequiredDistance then
		CancelLock()
	end
end)

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")
	local Settings, Triggerbot, Tracer, FOVCircle, FOVCircleOutline, TracerSettings, FOVSettings = Environment.Settings, Environment.Triggerbot, Environment.Tracer, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.ClosestPlayerTracer, Environment.FOVSettings
	local UpdateMode = Environment.DeveloperSettings.UpdateMode
	local TeamCheckOption = Environment.DeveloperSettings.TeamCheckOption

	if mouse1press and mouse1release then
		ServiceConnections.Triggerbot = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
			if Triggerbot.Enabled and Mouse.Target then
				local Character = Mouse.Target.Parent
				local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
				local Player = GetPlayerFromCharacter(Players, Character)

				if Character and Humanoid and Player then
					if Triggerbot.TeamCheck and __index(Player, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then return end
					if Triggerbot.AliveCheck and __index(Humanoid, "Health") <= 0 then return end
					if Triggerbot.AimLockedCheck and not Environment.Locked then return end
					if Triggerbot.Delay ~= 0 then taskwait(Triggerbot.Delay) end
					mouse1press(); taskwait(0); mouse1release()
				end
			end
		end))
	end

	ServiceConnections.UpdateTracer = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
		local ClosestPlayer = TracerSettings.Enabled and Settings.Enabled and GetClosestPlayer(true)
		if ClosestPlayer then
			setrenderproperty(Tracer, "Visible", true)
			for Index, Value in next, TracerSettings do
				if Index ~= "Color" and pcall(getrenderproperty, Tracer, Index) then setrenderproperty(Tracer, Index, Value) end
			end
			setrenderproperty(Tracer, "Color", TracerSettings.RainbowColor and GetRainbowColor() or TracerSettings.Color)
			
			if TracerSettings.Position == 1 then setrenderproperty(Tracer, "From", Vector2new(CameraViewportSize.X / 2, CameraViewportSize.Y))
			elseif TracerSettings.Position == 2 then setrenderproperty(Tracer, "From", CameraViewportSize / 2)
			else setrenderproperty(Tracer, "From", GetMouseLocation(UserInputService)) end

			setrenderproperty(Tracer, "To", ConvertVector(WorldToViewportPoint(Camera, __index(__index(ClosestPlayer, "Character")[Settings.LockPart], "Position"))))
		else
			setrenderproperty(Tracer, "Visible", false)
		end
	end))

	ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
		if FOVSettings.Enabled and Settings.Enabled then
			for Index, Value in next, FOVSettings do
				if Index ~= "Color" and pcall(getrenderproperty, FOVCircle, Index) then
					setrenderproperty(FOVCircle, Index, Value)
					setrenderproperty(FOVCircleOutline, Index, Value)
				end
			end
			setrenderproperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or FOVSettings.RainbowColor and GetRainbowColor() or FOVSettings.Color)
			setrenderproperty(FOVCircleOutline, "Color", FOVSettings.RainbowOutlineColor and GetRainbowColor() or FOVSettings.OutlineColor)
			setrenderproperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
			setrenderproperty(FOVCircle, "Position", GetMouseLocation(UserInputService))
			setrenderproperty(FOVCircleOutline, "Position", GetMouseLocation(UserInputService))
		else
			setrenderproperty(FOVCircle, "Visible", false)
			setrenderproperty(FOVCircleOutline, "Visible", false)
		end

		if Running and Settings.Enabled then
			GetClosestPlayer()
			local Offset = Settings.OffsetToMoveDirection and __index(FindFirstChildOfClass(__index(Environment.Locked, "Character"), "Humanoid"), "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10) or Vector3zero

			if Environment.Locked then
				local LockedPos3D = __index(__index(Environment.Locked, "Character")[Settings.LockPart], "Position")
				local LockedPos2D = WorldToViewportPoint(Camera, LockedPos3D + Offset)

				if Settings.LockMode == 2 then
					mousemoverel((LockedPos2D.X - GetMouseLocation(UserInputService).X) / Settings.Sensitivity2, (LockedPos2D.Y - GetMouseLocation(UserInputService).Y) / Settings.Sensitivity2)
				elseif Settings.LockMode == 3 and mousemoveabs then
					mousemoveabs(LockedPos2D.X, LockedPos2D.Y)
				else
					if Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, LockedPos3D + Offset)})
						Animation:Play()
					else
						__newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, LockedPos3D + Offset))
					end
					__newindex(UserInputService, "MouseDeltaSensitivity", 0)
				end
				setrenderproperty(FOVCircle, "Color", FOVSettings.LockedColor)
				setrenderproperty(Tracer, "Visible", false)
			end
		end
	end))

	ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), LPH_NO_VIRTUALIZE(function(Input)
		if Typing then return end
		if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Settings.TriggerKey) or Input.UserInputType == Settings.TriggerKey then
			if Settings.Toggle then
				Running = not Running
				if not Running then CancelLock() end
			else
				Running = true
			end
		end
	end))

	ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), LPH_NO_VIRTUALIZE(function(Input)
		if Typing then return end
		if (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Settings.TriggerKey) or Input.UserInputType == Settings.TriggerKey then
			Running = false; CancelLock()
		end
	end))
end

--// Typing Check
ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function() Typing = true end)
ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function() Typing = false end)

repeat taskwait(0) until Environment and Load

Environment.Exit = LPH_NO_VIRTUALIZE(function(self)
	for Index, _ in next, ServiceConnections do pcall(Disconnect, ServiceConnections[Index]) end
	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetRainbowColor = nil; FixUsername = nil
	self.FOVCircle:Remove(); self.FOVCircleOutline:Remove(); self.Tracer:Remove()
	getgenv().ExunysDeveloperAimbot = nil; pcall(collectgarbage, "step", 200)
end)

Environment.Restart = LPH_NO_VIRTUALIZE(function()
	for Index, _ in next, ServiceConnections do pcall(Disconnect, ServiceConnections[Index]) end
	Load()
end)

Environment.Blacklist = LPH_NO_VIRTUALIZE(function(self, Username)
	Username = FixUsername(Username)
	if Username then self.Blacklisted[#self.Blacklisted + 1] = Username end
end)

Environment.Whitelist = LPH_NO_VIRTUALIZE(function(self, Username)
	Username = FixUsername(Username)
	if Username then
		local Index = tablefind(self.Blacklisted, Username)
		if Index then tableremove(self.Blacklisted, Index) end
	end
end)

Environment.GetClosestPlayer = LPH_NO_VIRTUALIZE(function() return GetClosestPlayer(true) end)
Environment.Load = Load
setmetatable(Environment, {__call = Load})

return Environment
