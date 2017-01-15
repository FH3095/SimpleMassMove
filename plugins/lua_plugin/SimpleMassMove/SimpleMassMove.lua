
local channelMover = FH3095_getChannelMover()

channelMover.const.menuIDs = {
	MOVE_ALL_FROM_CHANNEL_TO_MY_CHANNEL = 1,
	MOVE_ALL_FROM_MY_CHANNEL_TO_CHANNEL = 2,
	MOVE_ALL_TO_MY_CHANNEL = 3,
}

function channelMover:printMsg(msg)
	ts3.printMessage(ts3.getCurrentServerConnectionHandlerID(), self.const.MODULE_NAME .. ": " .. msg, 1)
end

function channelMover:debugMsg(msg)
	if self.const.DEBUG ~= 0 then
		if self.const.DEBUG_MSG_IN_CHAT ~= 0 then
			self:printMsg(msg)
		end
		print(self.const.MODULE_NAME .. ": " .. msg)
	end
end

function channelMover:getMyClientID(serverConnectionHandlerID)
	local myClientID, error = ts3.getClientID(serverConnectionHandlerID)
	if error ~= ts3errors.ERROR_ok then
		self:printMsg("Error getting own client ID: " .. error)
		return 0
	end
	if myClientID == 0 then
		self:printMsg("Not connected")
		return 0
	end
	
	return myClientID
end

function channelMover:getMyChannelID(serverConnectionHandlerID, myClientID)
	local myChannelID, error = ts3.getChannelOfClient(serverConnectionHandlerID, myClientID)
	if error ~= ts3errors.ERROR_ok then
		self:printMsg("Error getting own channel: " .. error)
		return 0
	end

	return myChannelID
end

function channelMover:moveUsers(serverConnectionHandlerID,targetChannelID,getClientsFunction)
		local function reverseTable(tbl)
			local ret = {}
			for i,v in ipairs(tbl) do
				ret[v] = i
			end
			return ret
		end
		local myClientID = self:getMyClientID(serverConnectionHandlerID)

		local channelClients, error = ts3.getChannelClientList(serverConnectionHandlerID, targetChannelID)
		if error == ts3errors.ERROR_not_connected then
			self:printMsg("Not connected")
			return
		elseif error ~= ts3errors.ERROR_ok then
			self:printMsg("Error getting client list of target channel: " .. error)
			return
		end
		channelClients = reverseTable(channelClients)

		local clients, error = getClientsFunction(serverConnectionHandlerID)
		if error == ts3errors.ERROR_not_connected then
			self:printMsg("Not connected")
			return
		elseif error ~= ts3errors.ERROR_ok then
			self:printMsg("Error getting client list: " .. error)
			return
		end

		local counter = 0
		for i=1, #clients do
			if clients[i] ~= myClientID and nil == channelClients[clients[i]] then
				error = ts3.requestClientMove(serverConnectionHandlerID, clients[i], targetChannelID, "")
				if error == ts3errors.ERROR_ok then
					counter = counter + 1
				else
					local clientName, error = ts3.getClientVariableAsString(serverConnectionHandlerID, clients[i], ts3defs.ClientProperties.CLIENT_NICKNAME)
					if error ~= ts3errors.ERROR_ok then
						self:printMsg("Error moving client with id " .. clients[i] .. ", additionally an error occurred while trying to receive this clients nickname: " .. error)
					else
						self:printMsg("Error moving \"" .. clientName .. "\": " .. error)
					end
				end
			end
		end

		self:printMsg("Moved " .. counter .. " clients.")
end

function channelMover:onChannelMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID, selectedItemID)
	self:debugMsg("ChannelMenuItemEvent: " .. serverConnectionHandlerID .. " , " .. menuType .. " , " .. menuItemID .. " , " .. selectedItemID)

	if menuItemID == self.const.menuIDs.MOVE_ALL_FROM_CHANNEL_TO_MY_CHANNEL or menuItemID == self.const.menuIDs.MOVE_ALL_FROM_MY_CHANNEL_TO_CHANNEL then
		local myClientID = self:getMyClientID(serverConnectionHandlerID)
		local myChannelID = self:getMyChannelID(serverConnectionHandlerID,myClientID)

		if myChannelID == selectedItemID then
			self:printMsg("Can't move users from your channel into your channel.")
			return
		end

		if menuItemID == self.const.menuIDs.MOVE_ALL_FROM_CHANNEL_TO_MY_CHANNEL then
			local function getClientsFunc(_)
				return ts3.getChannelClientList(serverConnectionHandlerID, selectedItemID)
			end
			self:moveUsers(serverConnectionHandlerID, myChannelID, getClientsFunc)
		elseif menuItemID == self.const.menuIDs.MOVE_ALL_FROM_MY_CHANNEL_TO_CHANNEL then
			local function getClientsFunc(_)
				return ts3.getChannelClientList(serverConnectionHandlerID, myChannelID)
			end
			self:moveUsers(serverConnectionHandlerID, selectedItemID, getClientsFunc)
		end
	end
end

function channelMover:onGlobalMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID)
	self:debugMsg("GlobalMenuItemEvent: " .. serverConnectionHandlerID .. " , " .. menuType .. " , " .. menuItemID)

	if menuItemID == self.const.menuIDs.MOVE_ALL_TO_MY_CHANNEL then
		local function getClientsFunc(_)
			return ts3.getClientList(serverConnectionHandlerID)
		end
		local myClientID = self:getMyClientID(serverConnectionHandlerID)
		local myChannelID = self:getMyChannelID(serverConnectionHandlerID,myClientID)

		self:moveUsers(serverConnectionHandlerID,myChannelID,getClientsFunc)
	end
end

-- Callback functions (not allowed to use channelMover:onMenuItemEvent)

function channelMover.onMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID, selectedItemID)
	local self = channelMover
	self:debugMsg("MenuItemEvent: " .. serverConnectionHandlerID .. " , " .. menuType .. " , " .. menuItemID .. " , " .. selectedItemID)

	if menuType == ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_CHANNEL then
		self:onChannelMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID, selectedItemID)
	elseif menuType == ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL then
		self:onGlobalMenuItemEvent(serverConnectionHandlerID, menuType, menuItemID)
	end
end

function channelMover.onCreateMenus(moduleMenuItemID)
	local self = channelMover
	self:debugMsg("Register Menu with moduleID " .. moduleMenuItemID)

	return {
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_CHANNEL, self.const.menuIDs.MOVE_ALL_FROM_CHANNEL_TO_MY_CHANNEL, "Move all from this channel to my channel", self.const.MODULE_FOLDER .. "/move_from_to_my_channel.png",},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_CHANNEL, self.const.menuIDs.MOVE_ALL_FROM_MY_CHANNEL_TO_CHANNEL, "Move all from my channel to this channel", self.const.MODULE_FOLDER .. "/move_from_my_to_channel.png",},
		{ts3defs.PluginMenuType.PLUGIN_MENU_TYPE_GLOBAL, self.const.menuIDs.MOVE_ALL_TO_MY_CHANNEL, "Move all to my channel", self.const.MODULE_FOLDER .. "/move_all.png",},
	}
end
