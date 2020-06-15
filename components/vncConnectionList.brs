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
	m.top.list = m.top.findNode("markupList")

	m.top.hasNextPanel = true
	m.top.focusable = true

	m.top.observeField("createNextPanelIndex", "createNextPanel")

	m.connections = loadConnections()

	m.renderConnections = function() as void
		content = m.top.list.content
		while content.getChildCount() > 1 ' remove all existing connections
			content.removeChildIndex(0)
		end while
		for i = m.connections.count()-1 to 0 step -1 ' TODO how to order these? MRU? currently the child node indices have to match the array indices
			connection = m.connections[i]
			node = createObject("roSGNode", "ContentNode")
			node.title = connection.hostname+":"+connection.port
			content.insertChild(node, 0)
		end for
	end function

	m.renderConnections()
end function

function normalizeConnection(connection as object) as object
	' TODO should we send hostname=invalid ("[unset]") instead?
	if connection.hostname = invalid connection.hostname = ""
	if connection.port = invalid connection.port = "5900"
	if connection.bpp = invalid connection.bpp = "24"
	if connection.passwd = invalid connection.passwd = ""
	return connection
end function

function loadConnections() as object
	reg = createObject("roRegistrySection", "connections")

	if reg.exists("json") = false return []
	conns = parseJson(reg.read("json"))

	for i = 0 to conns.count()-1
		normalizeConnection(conns[i])
	end for
	return conns
end function

function saveToRegistry(id as integer, connection as object) as void
	reg = createObject("roRegistrySection", "connections")
	m.connections[id] = connection
	reg.write("json", formatJson(m.connections))
	reg.flush()
end function

function deleteFromRegistry(id as integer) as void
	if m.connections.delete(id) = true then ' could return false if this wasn't saved in the registry yet
		reg = createObject("roRegistrySection", "connections")
		reg.write("json", formatJson(m.connections))
		reg.flush()
	end if
end function

function createNextPanel() as void
	editor = createObject("roSGNode", "vncConnectionEditor")

	i = m.top.createNextPanelIndex
	if i >= m.connections.count() then ' add
		editor.connection = {
			id: m.connections.count(),
			data: normalizeConnection({})
		}
	else
		editor.connection = {
			id: i,
			data: m.connections[i]
		}
	end if
	editor.connectionList = m.top
	m.top.nextPanel = editor
end function

' component function
function saveConnection(connection as object) as void
	saveToRegistry(connection.id, connection.data)
	m.renderConnections()
end function

' component function
function deleteConnection(id as integer) as void
	deleteFromRegistry(id)
	m.renderConnections()
end function

' component function
function connectTo(connection as object) as void
	m.top.getScene().callFunc("connectTo", connection)
end function
