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
end function

function onSetValue() as void
	if m.top.value = "" then
		m.top.value = getEnumValues().keys()[0]
	end if
	m.top.findNode("labelList").content.getChild(0).title = getEnumValues()[m.top.value]
end function

function onSelect() as void
	keys = getEnumValues().keys()
	m.top.value = keys[(indexOf(keys, m.top.value)+1) mod keys.count()]
end function

function indexOf(a as object, v as dynamic) as integer
	for i = 0 to a.count()-1
		if a[i] = v return i
	end for
	return -1
end function

function getEnumValues() as object
	if m.top.key = "bpp" then
		return {
			"8": "Low Color (8 bits)"
			"24": "True Color (24 bits)"
		}
	end if
end function
