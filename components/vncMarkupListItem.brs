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
	m.icon = [m.top.getChild(0), m.top.getChild(1)]
	m.label = m.top.getChild(2)
end function

function showIcon(text as string, solid = false as boolean) as void
	if solid then
		icon = m.icon[1]
	else
		icon = m.icon[0]
	end if
	icon.text = text
	icon.color = m.label.color
	icon.font.size = m.label.font.size
	m.label.text = "     "+m.label.text
	icon.visible = true
end function

function setItemContent() as void
	content = m.top.itemContent
	if content <> invalid then
		m.label.text = content.title

		action = content.description
		if action = "_add" or action = "_save" then
			m.label.color = "0x00aa00ff"
			if action = "_save" then
				showIcon("")
			else
				showIcon("", true)
			end if
		else if action = "_connect" then
			m.label.color = "0x016b9dff"
			showIcon("", true)
		else if action = "_delete" then
			m.label.color = "0xa40000ff"
			showIcon("")
		end if
	end if
end function

function setFocusPercent() as void
	if m.top.itemContent <> invalid then
		action = m.top.itemContent.description
		if action = "_add" or action = "_connect" or action = "_save" or action = "_delete" then
			return ' keep the color
		end if
	end if

	' see defaults at https://developer.roku.com/en-ca/docs/references/scenegraph/list-and-grid-nodes/labellist.md
	if m.top.focusPercent > .9 then
		m.label.color = "0x262626ff"
	else
		m.label.color = "0xddddddff"
	end if
end function

function setHeight() as void
	m.icon[0].height = m.top.height
	m.icon[1].height = m.top.height
	m.label.height = m.top.height
end function
