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
	m.top.rotation = 1e-33 ' gets rid of garbage that shows up when you move your cursor around a lot TODO do we care about non-OpenGL devices?

	m.renderCount = 0
end function

function allocate(width as integer, height as integer, colorFormat as object, instanceId as integer) as void
	m.Bpp = colorFormat.bpp / 8
	m.bmpHeaderLength = bmp_createHeader(0, colorFormat, 0, 0).count()
	m.fb = createObject("roByteArray") ' this holds bitmap data of the entire canvas
	m.fb.setResize(width * height * m.Bpp, false)
	m.width = width
	m.height = height
	m.colorFormat = colorFormat
	m.instanceId = instanceId
end function

function clear() as void
	cleanupPosters(m.top.getChildren(-1, 0))
end function

function drawBmp(path as string, x as integer, y as integer, width as integer, height as integer) as void
	' patch the new bmp into the canvas bitmap
	bmpBa = createObject("roByteArray")
	for yl = y to y+height-1
		' TODO optimize? do incremental math and unroll the loop?
		fbOffset = (yl*m.width + x) * m.Bpp
		bmpOffset = m.bmpHeaderLength + ((yl-y)*width) * m.Bpp
		bmpBa.readFile(path, bmpOffset, width * m.Bpp)
		j = fbOffset
		for each bmpByte in bmpBa
			m.fb[j] = bmpByte
			j += 1
		end for
	end for

	' It seems we no longer have a problem with exhausting texture memory and getting flickering images,
	' but having thousands of nodes is still probably not a good idea.
	' TODO we get double-painting the cursor when moving it quick on a 8bpp screen that hasn't repainted
	if m.top.getChildCount() > 1000 then
		' TODO also repaint every 5 seconds or so, in case there is a corruption we can't detect
		fbPath = bmp_createFromBytes(m.fb, m.colorFormat, m.width, m.height, "canvas", m.instanceId, m.renderCount)
		clear()
		addPoster(fbPath, 0, 0, true)
	else
		addPoster(path, x, y)
	end if
	m.renderCount += 1
end function

function addPoster(path as string, x as integer, y as integer, isRedraw = false) as void
	poster = createObject("roSGNode", "Poster")
	poster.translation = [x, y]
	if isRedraw = true then
		poster.loadSync = true
	end if
	poster.uri = path
	m.top.appendChild(poster)
end function

function cleanupPosters(posters as object) as void
	for each poster in posters
		deleteFile(poster.uri)
	end for
	m.top.removeChildren(posters)
end function
