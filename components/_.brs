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

function min(a as dynamic, b as dynamic) as dynamic
	if a < b then
		return a
	else
		return b
	end if
end function

#if debug
function assert(b as boolean, msg as string) as void
	if not b then
		print "Assertion failed: ";msg
		stop
	end if
end function
#end if

function logTime(str as string) as void
	#if debug
		t = createObject("roDateTime")
		print ":";stri(t.getSeconds()).replace(" ", "");".";stri(t.getMilliseconds()).replace(" ", "");" ";str
	#endif
end function
