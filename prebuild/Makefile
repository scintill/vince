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

NODE ?= node # or nodes
all: fonts bmps

fonts: ../fonts ../fonts/fa-regular-400.ttf ../fonts/fa-solid-900.ttf
bmps: ../images/8.bmph ../images/24.bmph

../fonts:
	mkdir $@

../fonts/%: %
	pyftsubset $< --output-file=$@ --name-IDs='*' --text=""

../images/8.bmph: bmph.js
	$(NODE) ./bmph.js 8 | base64 -d > $@

../images/24.bmph: bmph.js
	$(NODE) ./bmph.js 24 | base64 -d > $@
