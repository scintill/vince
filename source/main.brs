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

' TODO disable system screensaver? our usecase could involve someone watching an "idle" Roku for 20 minutes
	' https://community.roku.com/t5/Roku-Developer-Program/Is-there-a-programmatic-way-to-prevent-Roku-to-go-to-screen/m-p/326075
' TODO make sure 1080 resolution works
' TODO any fancier auth types?
' TODO screensaver mode
' TODO show docs/tips somewhere, like how to zoom
' TODO connect should validate conn details like save does
function main() as void
	screen = createObject("roSGScreen")
	msgPort = createObject("roMessagePort")
	screen.setMessagePort(msgPort)
	screen.createScene("vncScene")
	screen.show()

	while true
		msg = wait(0, msgPort)

		if type(msg) = "roSGScreenEvent" and msg.isScreenClosed() return
	end while
end function
