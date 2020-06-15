/*
 * Copyright (c) 2020 Joey Hewitt <joey@joeyhewitt.com>
 *
 * This file is part of Vince.
 *
 * Vince is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Vince is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Vince.  If not, see <https://www.gnu.org/licenses/>.
 */

if (process.argv[2] == "8") {
	bpp = { bpp: 8, depth: 8 };
} else {
	bpp = { bpp: 32, depth: 24 };
}
console.log(Buffer.from(bmp_createHeader([], bpp, 0, 0)).toString('base64'));

function bmp_createHeader(imageDataBytes, colorFormat, width, height) {
	const dibHeaderLength = 40;
	const bmpDataOffset = 14 + dibHeaderLength + (colorFormat.bpp == 8 ? (4*256) : 0); // 8bpp has palette

	// https://en.wikipedia.org/wiki/BMP_file_format
	// http://web.archive.org/web/20080731080151/http://www.fortunecity.com/skyscraper/windows/364/bmpffrmt.html
	// https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfo?redirectedfrom=MSDN
	ba = []
	ba.push(0x42); // magic (2 bytes)
	ba.push(0x4d);
	ba_U32ToByteArrayLE(bmpDataOffset + imageDataBytes.length, ba, ba.length); // total file length
	ba.push(0); // reserved (4 bytes)
	ba.push(0);
	ba.push(0);
	ba.push(0);
	ba_U32ToByteArrayLE(bmpDataOffset, ba, ba.length); // BMP data offset
	ba_U32ToByteArrayLE(dibHeaderLength, ba, ba.length); // DIB header length
	ba_U32ToByteArrayLE(width, ba, ba.length);
	ba_U32ToByteArrayLE(-height, ba, ba.length); // negative, to store rows in top-down order
	ba.push(1); // num planes (2 bytes)
	ba.push(0);
	ba.push(colorFormat.bpp); // bpp (2 bytes)
	ba.push(0);
	ba_U32ToByteArrayLE(0, ba, ba.length); // no compression, RGB
	ba_U32ToByteArrayLE(imageDataBytes.length, ba, ba.length); // size of image
	ba_U32ToByteArrayLE(0, ba, ba.length); // x DPM
	ba_U32ToByteArrayLE(0, ba, ba.length); // y DPM
	ba_U32ToByteArrayLE(0, ba, ba.length); // num colors used
	ba_U32ToByteArrayLE(0, ba, ba.length); // num colors important

	console.assert(ba.length == 14 + dibHeaderLength, "DIB header length correct");

	if (colorFormat.bpp == 8) {
		// create a palette where each index holds the color that VNC is expressing as RGB, scaled to the 24-bit RGB
		for (let rgb = 0; rgb < 256; rgb++) {
			ba.push((rgb & 3) / 3 * 255 + 0.5); // B
			ba.push(((rgb >> 2) & 7) / 7 * 255 + 0.5); // G
			ba.push(((rgb >> 5) & 7) / 7 * 255 + 0.5); // R
			ba.push(0); // reserved
		}
	}

	console.assert(ba.length == bmpDataOffset, "BMP data offset correct");

	return ba;
}

function ba_U32ToByteArrayLE(n, ba, offset) {
	ba[offset] = n & 0xff;
	ba[offset+1] = (n >> 8) & 0xff;
	ba[offset+2] = (n >> 16) & 0xff;
	ba[offset+3] = (n >> 24) & 0xff;
}
