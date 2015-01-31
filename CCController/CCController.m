#import "CCController.h"
#import <GameController/GCExtendedGamepad.h>

#include <IOKit/hid/IOHIDLib.h>


@implementation CCController {
	GCExtendedGamepadSnapShotDataV100 _snapshot;
	GCExtendedGamepadSnapshot *_gamepad;
}

@synthesize controllerPausedHandler = _controllerPausedHandler;
@synthesize vendorName = _vendorName;
@synthesize playerIndex = _playerIndex;

static IOHIDManagerRef HID_MANAGER = NULL;
static NSMutableArray *CONTROLLERS = nil;

//MARK: Class methods

+(void)initialize
{
	if(self != [CCController class]) return;
	
	HID_MANAGER = IOHIDManagerCreate(kCFAllocatorDefault, 0);
	CONTROLLERS = [NSMutableArray array];

	if (IOHIDManagerOpen(HID_MANAGER, kIOHIDOptionsTypeNone) != kIOReturnSuccess) {
		NSLog(@"Error initializing CCGameController");
		return;
	}
	
	// Register to get callbacks when gamepads are connected.
	NSArray *matches = @[
		@{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop), @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_GamePad)},
		@{@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop), @(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_MultiAxisController)},
	];
	
	IOHIDManagerSetDeviceMatchingMultiple(HID_MANAGER, (__bridge CFArrayRef)matches);
	IOHIDManagerRegisterDeviceMatchingCallback(HID_MANAGER, ControllerConnected, NULL);
	
	// Pump the event loop to list all of the currently connected gamepads.
	NSString *mode = @"CCControllerPollGamepads";
	IOHIDManagerScheduleWithRunLoop(HID_MANAGER, CFRunLoopGetCurrent(), (__bridge CFStringRef)mode);
	
	while(CFRunLoopRunInMode((CFStringRef)mode, 0, TRUE) == kCFRunLoopRunHandledSource){}

	IOHIDManagerUnscheduleFromRunLoop(HID_MANAGER, CFRunLoopGetCurrent(), (__bridge CFStringRef)mode);
	
	// Schedule the HID manager normally to get callbacks during runtime.
	IOHIDManagerScheduleWithRunLoop(HID_MANAGER, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	
	NSLog(@"CCController initialized.");
}

+ (NSArray *)controllers;
{
	
	return [[super controllers] arrayByAddingObjectsFromArray:CONTROLLERS];
}

//MARK: Lifecycle

-(instancetype)initWithDevice:(IOHIDDeviceRef)device
{
	if((self = [super init])){
		NSString *manufacturer = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDManufacturerKey));
		NSString *product = (__bridge NSString *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
		_vendorName = [NSString stringWithFormat:@"%@ %@", manufacturer, product];
		
		_snapshot.version = 0x0100;
		_snapshot.size = sizeof(_snapshot);

		_gamepad = [[GCExtendedGamepadSnapshot alloc] init];
		_gamepad.snapshotData = NSDataFromGCExtendedGamepadSnapShotDataV100(&_snapshot);
	}
	
	return self;
}

static IOHIDElementRef
GetAxis(IOHIDDeviceRef device, int axis)
{
	NSDictionary *match = @{
		@(kIOHIDElementUsagePageKey): @(kHIDPage_GenericDesktop),
		@(kIOHIDElementUsageKey): @(axis),
	};
	
	NSArray *elements = CFBridgingRelease(IOHIDDeviceCopyMatchingElements(device, (__bridge CFDictionaryRef)match, 0));
	if(elements.count != 1) NSLog(@"Warning. Oops, didn't find exactly one axis?");
	
	return (__bridge IOHIDElementRef)elements[0];
}

static void
SetupAxis(IOHIDElementRef element, int dmin, int dmax, float rmin, float rmax, int deadZone)
{
	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationMinKey), (__bridge CFTypeRef)@(rmin));
	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationMaxKey), (__bridge CFTypeRef)@(rmax));
	
	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMinKey), (__bridge CFTypeRef)@(dmin));
	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), (__bridge CFTypeRef)@(dmax));
	
	if(deadZone){
		IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationDeadZoneMinKey), (__bridge CFTypeRef)@(127 - deadZone));
		IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationDeadZoneMaxKey), (__bridge CFTypeRef)@(127 + deadZone));
	}
	
//	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationGranularityKey), (__bridge CFTypeRef)@(1.0/64.0));
}

static void
ControllerConnected(void *context, IOReturn result, void *sender, IOHIDDeviceRef device)
{
	if(result == kIOReturnSuccess){
		CCController *controller = [[CCController alloc] initWithDevice:device];
		
		// Register event/remove callbacks.for buttons and axes.
		IOHIDValueCallback valueCallback = ControllerInputGeneric;
		
		NSArray *matches = @[
			@{@(kIOHIDElementUsagePageKey): @(kHIDPage_GenericDesktop)},
			@{@(kIOHIDElementUsagePageKey): @(kHIDPage_Button)},
		];
		
		NSUInteger vid = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey)) unsignedIntegerValue];
		NSUInteger pid = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey)) unsignedIntegerValue];
		
		if(vid == 0x054C){ // Sony
			if(pid == 0x5C4){ // DualShock 4
				NSLog(@"[CCController initWithDevice:] Sony Dualshock 4 detected.");
				
				const int deadZone = 10;
				
				SetupAxis(GetAxis(device, 0x30), 0, 255, -1.0,  1.0, deadZone); // Left thumb x
				SetupAxis(GetAxis(device, 0x31), 0, 255,  1.0, -1.0, deadZone); // Left thumb y
				SetupAxis(GetAxis(device, 0x32), 0, 255, -1.0,  1.0, deadZone); // Right thumb x
				SetupAxis(GetAxis(device, 0x35), 0, 255,  1.0, -1.0, deadZone); // Right thumb y
				
				SetupAxis(GetAxis(device, 0x33), 0, 255,  0.0,  1.0, 0); // Left trigger
				SetupAxis(GetAxis(device, 0x34), 0, 255,  0.0,  1.0, 0); // Right trigger
			}
		} else if(vid == 0x045E){ // Microsoft
			if(pid == 0x028E || pid == 0x028F){ // 360 wired/wireless
				NSLog(@"[CCController initWithDevice:] Microsoft Xbox 360 controller detected.");
			}
		} else if(vid == 0x057E){ // Nintendo
			if(pid == 0x0306){
				NSLog(@"[CCController initWithDevice:] Nintendo Wiimote detected.");
			}
		}
		
		IOHIDDeviceSetInputValueMatchingMultiple(device, (__bridge CFArrayRef)matches);
		IOHIDDeviceRegisterInputValueCallback(device, valueCallback, (__bridge void *)controller);
		IOHIDDeviceRegisterRemovalCallback(device, ControllerDisconnected, (void *)CFBridgingRetain(controller));
		IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
		
		[CONTROLLERS addObject:controller];
		[[NSNotificationCenter defaultCenter] postNotificationName:GCControllerDidConnectNotification object:controller];
	}
}

static void
ControllerDisconnected(void *context, IOReturn result, void *sender)
{
	if(result == kIOReturnSuccess){
		CCController *controller = CFBridgingRelease((CFTypeRef)context);
		
		[CONTROLLERS removeObject:controller];
		[[NSNotificationCenter defaultCenter] postNotificationName:GCControllerDidDisconnectNotification object:controller];
	}
}

//MARK: Input callbacks

// Currently hardcoded for Dualshock 4 since that is all I have to test with.
static void
ControllerInputGeneric(void *context, IOReturn result, void *sender, IOHIDValueRef value)
{
	if(result == kIOReturnSuccess){
		CCController *controller = (__bridge CCController *)context;
		GCExtendedGamepadSnapShotDataV100 *snapshot = &controller->_snapshot;
		
		IOHIDElementRef element = IOHIDValueGetElement(value);
		
		uint32_t usagePage = IOHIDElementGetUsagePage(element);
		uint32_t usage = IOHIDElementGetUsage(element);
		
		int state = (int)IOHIDValueGetIntegerValue(value);
		float analog = IOHIDValueGetScaledValue(value, kIOHIDValueScaleTypeCalibrated);
		
//		NSLog(@"usagePage: 0x%02X, usage 0x%02X, value: %d / %f", usagePage, usage, state, analog);
		
		if(usagePage == kHIDPage_Button){
			switch(usage){
				case 0x02: snapshot->buttonA = state; break;
				case 0x03: snapshot->buttonB = state; break;
				case 0x01: snapshot->buttonX = state; break;
				case 0x04: snapshot->buttonY = state; break;
				case 0x05: snapshot->leftShoulder = state; break;
				case 0x06: snapshot->rightShoulder = state; break;
				case 0x0A: if(state) controller.controllerPausedHandler(controller); break;
			}
		} else if(usagePage == kHIDPage_GenericDesktop){
			if(usage == 0x39){
				switch(state){
					case  0: snapshot->dpadX =  0.0; snapshot->dpadY =  1.0; break;
					case  1: snapshot->dpadX =  1.0; snapshot->dpadY =  1.0; break;
					case  2: snapshot->dpadX =  1.0; snapshot->dpadY =  0.0; break;
					case  3: snapshot->dpadX =  1.0; snapshot->dpadY = -1.0; break;
					case  4: snapshot->dpadX =  0.0; snapshot->dpadY = -1.0; break;
					case  5: snapshot->dpadX = -1.0; snapshot->dpadY = -1.0; break;
					case  6: snapshot->dpadX = -1.0; snapshot->dpadY =  0.0; break;
					case  7: snapshot->dpadX = -1.0; snapshot->dpadY =  1.0; break;
					default: snapshot->dpadX =  0.0; snapshot->dpadY =  0.0; break;
				}
			} else {
				switch(usage){
					case 0x30: snapshot->leftThumbstickX = analog; break;
					case 0x31: snapshot->leftThumbstickY = analog; break;
					case 0x32: snapshot->rightThumbstickX = analog; break;
					case 0x35: snapshot->rightThumbstickY = analog; break;
					case 0x33: snapshot->leftTrigger = analog; break;
					case 0x34: snapshot->rightTrigger = analog; break;
				}
			}
		}
		
		controller->_gamepad.snapshotData = NSDataFromGCExtendedGamepadSnapShotDataV100(snapshot);
	}
}

//MARK: Misc

-(GCGamepad *)gamepad
{
	return (GCGamepad *)_gamepad;
}

-(GCExtendedGamepad *)extendedGamepad
{
	return _gamepad;
}

@end
