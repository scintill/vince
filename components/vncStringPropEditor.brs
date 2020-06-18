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
	m.top.focusable = true
	m.top.hasNextPanel = false
	m.top.panelSize = "medium"
	m.top.list = m.top.findNode("labelList")
	m.top.list.observeField("itemSelected", "onSelect")

	m.setDisplayValue = function() as void
		displayValue = m.top.value
		if m.top.valueExists = false then
			displayValue = "[unset]"
		else if displayValue = ""
			displayValue = "[empty]"
		end if
		m.top.findNode("labelList").content.getChild(0).title = displayValue
	end function

	m.top.valueExists = false
	m.setDisplayValue()
end function

function setDisplayValue() as void
	m.setDisplayValue()
end function

function onSelect() as void
	value = m.top.value
	if m.top.valueExists = false then
		value = ""
	end if
	global_keyboardShow(m.top, m.top.title, value, "onKeyboardClose")
end function

function onKeyboardClose() as void
	response = global_keyboardGetResponse()
	if response <> invalid ' invalid means cancel the edit
		m.top.value = response
		m.top.valueExists = true
	end if
end function
