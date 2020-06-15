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

function global_keyboardShow(component as object, title as string, text as string, callback as string) as void
	keyboardDlg = createObject("roSGNode", "KeyboardDialog")
	keyboardDlg.title = title
	keyboardDlg.text = text
	keyboardDlg.buttons = ["OK", "Cancel"]
	keyboardDlg.observeField("buttonSelected", callback)
	keyboardDlg.keyboard.textEditBox.cursorPosition = len(text)
	component.getScene().dialog = keyboardDlg
	m.global_keyboardDlg = keyboardDlg
end function

function global_keyboardGetResponse() as dynamic
	keyboardDlg = m.global_keyboardDlg
	keyboardDlg.unobserveField("buttonSelected")
	m.global_keyboardDlg = invalid
	keyboardDlg.getScene().dialog = invalid
	if keyboardDlg.buttonSelected = 0 then
		return keyboardDlg.text
	else
		return invalid
	end if
end function
