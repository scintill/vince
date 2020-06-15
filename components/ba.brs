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

function ba_U16ToByteArray(n as integer, ba as object, offset as integer) as void
	ba[offset] = (n >> 8) and &hff
	ba[offset+1] = n and &hff
end function

function ba_U32ToByteArrayLE(n as integer, ba as object, offset as integer) as void
	ba[offset] = n and &hff
	ba[offset+1] = (n >> 8) and &hff
	ba[offset+2] = (n >> 16) and &hff
	ba[offset+3] = (n >> 24) and &hff
end function

function ba_byteArrayToU32LE(ba as object, offset as integer) as integer
	return (ba[offset+3] << 24) or (ba[offset+2] << 16) or (ba[offset+1] << 8) or ba[offset]
end function
