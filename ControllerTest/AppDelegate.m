//
//  AppDelegate.m
//  ControllerTest
//
//  Created by Scott Lembcke on 1/30/15.
//  Copyright (c) 2015 Scott Lembcke. All rights reserved.
//

#include <IOKit/hid/IOHIDLib.h>

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

static void
GamepadInput(void *context, IOReturn result, void *sender, IOHIDValueRef value)
{
	if(result == kIOReturnSuccess){
		IOHIDElementRef element = IOHIDValueGetElement(value);
		
		uint32_t usagePage = IOHIDElementGetUsagePage(element);
		uint32_t usage = IOHIDElementGetUsage(element);
		
		int intValue = (int)IOHIDValueGetIntegerValue(value);
		float floatValue = IOHIDValueGetScaledValue(value, kIOHIDValueScaleTypeCalibrated);
		
		NSLog(@"usagePage: %02x, usage %02x, int: %d, float: %f", usagePage, usage, intValue, floatValue);
	}
}

static void
GamepadDisconnected(void *context, IOReturn result, void *sender)
{
	NSLog(@"Gamepad Disconnected.");
}

static void
GamepadConnected(void *context, IOReturn result, void *sender, IOHIDDeviceRef device)
{
	if(result == kIOReturnSuccess){
		// Register event/remove callbacks.for buttons and axes.
		NSArray *matches = @[
			@{@(kIOHIDElementUsagePageKey): @(kHIDPage_GenericDesktop)},
			@{@(kIOHIDElementUsagePageKey): @(kHIDPage_Button)},
		];
		
		IOHIDDeviceSetInputValueMatchingMultiple(device, (__bridge CFArrayRef)matches);
		IOHIDDeviceRegisterInputValueCallback(device, GamepadInput, NULL);
		
		IOHIDDeviceRegisterRemovalCallback(device, GamepadDisconnected, NULL);

		IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	IOHIDManagerRef hid = IOHIDManagerCreate(kCFAllocatorDefault, 0);

	if (IOHIDManagerOpen(hid, kIOHIDOptionsTypeNone) != kIOReturnSuccess) {
		abort();
	}
	
	// Register to get callbacks for gampads being connected.
	NSArray *matches = @[
		@{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop), @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_GamePad)},
		@{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop), @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_MultiAxisController)},
	];
	
	IOHIDManagerSetDeviceMatchingMultiple(hid, (__bridge CFArrayRef)matches);
	IOHIDManagerRegisterDeviceMatchingCallback(hid, GamepadConnected, NULL);
	
	// Pump the event loop to list all of the currently connected gamepads.
	CFRunLoopRef loop = CFRunLoopGetCurrent();
	NSString *mode = @"PollGamepads";
	IOHIDManagerScheduleWithRunLoop(hid, loop, (__bridge CFStringRef)mode);
	
	while(CFRunLoopRunInMode((CFStringRef)mode, 0, TRUE) == kCFRunLoopRunHandledSource){}

	IOHIDManagerUnscheduleFromRunLoop(hid, loop, (__bridge CFStringRef)mode);
	
	// Schedule the HID manager normally to get callbacks during runtime.
	IOHIDManagerScheduleWithRunLoop(hid, loop, kCFRunLoopDefaultMode);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
