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

function skt_send(socket as object, ba as object, start as integer, totalWanted as integer) as integer
	msgPort = skt_getGlobalMessagePort()
	socket.notifyWritable(true)

	totalSent = 0
	while totalSent < totalWanted
		event = wait(0, msgPort)

		if socket.isWritable() then
			result = socket.send(ba, totalSent, totalWanted - totalSent)
			if result < 0 then
				return invalid
			else
				totalSent += result
			end if
		end if
	end while

	socket.notifyWritable(false)
	return totalSent
end function

function skt_receiveBytes(socket as object, totalWanted as integer) as object
	msgPort = skt_getGlobalMessagePort()
	socket.notifyReadable(true)

	ba = createObject("roByteArray")
	ba[totalWanted-1] = 0
	totalReceived = 0
	while totalReceived < totalWanted
		event = wait(0, msgPort)

		if socket.isReadable() then
			result = socket.receive(ba, totalReceived, totalWanted - totalReceived)
			' testing shows -1 is for error, example code shows 0 is for closed
			if result <= 0 then
				return invalid
			else
				totalReceived += result
			end if
		end if
	end while

	socket.notifyReadable(false)
	return ba
end function

function skt_adopt(socket as object) as void
	socket.setMessagePort(skt_getGlobalMessagePort())
	socket.notifyException(true)
end function

function skt_getGlobalMessagePort() as object
	if m.global_socketMessagePort = invalid
		m.global_socketMessagePort = createObject("roMessagePort")
	end if
	return m.global_socketMessagePort
end function

'''' everything below must use the above rather than directly doing socket I/O

function skt_seekBytes(socket as object, n as integer) as boolean
	ba = skt_receiveBytes(socket, n)
	return ba <> invalid and ba.count() = n
end function

function skt_receiveStr(socket as object, n as integer) as dynamic
	ba = skt_receiveBytes(socket, n)
	if ba = invalid return invalid
	s = ba.toAsciiString()
	if s.len() <> n return invalid
	return s
end function

function skt_receiveU8(socket as object) as dynamic
	ba = skt_receiveBytes(socket, 1)
	if ba = invalid then return invalid
	return ba[0]
end function

function skt_receiveU16(socket as object) as dynamic
	ba = skt_receiveBytes(socket, 2)
	if ba = invalid then return invalid
	return (ba[0] << 8) or ba[1]
end function

function skt_receiveU32(socket as object) as dynamic
	ba = skt_receiveBytes(socket, 4)
	if ba = invalid then return invalid
	return (ba[0] << 24) or (ba[1] << 16) or (ba[2] << 8) or ba[3]
end function

function skt_sendStr(socket as object, str as string) as integer
	ba = createObject("roByteArray")
	ba.fromAsciiString(str)
	return skt_send(socket, ba, 0, ba.count())
end function

#if debug
function skt_dumpStatus(socket as object) as void
	print "status: ";
	print "eAgain="; socket.eAgain();" ";
	print "eAlready="; socket.eAlready();" ";
	'print "eBadAddr="; socket.eBadAddr();" ";
	print "eDestAddrReq="; socket.eDestAddrReq();" ";
	print "eHostUnreach="; socket.eHostUnreach();" ";
	'print "eInvalid="; socket.eInvalid();" ";
	print "eInProgress="; socket.eInProgress();" ";
	print "eWouldBlock="; socket.eWouldBlock();" ";
	print "eSuccess="; socket.eSuccess();" ";
	print "eOK="; socket.eOK();" ";
	print "eConnAborted="; socket.eConnAborted();" ";
	print "eConnRefused="; socket.eConnRefused();" ";
	print "eConnReset="; socket.eConnReset();" ";
	print "eIsConn="; socket.eIsConn();" ";
	print "eNotConn="; socket.eNotConn();" ";
	print
end function
#end if
