# Copyright (c) 2020 Joey Hewitt <joey@joeyhewitt.com>
#
# This file is part of Vince.
#
# Vince is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Vince is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Vince.  If not, see <https://www.gnu.org/licenses/>.

APPNAME = vince
VERSION = 0.1

ZIP_EXCLUDE_LOCAL = /.git/\* .gitignore /dist/\* /proprietary/\* /prebuild/\* /docs/\* /notes.txt

.PHONY: .always
manifest: .always
	make -C prebuild

include proprietary/app.mk # based on https://github.com/rokudev/samples/blob/master/getting%20started/makefile/app.mk
