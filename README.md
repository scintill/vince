# Vince - VNC client for Roku OS (GPLv3+)

![Screenshot](docs/screenshot.png)

Vince is a basic view-only VNC client for Roku. It supports storing several connections and selecting them from a menu.

* Color depths of 8 or 24 bpp are supported
* VNC password authentication
* One connection can be selected as a screensaver. If the system screensaver is set to the Vince channel, that connection will be opened when the screensaver starts.

## Installing

Navigate to [https://my.roku.com/add/Vince](https://my.roku.com/add/Vince) in your browser, and log in using the Roku account associated with your device(s). Follow the directions, and Vince should appear on your homescreen.

## Usage

The menus are hopefully intuitive. When you have a connection open, press the "OK" button on your remote to toggle zooming the screen. While zoomed, use the arrow buttons to pan around. Press "OK" again to zoom out. Press "back" or "left" to exit the connection.

## Building

Currently the build relies on a Roku-provided Makefile with no explicit license. See the comment at the bottom of `Makefile` for the URL to that file, download it, and run `make` to build the zip, then [sideload it](https://developer.roku.com/en-ca/docs/developer-program/getting-started/developer-setup.md).

## License

Vince is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

The full text of the license is included in the file "COPYING". See also LICENSE.md.
