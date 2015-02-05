#import <GameController/GCController.h>


@interface CCController : GCController
@end


@interface GCExtendedGamepad(SnapshotDataFast)

// Get a snapshot data instance directly from a gamepad without needing to make a snapshot object.
// Also a necessary workaround for a *massive* memory leak in -saveSnapshot in 10.9.
-(NSData *)snapshotDataFast;

@end
