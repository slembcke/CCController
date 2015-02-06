//
//  main.m
//  ControllerTest
//
//  Created by Scott Lembcke on 1/30/15.
//  Copyright (c) 2015 Scott Lembcke. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CCController.h"

static void
ActivateController(GCController *controller)
{
	NSLog(@"Activating controller: %@", controller);
	NSLog(@"	VendorName: %@", controller.vendorName);
	
//	controller.playerIndex = 0;
	
	controller.controllerPausedHandler = ^(GCController *controller){
		NSLog(@"Pause button.");
	};
	
	controller.extendedGamepad.valueChangedHandler = ^(GCExtendedGamepad *gamepad, GCControllerElement *element){
		NSLog(@"L: (% .1f, % .1f), R: (% .1f, % .1f), DPad: (% .1f, % .1f), LT: %.1f, RT: %.1f, RS: %d, LS: %d, A: %d, B: %d, X: %d, Y: %d",
			gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value,
			gamepad.rightThumbstick.xAxis.value, gamepad.rightThumbstick.yAxis.value,
			gamepad.dpad.xAxis.value, gamepad.dpad.yAxis.value,
			gamepad.leftTrigger.value, gamepad.rightTrigger.value,
			gamepad.leftShoulder.pressed, gamepad.rightShoulder.pressed,
			gamepad.buttonA.pressed, gamepad.buttonB.pressed, gamepad.buttonX.pressed, gamepad.buttonY.pressed
		);
	};
	
	__block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:controller queue:nil usingBlock:^(NSNotification *notification){
		NSLog(@"Deactivating controller: %@", notification.object);
		[[NSNotificationCenter defaultCenter] removeObserver:observer];
	}];
}

int main(int argc, const char * argv[]) {
//	GCExtendedGamepadSnapshot *gamepad = [[GCExtendedGamepadSnapshot alloc] init];
//	for(;;){
//		@autoreleasepool {
//			[gamepad snapshotDataFast];
//		}
//	}
	
	@autoreleasepool {
		NSArray *controllers = [CCController controllers];
		NSLog(@"%d controllers found.", (int)controllers.count);
		
		for(CCController *controller in controllers){
			ActivateController(controller);
		}
		
		[[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidConnectNotification object:nil queue:nil
			usingBlock:^(NSNotification *notification){
				ActivateController(notification.object);
			}
		];
	}
	
	CFRunLoopRun();
}
