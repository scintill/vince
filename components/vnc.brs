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

function vnc_createObject(node as object, instanceId as integer, connSpec as object) as object
	return {
		_node: node,
		_connSpec: connSpec,
		_ba: createObject("roByteArray"), ' scratch buffer frequently reused for small arrays
		_bitmapCounter: 0,
		_instanceId: instanceId,

		start: function() as dynamic
			m._socket = createObject("roStreamSocket")
			addrOb = createObject("roSocketAddress")
			addr = m._connSpec.hostname+":"+m._connSpec.port
			if addrOb.setAddress(addr) = false then
				return "Invalid address "+addr
			end if
			if m._socket.setSendToAddress(addrOb) = false then
				return "Unable to initiate connection to "+addr
			end if
			if m._socket.connect() = false then
				return "Unable to open connection to "+addr
			end if
			skt_adopt(m._socket)

			' https://tools.ietf.org/html/rfc6143
			' handshake
			msg = skt_receiveStr(m._socket, 12)
			if msg = invalid goto connlost
			if (left(msg, 8) = "RFB 003." and asc(right(msg, 1)) = 10) = false then return "Server sent invalid version number"
			if skt_sendStr(m._socket, "RFB 003.003" + chr(10)) <> 12 goto connlost

			securityType = skt_receiveU32(m._socket)
			if securityType = invalid then
				goto connlost
			else if securityType = 0 then
				return m._readSecurityFailureReason()
			else if securityType = 1 then ' type None
				' do nothing
			else if securityType = 2 then ' type VNC
				result = m._doVNCTypeAuth()
				if type(result) <> "Boolean" or result <> true then
					return result
				end if
			else
				return "Security is required (type "+stri(securityType)+"), but is unsupported"
			end if

			' init
			if skt_sendStr(m._socket, chr(1)) <> 1 goto connlost ' shared-flag=1
			m._fbWidth = skt_receiveU16(m._socket)
			m._fbHeight = skt_receiveU16(m._socket)
			if m._fbWidth = invalid or m._fbHeight = invalid goto connlost

			return true

		connlost:
			return "Connection lost"
		end function

		_readSecurityFailureReason: function() as string
			reasonLength = skt_receiveU32(m._socket)
			reason = invalid
			if reasonLength <> invalid then
				reason = skt_receiveStr(m._socket, reasonLength)
			end if
			if reason = invalid then
				reason = "unknown reason"
			end if
			return "Connection failed - "+reason
		end function,

		_doVNCTypeAuth: function() as dynamic
			challenge = skt_receiveBytes(m._socket, 16)
			if challenge = invalid goto connlost

			pwd = createObject("roByteArray")
			pwd.fromAsciiString(left(m._connSpec.passwd, 8)) ' truncate to 8 chars
			pwd[8] = 0 ' pad to 8 chars if needed by adding a null ninth
			pwd.delete(8) ' truncate to 8 chars again
			' reverse the bits of each byte
			for i = 0 to 7
				' https://stackoverflow.com/questions/2602823/in-c-c-whats-the-simplest-way-to-reverse-the-order-of-bits-in-a-byte
				pwd[i] = ((pwd[i] and &hf0) >> 4) or ((pwd[i] and &h0f) << 4)
				pwd[i] = ((pwd[i] and &hcc) >> 2) or ((pwd[i] and &h33) << 2)
				pwd[i] = ((pwd[i] and &haa) >> 1) or ((pwd[i] and &h55) << 1)
			end for
			cipher = createObject("roEVPCipher")
			if cipher.setup(true, "des-ecb", pwd.toHexString(), "", 0) <> 0 then
				return "Error setting up DES cipher"
			end if
			response = cipher.process(challenge)
			if response = invalid then
				return "Error using DES cipher"
			end if

			if skt_send(m._socket, response, 0, 16) <> 16 goto connlost
			result = skt_receiveU32(m._socket)

			if result <> 0 then
				return "Authentication failed. Please verify the password."
			end if
			return true

		connlost:
			return "Connection lost"
		end function,

		onScreenAllocated: function() as dynamic
			if skt_seekBytes(m._socket, 16) = false goto connlost ' pixelformat
			n = skt_receiveU32(m._socket)
			if n = invalid goto connlost
			if skt_receiveStr(m._socket, n) = invalid goto connlost ' desktop's name

			' SetPixelFormat
			colorFormat = m._getColorFormat(m._connSpec.bpp)
			if m._sendSetPixelFormat(colorFormat) = false goto connlost

			' SetEncodings, number of encodings, raw encoding
			if m._sendSetEncodings() = false goto connlost

			' FramebufferUpdateRequest
			if m._sendFramebufferUpdateRequest({ incremental: false, x: 0, y: 0, width: m._fbWidth, height: m._fbHeight }) = false goto connlost

			while true
				msgType = skt_receiveU8(m._socket)
				if msgType = invalid then
					goto connlost
				else if msgType = 0 then
					' FramebufferUpdate
					if skt_seekBytes(m._socket, 1) = false goto connlost ' padding
					numRects = skt_receiveU16(m._socket)
					if numRects = invalid goto connlost
					for i = 1 to numRects
						result = m._receiveRectToScreen(colorFormat)
						if type(result) <> "Boolean" or result <> true then
							return result
						end if
					end for
					if m._sendFramebufferUpdateRequest({ incremental: true, x: 0, y: 0, width: m._fbWidth, height: m._fbHeight }) = false goto connlost
				else if msgType = 1 then
					' SetColorMapEntries
					return "Server sent an invalid SetColorMapEntries command" ' should not be sent because we didn't ask for it
				else if msgType = 2 then
					' Bell
					print "Bell" ' TODO
				else if msgType = 3 then
					' ServerCutText
					if skt_seekBytes(m._socket, 3) = false goto connlost ' padding
					cutTextLength = skt_receiveU32(m._socket)
					if cutTextLength = invalid goto connlost
					if skt_seekBytes(m._socket, cutTextLength) = false goto connlost
				else
					return "Server sent an invalid message type: "+stri(msgType)
				end if
			end while ' should go forever

		connlost:
			return "Connection lost"
		end function,

		_sendFramebufferUpdateRequest: function(params as object) as boolean
			' FramebufferUpdateRequest, incremental, x, y, width, height
			if not params.incremental then
				m._ba.fromHexString("03" + "00")
			else
				m._ba.fromHexString("03" + "01")
			end if
			ba_U16ToByteArray(params.x, m._ba, 2)
			ba_U16ToByteArray(params.y, m._ba, 4)
			ba_U16ToByteArray(params.width, m._ba, 6)
			ba_U16ToByteArray(params.height, m._ba, 8)
			return skt_send(m._socket, m._ba, 0, 10) = 10
		end function,

		_sendSetPixelFormat: function(colorFormat as object) as boolean
			' SetPixelFormat, bpp, depth, little-endian, true-color, {RGB}max, {RGB}shift, padding
			if colorFormat.bpp = 32 and colorFormat.depth = 24 then
				m._ba.fromHexString("00000000" + "20" + "18" + "00" + "01" + "00ff00ff00ff" + "100800" + "000000")
			else if colorFormat.bpp = 8 and colorFormat.depth = 8 then
				m._ba.fromHexString("00000000" + "08" + "08" + "00" + "01" + "000700070003" + "050200" + "000000")
			end if
			return skt_send(m._socket, m._ba, 0, 20) = 20
		end function,

		_sendSetEncodings: function() as boolean
			m._ba.fromHexString("0200" + "0001" + "00000000")
			return skt_send(m._socket, m._ba, 0, 2+2+4) = 2+2+4
		end function,

		' XXX download only the bytes we need, not the extra/alpha byte? Server sends me blue noise if I try
		_receiveRectToScreen: function(colorFormat as object) as dynamic
			x = skt_receiveU16(m._socket)
			y = skt_receiveU16(m._socket)
			width = skt_receiveU16(m._socket)
			height = skt_receiveU16(m._socket)
			if x = invalid or y = invalid or width = invalid or height = invalid goto connlost

			'print "rect width="; width; " height="; height
			rectType = skt_receiveU32(m._socket) ' actually S32
			if rectType = invalid then
				goto connlost
			else if rectType <> 0 then
				return "Server sent invalid rect type"
			end if

			linesLoaded = 0
			' TODO can we make this faster? a better encoding could help, but it's a tradeoff between slow I/O and slow Brightscript computations
			while linesLoaded < height
				linesToFetch = min(100, height - linesLoaded)

				'logTime("start receiving "+stri(linesToFetch))
				ba = skt_receiveBytes(m._socket, width * linesToFetch * colorFormat.bpp/8)
				if ba = invalid goto connlost

				'logTime("start saving")
				bmp = bmp_createFromBytes(ba, colorFormat, width, linesToFetch, "vnc", m._instanceId, m._bitmapCounter)
				m._bitmapCounter += 1
				if bmp = invalid then
					return "Unable to render bitmap data"
				end if

				'logTime("start drawing")
				m._drawBmp(bmp, x, y, width, linesToFetch)
				'logTime("sent draw msg")

				linesLoaded += linesToFetch
				y += linesToFetch
			end while
			'logTime("done streaming")

			return true

		connlost:
			return "Connection lost"
		end function, 'run

		_drawBmp: function(bmpPath as string, x as integer, y as integer, width as integer, height as integer) as void
			m._node.msgOut = {type: "addBmp", bmp: bmpPath, x: x, y: y, width: width, height: height, redraw: false }
		end function,

		_getColorFormat: function(bppEnum as string) as object
			if bppEnum = "24" then
				return { bpp: 32, depth: 24 }
			else if bppEnum = "8" then
				return { bpp: 8, depth: 8 }
			end if
		end function,

	}
end function

'' scenegraph
function init() as void
	m.top.functionName = "vnc_task"
end function

function vnc_task() as void
	msgPort = createObject("roMessagePort")
	m.top.observeField("msgIn", msgPort)

	m.vnc = vnc_createObject(m.top, m.top.instanceId, m.top.connectionSpec)
	result = m.vnc.start()
	if type(result) <> "Boolean" or result <> true then
		m.top.msgOut = {type: "error", error: result}
		return
	else
		m.top.msgOut = {type: "allocateScreen", width: m.vnc._fbWidth, height: m.vnc._fbHeight, colorFormat: m.vnc._getColorFormat(m.top.connectionSpec.bpp)}
	end if

	while true
		msg = wait(0, msgPort)
		if type(msg) = "roSGNodeEvent" and msg.getField() = "msgIn" then
			result = vnc_msgIn(msg.getData())
			if type(result) = "String" then
				m.top.msgOut = {type: "error", error: result}
				return
			end if
		end if
	end while
end function

function vnc_msgIn(msg as object) as dynamic
	'print "vnc_msgIn ";msg
	if msg.type = "screenAllocated" then
		' XXX this doesn't return when it's working successfully, which means we can't get any more messages into the task.
		' we could work the task's messageport into the socket loop
		return m.vnc.onScreenAllocated()
	end if
	return true
end function
