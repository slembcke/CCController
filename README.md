# CCController

I really like Apple's GameController.framework API. It's clean, simple, and fairly complete. Unfortunately on Mac it's almost useless since there basically aren't any controllers to use it with. Most players that want to use a controller with their Mac seem to use a console controller nowadays. Why not support those?! It's nice that it's cross-platform (at least iOS/Mac) too.

So I poked around and found that I could do it very easily using gamepad snapshots.

* PS4 controllers work out of the box using both USB and bluetooth.
* 360 wired controllers work if you install a driver for them. Wireless controllers also work if you have the USB reciever dongle.
* I've been told Xbox One controllers work as well.

If somebody could test this for a PS3 controller, that would be very helpful. You'll have to add the USB vid/pid to CCController.m. I'm guessing it's functionally identical to a PS4 controller otherwise.

## Use:

Instead of calling `[GCController controllers]` to get the list of controllers, call `[CCController controllers]` instead. That's all! Everything else should work as expected.

## More Controllers!

Right now the mappings are hard coded specifically for Xbox/PS controllers. I'd like to make it more configurable using a plist file though. Feral Interactive gave me permission to use their controller mapping files. @geowar1 also pointed me to some existing data. It's mostly a matter of time (or pull request?).

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
