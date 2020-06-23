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

function mainImpl(isScreenSaver as boolean) as void
	screen = createObject("roSGScreen")
	msgPort = createObject("roMessagePort")
	screen.setMessagePort(msgPort)
	scene = screen.createScene("vncScene")
	screen.show()
	scene.callFunc("mainInit", {"isScreenSaver": isScreenSaver})

	while true
		msg = wait(0, msgPort)

		if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() return
	end while
end function

function main() as void
	mainImpl(false)
end function

function runScreenSaver() as void
	mainImpl(true)
end function
