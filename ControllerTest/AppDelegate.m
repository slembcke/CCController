//
//  AppDelegate.m
//  ControllerTest
//
//  Created by Scott Lembcke on 1/30/15.
//  Copyright (c) 2015 Scott Lembcke. All rights reserved.
//

#import "AppDelegate.h"

#import "CCController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

-(void)activateController:(GCController *)controller
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
		NSLog(@"Dpad (%f, %f).", xValue, yValue);
	};
	
	[[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:controller queue:nil
		usingBlock:^(NSNotification *notification){
			NSLog(@"Deactivating controller: %@", notification.object);
		}
	];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSArray *controllers = [CCController controllers];
	NSLog(@"%d controllers found.", (int)controllers.count);
	
	for(CCController *controller in controllers){
		[self activateController:controller];
	}
	
	__weak typeof(self) _self = self;
	[[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidConnectNotification object:nil queue:nil
		usingBlock:^(NSNotification *notification){
			[_self activateController:notification.object];
		}
	];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
