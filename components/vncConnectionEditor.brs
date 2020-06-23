' Copyright (c) 2020 Joey Hewitt <joey@joeyhewitt.com>
'
' This file is part of Vince.
'
' Vince is free software: you can redistribute it and/or modify
' it under the terms of the GNU General Public License as published by
' the Free Software Foundation, either version 3 of the License, or
' (at your option) any later version.
'
' Vince is distributed in the hope that it will be useful,
' but WITHOUT ANY WARRANTY; without even the implied warranty of
' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
' GNU General Public License for more details.
'
' You should have received a copy of the GNU General Public License
' along with Vince.  If not, see <https://www.gnu.org/licenses/>.

function init() as void
	m.propList = m.top.findNode("propList")
	m.propListPanel = m.top

	m.propListPanel.list = m.propList
	m.propListPanel.focusable = true

	m.propListPanel.observeField("createNextPanelIndex", "createNextPanel")
	m.propList.observeField("itemSelected", "onItemSelected")
end function

function getContentNode(i as integer) as object
	return m.propList.content.getChild(i)
end function

function onItemSelected() as void
	action = getContentNode(m.propList.itemSelected).description
	if action = "_connect" then
		m.top.connectionList.callFunc("connectTo", m.connection.data)
	else if action = "_save" then
		errors = validateConnectionSpec()
		if errors.count() > 0 then
			m.top.getScene().callFunc("showErrorDialog", errors.join(chr(10)), invalid)
		else
			m.top.connectionList.callFunc("saveConnection", m.connection)
		end if
	else if action = "_delete" then
		m.top.connectionList.callFunc("deleteConnection", m.connection.id)
	end if
end function

function onPropValueChange(event as object) as void
	value = componentValueToModelValue(m.currentConnectionKey, event.getRoSGNode().value)
	m.connection.data[m.currentConnectionKey] = value
end function

function modelValueToComponentValue(key as string, value as dynamic) as dynamic
	if key = "isScreenSaver" then
		if value then
			value = "true"
		else
			value = "false"
		end if
	end if
	return value
end function

function componentValueToModelValue(key as string, value as dynamic) as dynamic
	if key = "isScreenSaver" then
		value = (value = "true")
	end if
	return value
end function

function onSetConnection() as void
	m.connection = m.top.connection
end function

function createPropEditor(cnode as object) as object
	connectionValue = m.connection.data[cnode.description]

	if cnode.description = "bpp" or cnode.description = "isScreenSaver" then
		propEditor = createObject("roSGNode", "vncEnumPropEditor")
	else
		propEditor = createObject("roSGNode", "vncStringPropEditor")
		propEditor.valueExists = (connectionValue <> invalid)
	end if
	propEditor.title = cnode.title
	propEditor.key = cnode.description
	propEditor.value = modelValueToComponentValue(propEditor.key, connectionValue)
	propEditor.observeField("value", "onPropValueChange")
	return propEditor
end function

function createNextPanel() as void
	cnode = getContentNode(m.propListPanel.createNextPanelIndex)
	action = cnode.description
	if action = "_save" or action = "_delete" or action = "_connect" then
		m.propListPanel.nextPanel = invalid
		m.propListPanel.hasNextPanel = false
		m.propListPanel.selectButtonMovesPanelForward = false
		return
	end if

	m.propListPanel.nextPanel = createPropEditor(cnode)
	m.propListPanel.hasNextPanel = true
	m.propListPanel.selectButtonMovesPanelForward = true
	m.currentConnectionKey = cnode.description
end function

function validateConnectionSpec() as object
	data = m.connection.data
	errors = []

	if val(data.port, 10) <= 0 then
		errors.push("Port must be a number greater than 0")
	end if

	return errors
end function

' component function
' kinda ugly, but plumbing back from the scene is probably easier than getting this event to bubble the way I want
function onPlayButton() as void
	m.top.connectionList.callFunc("connectTo", m.connection.data)
end function
