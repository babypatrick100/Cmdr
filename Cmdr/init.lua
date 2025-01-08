local RunService = game:GetService("RunService")

local Util = require(script.Shared.Util)

if RunService:IsServer() == false then
	error(
		"[Cmdr] Client scripts cannot require the server library. Please require the client library from the client to use Cmdr in your own code."
	)
end

--[=[
	@class Cmdr
	@server

	The Cmdr server singleton and entry point.
]=]

--[=[
	@within Cmdr
	@prop Registry Registry
	@readonly
	Refers to the current command Registry.
]=]

--[=[
	@within Cmdr
	@prop Dispatcher Dispatcher
	@readonly
	Refers to the current command Dispatcher.
]=]

--[=[
	@within Cmdr
	@prop Util Util
	@readonly
	Refers to a table containing many useful utility functions.
]=]

local Cmdr
do
	Cmdr = setmetatable({
		ReplicatedRoot = nil,
		RemoteFunction = nil,
		RemoteEvent = nil,
		Util = Util,
		DefaultCommandsFolder = script.BuiltInCommands,
	}, {
		__index = function(self, k)
			local registryMethod = self.Registry[k]
			if registryMethod == nil then
				return nil
			end

			if typeof(registryMethod) ~= "function" then
				return registryMethod
			end

			return function(_, ...)
				return registryMethod(self.Registry, ...)
			end
		end,
	})

	Cmdr.Registry = require(script.Shared.Registry)(Cmdr)
	Cmdr.Dispatcher = require(script.Shared.Dispatcher)(Cmdr)

	require(script.Initialize)(Cmdr)
end

Cmdr:SetCommandExecutionTextValidator(function(_, text)
	if #text > 10000 then
		return "Input too long"
	end

	return nil
end)

-- Handle command invocations from the clients.
Cmdr.RemoteFunction.OnServerInvoke = function(player, text, options)
	local response = Cmdr.CommandExecutionTextValidator(player, text, options)
	if response ~= nil then
		return response
	end

	return Cmdr.Dispatcher:EvaluateAndRun(text, player, options)
end

return Cmdr
