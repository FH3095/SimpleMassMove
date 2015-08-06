--
-- Author: FH3095
--

require("ts3init")
require("ts3defs")
require("ts3errors")

local function protectTable(tbl)
	local function metaTableConstProtect(_,key,value)
		if nil ~= tbl[key] then
			print(tostring(key) .. " is a read-only variable! (Tried to change to \'" .. tostring(value) .. "\'.)")
			return
		end
		rawset(tbl,key,value)
	end

	return setmetatable ({}, -- You need to use a empty table, otherwise __newindex would only be called for first entry
		{
			__index = tbl, -- read access -> original table
			__newindex = metaTableConstProtect,
	})
end

local channelMover = {
	const = {
		MODULE_NAME = "Simple Mass Move",
		MODULE_FOLDER = "SimpleMassMove",
		DEBUG = 0,
		DEBUG_MSG_IN_CHAT = 1,
	},
	var = {},
}

channelMover.const = protectTable(channelMover.const)

function FH3095_getChannelMover()
	return channelMover
end

require(channelMover.const.MODULE_FOLDER .. "/SimpleMassMove")


local registeredEvents = {
	createMenus = channelMover.onCreateMenus,
	onMenuItemEvent = channelMover.onMenuItemEvent,
}

ts3RegisterModule(channelMover.const.MODULE_NAME, registeredEvents)
