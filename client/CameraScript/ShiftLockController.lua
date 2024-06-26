--!native
--!optimize 2
--[[
	// FileName: ShiftLockController
	// Written by: jmargh
	// Version 1.1
	// Description: Manages the state of shift lock mode

	// Required by:
		RootCamera

	// Note: ContextActionService sinks keys, so until we allow binding to ContextActionService without sinking
	// keys, this module will use UserInputService.
--]]
local ContextActionService = game:GetService('ContextActionService')
local Players = game:GetService('Players')
local StarterPlayer = game:GetService('StarterPlayer')
local UserInputService = game:GetService('UserInputService')
-- Settings and GameSettings are read only
local Settings = UserSettings()	-- ignore warning
local GameSettings = Settings.GameSettings

local ShiftLockController = {}

--[[ Script Variables ]]--
while not Players.LocalPlayer do
	wait()
end
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')
local ScreenGui = nil
local ShiftLockIcon = nil
local InputCn = nil
local IsShiftLockMode = false
local IsShiftLocked = false
local IsActionBound = false

-- wrapping long conditional in function
local function isShiftLockMode()
	return LocalPlayer.DevEnableMouseLock and GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch and
			LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.ClickToMove and
			GameSettings.ComputerMovementMode ~= Enum.ComputerMovementMode.ClickToMove and
			LocalPlayer.DevComputerMovementMode ~= Enum.DevComputerMovementMode.Scriptable and
			UserInputService.KeyboardEnabled and UserInputService.MouseEnabled
end

if not UserInputService.TouchEnabled then	-- TODO: Remove when safe on mobile
	IsShiftLockMode = isShiftLockMode()
end

--[[ Constants ]]--
local SHIFT_LOCK_OFF = "rbxassetid://16441982688"
local SHIFT_LOCK_OFF_HOVER = "rbxassetid://16441982688"
local SHIFT_LOCK_ON = "rbxassetid://16441982483"
local SHIFT_LOCK_ON_HOVER = "rbxassetid://16441982300"
local SHIFT_LOCK_CURSOR = 'rbxassetid://10584659375'

--[[ Local Functions ]]--
local function onShiftLockToggled()
	IsShiftLocked = not IsShiftLocked
	if IsShiftLocked then
		ShiftLockIcon.Image = SHIFT_LOCK_ON
		Mouse.Icon = SHIFT_LOCK_CURSOR
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		ShiftLockIcon.Image = SHIFT_LOCK_OFF
		Mouse.Icon = ""
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local function initialize()
	ScreenGui = _G.RobloxGui	
	local frame = ScreenGui:WaitForChild("ControlFrame"):WaitForChild("BottomLeftControl")
	
	ShiftLockIcon = frame:WaitForChild("MouseLockLabel")
	ShiftLockIcon.Image = IsShiftLocked and SHIFT_LOCK_ON or SHIFT_LOCK_OFF
	ShiftLockIcon.Visible = IsShiftLockMode
	
	ShiftLockIcon.MouseButton1Click:connect(onShiftLockToggled)
end

--[[ Public API ]]--
function ShiftLockController:IsShiftLocked()
	return IsShiftLockMode and IsShiftLocked
end

--[[ Input/Settings Changed Events ]]--
local mouseLockSwitchFunc = function(actionName, inputState, inputObject)
--	if IsShiftLockMode and inputState == Enum.UserInputState.Begin then
--		onShiftLockToggled()
--	end
	if IsShiftLockMode then
		onShiftLockToggled()
	end
end

local function disableShiftLock()
	if ShiftLockIcon then ShiftLockIcon.Visible = false end
	IsShiftLockMode = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	Mouse.Icon = ""
	--ContextActionService:UnbindAction("ToggleShiftLock")
	if InputCn then
		InputCn:disconnect()
		InputCn = nil
	end
	IsActionBound = false
end

-- TODO: Remove when we figure out ContextActionService without sinking keys
local function onShiftInputBegan(inputObject, isProcessed)
	if inputObject.UserInputType == Enum.UserInputType.Keyboard and
		(inputObject.KeyCode == Enum.KeyCode.LeftShift or inputObject.KeyCode == Enum.KeyCode.RightShift) then
		--
		mouseLockSwitchFunc()
	end
end

local function enableShiftLock()
	IsShiftLockMode = isShiftLockMode()
	if IsShiftLockMode then
		if ShiftLockIcon then
			ShiftLockIcon.Visible = true
		end
		if IsShiftLocked then
			Mouse.Icon = SHIFT_LOCK_CURSOR
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
		if not IsActionBound then
			--ContextActionService:BindActionToInputTypes("ToggleShiftLock", mouseLockSwitchFunc, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
			InputCn = UserInputService.InputBegan:connect(onShiftInputBegan)
			IsActionBound = true
		end
	end
end
--[[local shiftlock = game.ReplicatedStorage:WaitForChild("shiftlock")
shiftlock.Changed:Connect(function()
	if shiftlock.Value == true then
		enableShiftLock()
	else
		disableShiftLock()
	end
end)]]
-- NOTE: This will fire for ControlMode when the settings menu is closed. If ControlMode is
-- MouseLockSwitch on settings close, it will change the mode to Classic, then to ShiftLockSwitch.
-- This is a silly hack, but needed to raise an event when the settings menu closes.
GameSettings.Changed:Connect(function(property)
	if property == 'ControlMode' then
		if GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch then
			enableShiftLock()
		else
			disableShiftLock()
		end
	elseif property == 'ComputerMovementMode' then
		if GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove then
			disableShiftLock()
		else
			enableShiftLock()
		end
	end
end)
LocalPlayer.Changed:Connect(function(property)
	if property == 'DevEnableMouseLock' then
		if LocalPlayer.DevEnableMouseLock then
			enableShiftLock()
		else
			disableShiftLock()
		end
	elseif property == 'DevComputerMovementMode' then
		if LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.ClickToMove or
			LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable then
			--
			disableShiftLock()
		else
			enableShiftLock()
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
	-- we need to recreate guis on character load
	if true then--not UserInputService.TouchEnabled then
		initialize()
	end
end)


--[[ Initialization ]]--
 -- TODO: Remove when safe! ContextActionService crashes touch clients with tupele is 2 or more
 if true then--not UserInputService.TouchEnabled then
	initialize()
	if isShiftLockMode() then
		--ContextActionService:BindActionToInputTypes("ToggleShiftLock", mouseLockSwitchFunc, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
		InputCn = UserInputService.InputBegan:Connect(onShiftInputBegan)
		IsActionBound = true
	end
end

return ShiftLockController
