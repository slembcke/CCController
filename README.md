IMPORTANT! It seems there is a fatal bug in [GCControllerSnapshot snapshotData] that prevents them from being used on OS X 10.11. Until Apple fixes it, this library can only be used on 10.9 or 10.10.

# CCController

I rather like Apple's GameController.framework API. It's clean, simple, and fairly complete, and (mildly) cross-platform. Unfortunately it's nearly useless on the Mac since nobody really has controllers to use with it. Most computer players use their console controllers on their computer, and using gamepad snapshots it's easy to trick GameController.framework into supporting them.

* PS4 controllers work out of the box using both USB and bluetooth.
* 360 wired controllers work if you install a driver for them. Wireless controllers also work if you have the Microsoft USB reciever dongle.
* I've been told Xbox One and PS3 controllers work as well.

## Use:

Instead of calling `[GCController controllers]` to get the list of controllers, call `[CCController controllers]` instead. That's all! Everything else should "just work" as expected.

## More Controllers!

Right now the mappings are hard coded specifically for Xbox/PS controllers. I'd like to make it more configurable using a plist file though. Feral Interactive gave me permission to use their controller mapping files. @geowar1 also pointed me to some existing data. It's mostly a matter of time (or pull a request?).

## License

Licensed under the MIT license:

Copyright (c) 2015 Scott Lembcke and Howling Moon Software

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
