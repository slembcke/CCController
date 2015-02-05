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
	
	controller.extendedGamepad.buttonA.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		NSLog(@"A button is %@.", pressed ? @"YES" : @"NO");
	};
	
	controller.extendedGamepad.buttonB.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		NSLog(@"B button is %@.", pressed ? @"YES" : @"NO");
	};
	
	controller.extendedGamepad.buttonX.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		NSLog(@"X button is %@.", pressed ? @"YES" : @"NO");
	};
	
	controller.extendedGamepad.buttonY.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		NSLog(@"Y button is %@.", pressed ? @"YES" : @"NO");
	};
	
	controller.extendedGamepad.leftShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		NSLog(@"Left shoulder is %@.", pressed ? @"YES" : @"NO");
	};
	
	controller.extendedGamepad.rightShoulder.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		NSLog(@"Right shoulder is %@.", pressed ? @"YES" : @"NO");
	};
	
	controller.extendedGamepad.dpad.valueChangedHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue){
		NSLog(@"Dpad is (%f, %f).", xValue, yValue);
	};
	
	controller.extendedGamepad.leftThumbstick.valueChangedHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue){
		NSLog(@"Left thumbstick is (%f, %f).", xValue, yValue);
	};
	
	controller.extendedGamepad.rightThumbstick.valueChangedHandler = ^(GCControllerDirectionPad *dpad, float xValue, float yValue){
		NSLog(@"Right thumbstick is (%f, %f).", xValue, yValue);
	};
	
	controller.extendedGamepad.leftTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		NSLog(@"Left trigger is %f.", value);
	};
	
	controller.extendedGamepad.rightTrigger.valueChangedHandler = ^(GCControllerButtonInput *button, float value, BOOL pressed){
		NSLog(@"Right trigger is %f.", value);
	};
	
	[[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:controller queue:nil
		usingBlock:^(NSNotification *notification){
			NSLog(@"Deactivating controller: %@", notification.object);
		}
	];
}

int main(int argc, const char * argv[]) {
//	GCExtendedGamepadSnapshot *snapshot = [[GCExtendedGamepadSnapshot alloc] init];
//	for(;;){
//		@autoreleasepool {
//			GCExtendedGamepadSnapshot *s = [snapshot saveSnapshot];
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
