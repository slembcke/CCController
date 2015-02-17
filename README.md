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
