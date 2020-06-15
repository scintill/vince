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
	m.dialog = createObject("roSGNode", "Dialog")
	m.busySpinner = m.top.findNode("busySpinner")
	m.vncTask = m.top.findNode("vncTask")
	m.canvas = m.top.findNode("canvas")

	m.vncTask.observeField("msgOut", "onMsgOut")
	m.dialog.observeField("buttonSelected", "onDismissErrorDialog")
	m.dialog.observeField("wasClosed", "onDismissErrorDialog")

	m.busySpinner.poster.uri = "pkg:/images/spinner.png"
	makeCenter(m.busySpinner, 64, 64)

	m.nextInstanceId = 0
	m.isZoomed = false

	setState("connections")
end function

function setState(state as string) as void
	' TODO destroy instead of hiding?
	if state <> "error" m.top.dialog = invalid

	' TODO we are losing state here, such as the panel layout and unsaved edits made to the connection.
	' restore it when the users backs out of connection
	m.top.removeChild(m.connPanelSet)
	m.connPanelSet = invalid

	m.canvas.visible = (state = "connected" or state = "error")

	if m.canvas.visible = false then
		m.canvas.callFunc("clear")
	end if

	if state = "connecting" then
		m.vncTask.control = "run"
		m.busySpinner.visible = true
		m.top.setFocus(true) ' get key events for controlling the session
	else if state = "error" then
		m.top.dialog = m.dialog
	else if state = "connections" then
		m.connPanelSet = m.top.createChild("PanelSet")
		m.connPanelSet.createChild("vncConnectionList").id = "vncConnectionList"
	end if
	m.state = state
end function

function connectTo(connection as object) as void
	m.vncTask.instanceId = m.nextInstanceId
	m.nextInstanceId += 1
	m.vncTask.connectionSpec = connection
	setState("connecting")
end function

function onMsgOut(event as object) as void
	msg = event.getData()
	'print "top onMsg ";msg
	if msg.type = "allocateScreen" then
		setState("connected")
		m.scaleFactor = getScaleFactor(msg)

		m.canvasWidth = msg.width
		m.canvasHeight = msg.height
		m.canvas.callFunc("allocate", msg.width, msg.height, msg.colorFormat, m.vncTask.instanceId)

		m.canvas.scale = [m.scaleFactor, m.scaleFactor]
		makeCenter(m.canvas, m.canvasWidth, m.canvasHeight)
		m.isZoomed = false
		m.vncTask.msgIn = {type: "screenAllocated"}
	else if msg.type = "addBmp" then
		m.canvas.callFunc("drawBmp", msg.bmp, msg.x, msg.y, msg.width, msg.height)
		m.busySpinner.visible = false
	else if msg.type = "error" then
		showErrorDialog(msg.error, "connections")
	end if
end function

function showErrorDialog(error as string, nextState as dynamic) as void
	m.dialog.title = "Error"
	m.dialog.message = error
	m.dialog.buttons = ["OK"]

	if nextState <> invalid
		m.stateAfterDialog = nextState
	else
		m.stateAfterDialog = m.state
	end if
	setState("error")
end function

function onDismissErrorDialog() as void
	m.top.dialog = invalid
	setState(m.stateAfterDialog)
end function

function getScaleFactor(screenDims as object) as object
	uiDims = m.top.currentDesignResolution
	return min(uiDims.width / screenDims.width, uiDims.height / screenDims.height)
end function

function makeCenter(component as object, width as integer, height as integer) as object
	uiDims = m.top.currentDesignResolution
	component.translation = [
		(uiDims.width - width*component.scale[0]) / 2,
		(uiDims.height - height*component.scale[1]) / 2,
	]
end function

function isCanvasSmallerThanUI() as boolean
	uiDims = m.top.currentDesignResolution
	return (m.canvasWidth <= uiDims.width) and (m.canvasHeight <= uiDims.height)
end function

function toggleZoom() as void
	if m.scaleFactor = 1 return

	if m.isZoomed then
		m.canvas.scale = [m.scaleFactor, m.scaleFactor]
	else
		m.canvas.scale = [1, 1]
	end if
	makeCenter(m.canvas, m.canvasWidth, m.canvasHeight)
	m.isZoomed = not m.isZoomed
end function

function panZoom(direction as string) as void
	if not m.isZoomed return
	if isCanvasSmallerThanUI() return

	uiDims = m.top.currentDesignResolution
	translation = m.canvas.translation
	if m.canvasHeight > uiDims.height then
		if direction = "up" then
			translation[1] += uiDims.height*3/4
			if translation[1] > 0 then
				translation[1] = 0
			end if
		else if direction = "down" then
			translation[1] -= uiDims.height*3/4
			if (translation[1]+m.canvasHeight) < uiDims.height then
				translation[1] = uiDims.height - m.canvasHeight
			end if
		end if
	end if
	if m.canvasWidth > uiDims.width then
		if direction = "left" then
			translation[0] += uiDims.width*3/4
			if translation[0] > 0 then
				translation[0] = 0
			end if
		else if direction = "right" then
			translation[0] -= uiDims.width*3/4
			if (translation[0]+m.canvasWidth) < uiDims.width then
				translation[0] = uiDims.width - m.canvasWidth
			end if
		end if
	end if

	m.canvas.translation = translation
end function

function onKeyEvent(key as string, press as boolean) as boolean
	if m.state = "connected" or m.state = "connecting" then
		' XXX sometimes we miss keydown. why? well, it doesn't hurt to catch both down & up
		if (key = "left" and not m.isZoomed) or key = "back" then
			m.vncTask.control = "stop"
			m.vncTask.instanceId = -1
			setState("connections")
			return true
		end if
	end if
	if m.state = "connected" then
		if key = "OK" and press then
			toggleZoom()
			return true
		else if (key = "left" or key = "right" or key = "up" or key = "down") and press then
			panZoom(key)
			return true
		end if
	end if
	if m.state = "connections" then
		if key = "play" and press then
			cList = m.connPanelSet.findNode("vncConnectionList")
			if cList <> invalid and cList.nextPanel <> invalid then
				cList.nextPanel.callFunc("onPlayButton")
				return true
			end if
		end if
	end if
	return false
end function
