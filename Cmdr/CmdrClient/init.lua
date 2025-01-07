local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Shared = script:WaitForChild("Shared")
local Util = require(Shared:WaitForChild("Util"))

if RunService:IsClient() == false then
	error(
		"[Cmdr] Server scripts cannot require the client library. Please require the server library from the server to use Cmdr in your own code."
	)
end

--[=[
	@class CmdrClient
	@client
	The Cmdr client singleton and entry point.
]=]

--[=[
	@within CmdrClient
	@prop Registry Registry
	@readonly
	Refers to the current command Registry.
]=]

--[=[
	@within CmdrClient
	@prop Dispatcher Dispatcher
	@readonly
	Refers to the current command Dispatcher.
]=]

--[=[
	@within CmdrClient
	@prop Util Util
	@readonly
	Refers to a table containing many useful utility functions.
]=]

--[=[
	@within CmdrClient
	@prop Enabled boolean
	@readonly
	Whether or not Cmdr is enabled (will show via the defined activation keys). Use [`CmdrClient:SetEnabled`](#SetEnabled) to change.
]=]

--[=[
	@within CmdrClient
	@prop PlaceName string
	@readonly
	The current place name, displayed on the interface. Use [`CmdrClient:SetPlaceName`](#SetPlaceName) to change.
]=]

--[=[
	@within CmdrClient
	@prop ActivationKeys { [Enum.KeyCode] = true }
	@readonly
	The list of key codes that will show or hide Cmdr. Use [`CmdrClient:SetActivationKeys`](#SetActivationKeys) to change.
]=]

local Cmdr
do
	Cmdr = setmetatable({
		ReplicatedRoot = script,
		RemoteFunction = script:WaitForChild("CmdrFunction"),
		RemoteEvent = script:WaitForChild("CmdrEvent"),
		ActivationKeys = { [Enum.KeyCode.F2] = true },
		Enabled = true,
		MashToEnable = false,
		ActivationUnlocksMouse = false,
		HideOnLostFocus = true,
		PlaceName = "Cmdr",
		Util = Util,
		Events = {},
	}, {
		-- This sucks, and may be redone or removed
		-- Proxies dispatch methods on to main Cmdr object
		__index = function(self, k)
			local r = self.Dispatcher[k]
			if r and type(r) == "function" then
				return function(_, ...)
					return r(self.Dispatcher, ...)
				end
			end
		end,
	})

	Cmdr.Registry = require(Shared.Registry)(Cmdr)
	Cmdr.Dispatcher = require(Shared.Dispatcher)(Cmdr)
end

do
	-- Setup Cmdr Gui loading - we need to wait for the client's character to laod
	-- since `PlayerGui` is guaranteed to be fully loaded when the character is loaded,
	-- that way we can avoid cloning a duplicate CmdrGui into the `PlayerGui` as it is
	-- possible that the developers may have a custom Cmdr gui setup in `StarterGui` already!
	local CmdrStarterGui = StarterGui:WaitForChild("Cmdr")

	if Player.Character == nil then
		Player.CharacterAdded:Wait()
	end

	if Player.PlayerGui:FindFirstChild("Cmdr") == nil then
		CmdrStarterGui:Clone().Parent = Player.PlayerGui
	end
end

local Interface = require(script.CmdrInterface)(Cmdr)

--[=[
	Sets the key codes that will used to show or hide Cmdr.

	@within CmdrClient
]=]
function Cmdr:SetActivationKeys(keys: { Enum.KeyCode })
	self.ActivationKeys = Util.MakeDictionary(keys)
end

--[=[
	Sets whether or not Cmdr can be shown via the defined activation keys. Useful for when you want users to opt-in to show the console, for instance in a settings menu.

	@within CmdrClient
]=]
function Cmdr:SetEnabled(enabled: boolean)
	self.Enabled = enabled
end

--[=[
	Sets if activation will free the mouse.

	@within CmdrClient
]=]
function Cmdr:SetActivationUnlocksMouse(enabled: boolean)
	self.ActivationUnlocksMouse = enabled
end

--[=[
	Shows the Cmdr window. Does nothing if Cmdr isn't enabled.

	@within CmdrClient
]=]
function Cmdr:Show()
	if not self.Enabled then
		return
	end

	Interface.Window:Show()
end

--[=[
	Hides the Cmdr window.

	@within CmdrClient
]=]
function Cmdr:Hide()
	Interface.Window:Hide()
end

--[=[
	Toggles the Cmdr window. Does nothing if Cmdr isn't enabled.

	@within CmdrClient
]=]
function Cmdr:Toggle()
	if not self.Enabled then
		self:Hide()
		return
	end

	Interface.Window:SetVisible(not Interface.Window:IsVisible())
end

--[=[
	Enables the "Mash to open" feature.
	This feature, when enabled, requires the activation key to be pressed 5 times within a second to [enable](#SetEnabled) Cmdr.
	This may be helpful to guard against mispresses from opening the window, for example.

	@within CmdrClient
]=]
function Cmdr:SetMashToEnable(enabled: boolean)
	self.MashToEnable = enabled

	if enabled then
		self:SetEnabled(false)
	end
end

--[=[
	Sets the hide on 'lost focus' feature.
	This feature, which is enabled by default, will cause Cmdr to [hide](#Hide) when the user clicks off the window.

	@within CmdrClient
]=]
function Cmdr:SetHideOnLostFocus(enabled: boolean)
	self.HideOnLostFocus = enabled
end

--[=[
	Sets the [network event handler](/docs/networkeventhandlers) for a certain event type.

	@within CmdrClient
]=]
function Cmdr:HandleEvent(name: string, callback: (...any) -> ())
	self.Events[name] = callback
end

--[=[
	Sets the line colors.

	@within CmdrClient
]=]

function Cmdr:SetLineColors(colors: { ValidUserText: Color3, InvalidUserText: Color3, System: Color3 })
	self.LineColors = colors
end

--[=[
	Sets the label color.

	@within CmdrClient
]=]

function Cmdr:SetLabelColor(color: Color3)
	self.LabelColor = color
end

--[=[
	Sets the label text.

	@within CmdrClient
]=]

function Cmdr:SetLabel(text: string)
	Interface.Window:SetLabel(text)
end

--[=[
	Toggles the cmdr history display.

	@within CmdrClient
]=]

function Cmdr:ToggleHistoryDisplay(toggle: boolean)
	self.ToggleHistoryDisplay = toggle 
end

if RunService:IsClient() then
	Cmdr:SetLabelColor(Color3.fromRGB(255, 223, 93))
	Cmdr:SetLineColors({
		ValidUserText = Color3.fromRGB(255, 255, 255),
		InvalidUserText = Color3.fromRGB(255, 73, 73),
		System = Color3.fromRGB(255, 255, 255),
		SystemReply = Color3.fromRGB(255, 228, 26),
	})
	Cmdr:SetLabel(`{Player.Name}$}`)
	Cmdr:ToggleHistoryDisplay(true)
end

-- "Only register when we aren't in studio because don't want to overwrite what the server portion did"
-- This is legacy code which predates Accurate Play Solo (which is now the only way to test in studio), this code will never run.
if RunService:IsServer() == false then
	Cmdr.Registry:RegisterTypesIn(script:WaitForChild("Types"))
	Cmdr.Registry:RegisterCommandsIn(script:WaitForChild("Commands"))
end

-- Hook up event listener
Cmdr.RemoteEvent.OnClientEvent:Connect(function(name, ...)
	if Cmdr.Events[name] then
		Cmdr.Events[name](...)
	end
end)

require(script.DefaultEventHandlers)(Cmdr)

return Cmdr
