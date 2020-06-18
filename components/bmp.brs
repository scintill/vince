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

function bmp_createHeader(byteCount as integer, colorFormat as object, width as integer, height as integer) as object
	ba = createObject("roByteArray")
	if ba.readFile("pkg:/images/" + stri(colorFormat.depth).mid(1) + ".bmph") = false return invalid

	' patch a few fields
	ba_U32ToByteArrayLE(ba_byteArrayToU32LE(ba, 2) + byteCount, ba, 2)
	ba_U32ToByteArrayLE(width, ba, 18)
	ba_U32ToByteArrayLE(-height, ba, 22)
	ba_U32ToByteArrayLE(byteCount, ba, 34)

	return ba
end function

function bmp_createFromBytes(imageDataBytes as object, colorFormat as object, width as integer, height as integer, namespace as string, instanceId as integer, tmpId as integer) as object
	bmpFileName = "tmp:/cfbtmp "+namespace+stri(instanceId)+stri(tmpId)+".bmp"

	' XXX Work around some kind of alpha bug (in Roku?), even though alpha is disabled.
	' The VNC server may choose to send differing values from pixel to pixel, in this byte that is supposed to be ignored. Some of
	' them cause Roku to not render correctly.
	' XXX do it in the receive loop instead? would it be faster? unroll this loop? my informal testing suggested this isn't a big deal
	if colorFormat.depth = 24 then
		for i = 3 to imageDataBytes.count()-1 step 4
			imageDataBytes[i] = &hff
		end for
	end if

	ba = bmp_createHeader(imageDataBytes.count(), colorFormat, width, height)
	ba.writeFile(bmpFileName)
	imageDataBytes.appendFile(bmpFileName)

	return bmpFileName
end function
