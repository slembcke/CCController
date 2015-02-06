#import "CCController.h"
#import <GameController/GCExtendedGamepad.h>

#include <IOKit/hid/IOHIDLib.h>


struct AxisRange {
	CFIndex min, max;
};


const float DeadZonePercent = 0.1f;


@implementation CCController {
	GCExtendedGamepadSnapShotDataV100 _snapshot;
	GCExtendedGamepadSnapshot *_gamepad;
	
	float _deadZonePercent;
	struct AxisRange _lThumbXRange;
	struct AxisRange _lThumbYRange;
	struct AxisRange _rThumbXRange;
	struct AxisRange _rThumbYRange;
	struct AxisRange _lTriggerRange;
	struct AxisRange _rTriggerRange;
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
SetupAxis(IOHIDDeviceRef device, IOHIDElementRef element, struct AxisRange *range, int dmin, int dmax)
{
	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationMinKey), (__bridge CFTypeRef)@(dmin));
	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationMaxKey), (__bridge CFTypeRef)@(dmax));
	
	// Set calibration range to the current value.
	IOHIDValueRef value = NULL;
	if(IOHIDDeviceGetValue(device, element, &value) != kIOReturnSuccess){
		NSLog(@"Error initializing gamepad axis.");
		return;
	}
	
	CFIndex rest = IOHIDValueGetIntegerValue(value);
	range->min = range->max = rest;
	
	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMinKey), (__bridge CFTypeRef)@(rest));
	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), (__bridge CFTypeRef)@(rest));
	
//	IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationGranularityKey), (__bridge CFTypeRef)@(1.0/2.0));
}

static void
ControllerConnected(void *context, IOReturn result, void *sender, IOHIDDeviceRef device)
{
	if(result == kIOReturnSuccess){
//		NSURL *url = [[NSBundle mainBundle] URLForResource:@"CCControllerConfig.plist" withExtension:nil];
//		NSDictionary *config = [NSDictionary dictionaryWithContentsOfURL:url];
//		
//		NSAssert(@"CCControllerConfig.plist not found.");
		
		CCController *controller = [[CCController alloc] initWithDevice:device];
		
		// Register event/remove callbacks.for buttons and axes.
		IOHIDValueCallback valueCallback = ControllerInputPS4;
		
		NSArray *matches = @[
			@{@(kIOHIDElementUsagePageKey): @(kHIDPage_GenericDesktop)},
			@{@(kIOHIDElementUsagePageKey): @(kHIDPage_Button)},
		];
		
		NSUInteger vid = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDVendorIDKey)) unsignedIntegerValue];
		NSUInteger pid = [(__bridge NSNumber *)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductIDKey)) unsignedIntegerValue];
		
		if(vid == 0x054C){ // Sony
			if(pid == 0x5C4){ // DualShock 4
				NSLog(@"[CCController initWithDevice:] Sony Dualshock 4 detected.");
				valueCallback = ControllerInputPS4;
				
				SetupAxis(device, GetAxis(device, 0x30), &controller->_lThumbXRange, -1.0,  1.0); // Left thumb x
				SetupAxis(device, GetAxis(device, 0x31), &controller->_lThumbYRange,  1.0, -1.0); // Left thumb y
				SetupAxis(device, GetAxis(device, 0x32), &controller->_rThumbXRange, -1.0,  1.0); // Right thumb x
				SetupAxis(device, GetAxis(device, 0x35), &controller->_rThumbYRange,  1.0, -1.0); // Right thumb y
				
				SetupAxis(device, GetAxis(device, 0x33), &controller->_lTriggerRange, 0.0,  1.0); // Left trigger
				SetupAxis(device, GetAxis(device, 0x34), &controller->_rTriggerRange, 0.0,  1.0); // Right trigger
			}
		} else if(vid == 0x045E){ // Microsoft
			if(pid == 0x028E || pid == 0x028F){ // 360 wired/wireless
				NSLog(@"[CCController initWithDevice:] Microsoft Xbox 360 controller detected.");
				valueCallback = ControllerInput360;
				
//				SetupAxis(device, GetAxis(device, 0x30), -1.0,  1.0); // Left thumb x
//				SetupAxis(device, GetAxis(device, 0x31),  1.0, -1.0); // Left thumb y
//				SetupAxis(device, GetAxis(device, 0x33), -1.0,  1.0); // Right thumb x
//				SetupAxis(device, GetAxis(device, 0x34),  1.0, -1.0); // Right thumb y
//				
//				SetupAxis(device, GetAxis(device, 0x32),  0.0,  1.0); // Left trigger
//				SetupAxis(device, GetAxis(device, 0x35),  0.0,  1.0); // Right trigger
			}
		} else if(vid == 0x057E){ // Nintendo
			if(pid == 0x0306){
				NSLog(@"[CCController initWithDevice:] Nintendo Wiimote detected.");
				
				// TODO can we do anything sensible with this?
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

static float
Clamp01(float value)
{	
	return MAX(0.0f, MIN(value, 1.0f));
}

static void
AutoCalibrateAxis(IOHIDDeviceRef device, IOHIDElementRef element, struct AxisRange *range, CFIndex value, BOOL updateDeadZone)
{
	BOOL deadZoneNeedsUpdate = NO;
	
	if(value < range->min){
		range->min = value;
		deadZoneNeedsUpdate = YES;
		
		IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMinKey), (__bridge CFTypeRef)@(value));
	}
	
	if(value > range->max){
		range->max = value;
		deadZoneNeedsUpdate = YES;
		
		IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), (__bridge CFTypeRef)@(value));
	}
	
	if(updateDeadZone && deadZoneNeedsUpdate){
		CFIndex mid = (range->min + range->max)/2;
		CFIndex deadZone = mid*DeadZonePercent;
		
		IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationDeadZoneMinKey), (__bridge CFTypeRef)@(mid - deadZone));
		IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationDeadZoneMaxKey), (__bridge CFTypeRef)@(mid + deadZone));
	}
}

static void
ControllerInput360(void *context, IOReturn result, void *sender, IOHIDValueRef value)
{
	@autoreleasepool {
		if(result == kIOReturnSuccess){
			CCController *controller = (__bridge CCController *)context;
			GCExtendedGamepadSnapShotDataV100 *snapshot = &controller->_snapshot;
			
			IOHIDElementRef element = IOHIDValueGetElement(value);
			
			uint32_t usagePage = IOHIDElementGetUsagePage(element);
			uint32_t usage = IOHIDElementGetUsage(element);
			
			int state = (int)IOHIDValueGetIntegerValue(value);
			
			// Auto-calibrate
			NSInteger min = [(__bridge NSNumber *)IOHIDElementGetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMinKey)) integerValue];
			NSInteger max = [(__bridge NSNumber *)IOHIDElementGetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMaxKey)) integerValue];
			IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMinKey), (__bridge CFTypeRef)@(MIN(min, state)));
			IOHIDElementSetProperty(element, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), (__bridge CFTypeRef)@(MAX(max, state)));
			
			float analog = IOHIDValueGetScaledValue(value, kIOHIDValueScaleTypeCalibrated);
			
	//		if(usage != 0x31 && usage != 0x30 && usage != 0x33 && usage != 0x34)
	//			NSLog(@"usagePage: 0x%02X, usage 0x%02X, value: %d / %f", usagePage, usage, state, analog);
			
			if(usagePage == kHIDPage_Button){
				switch(usage){
					case 0x01: snapshot->buttonA = state; break;
					case 0x02: snapshot->buttonB = state; break;
					case 0x03: snapshot->buttonX = state; break;
					case 0x04: snapshot->buttonY = state; break;
					case 0x05: snapshot->leftShoulder = state; break;
					case 0x06: snapshot->rightShoulder = state; break;
					case 0x09: if(state) controller.controllerPausedHandler(controller); break;
					
					// Dpad
					case 0x0E: snapshot->dpadX = Clamp01(snapshot->dpadX - (state ? 1.0f : -1.0f)); break;
					case 0x0F: snapshot->dpadX = Clamp01(snapshot->dpadX + (state ? 1.0f : -1.0f)); break;
					case 0x0D: snapshot->dpadY = Clamp01(snapshot->dpadY - (state ? 1.0f : -1.0f)); break;
					case 0x0C: snapshot->dpadY = Clamp01(snapshot->dpadY + (state ? 1.0f : -1.0f)); break;
				}
			} else if(usagePage == kHIDPage_GenericDesktop){
				switch(usage){
					case 0x30: snapshot->leftThumbstickX = analog; break;
					case 0x31: snapshot->leftThumbstickY = analog; break;
					case 0x33: snapshot->rightThumbstickX = analog; break;
					case 0x34: snapshot->rightThumbstickY = analog; break;
					case 0x32: snapshot->leftTrigger = analog; break;
					case 0x35: snapshot->rightTrigger = analog; break;
				}
			}
			
			controller->_gamepad.snapshotData = NSDataFromGCExtendedGamepadSnapShotDataV100(snapshot);
		}
	}
}

static void
ControllerInputPS4(void *context, IOReturn result, void *sender, IOHIDValueRef value)
{
	@autoreleasepool {
		if(result == kIOReturnSuccess){
			CCController *controller = (__bridge CCController *)context;
			GCExtendedGamepadSnapShotDataV100 *snapshot = &controller->_snapshot;
			
			IOHIDElementRef element = IOHIDValueGetElement(value);
			IOHIDDeviceRef device = IOHIDElementGetDevice(element);
			
			uint32_t usagePage = IOHIDElementGetUsagePage(element);
			uint32_t usage = IOHIDElementGetUsage(element);
			
			CFIndex state = (int)IOHIDValueGetIntegerValue(value);
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
					struct AxisRange *axisRange = NULL;
					BOOL updateDeadZone = YES;
					
					switch(usage){
						case 0x30: snapshot->leftThumbstickX  = analog; axisRange = &controller->_lThumbXRange; break;
						case 0x31: snapshot->leftThumbstickY  = analog; axisRange = &controller->_lThumbYRange; break;
						case 0x32: snapshot->rightThumbstickX = analog; axisRange = &controller->_rThumbXRange; break;
						case 0x35: snapshot->rightThumbstickY = analog; axisRange = &controller->_rThumbYRange; break;
						case 0x33: snapshot->leftTrigger      = analog; axisRange = &controller->_lTriggerRange; updateDeadZone = NO; break;
						case 0x34: snapshot->rightTrigger     = analog; axisRange = &controller->_rTriggerRange; updateDeadZone = NO; break;
					}
					
					if(axisRange) AutoCalibrateAxis(device, element, axisRange, state, updateDeadZone);
				}
			}
			
			controller->_gamepad.snapshotData = NSDataFromGCExtendedGamepadSnapShotDataV100(snapshot);
		}
	}
}

//MARK: Misc

-(GCGamepad *)gamepad
{
	// Not implemented for now.
	return nil;
}

-(GCExtendedGamepad *)extendedGamepad
{
	// TODO should make this weak and lazy.
	// Then we can pump the gamepad data only when it's active.
	return _gamepad;
}

@end


@implementation GCExtendedGamepad(SnapshotDataFast)

-(NSData *)snapshotDataFast
{
	GCExtendedGamepadSnapShotDataV100 snapshot = {
		.version = 0x0100,
		.size = sizeof(GCExtendedGamepadSnapShotDataV100),
		.dpadX = self.dpad.xAxis.value,
		.dpadY = self.dpad.yAxis.value,
		.buttonA = self.buttonA.value,
		.buttonB = self.buttonB.value,
		.buttonX = self.buttonX.value,
		.buttonY = self.buttonY.value,
		.leftShoulder = self.leftShoulder.value,
		.rightShoulder = self.rightShoulder.value,
		.leftThumbstickX = self.leftThumbstick.xAxis.value,
		.leftThumbstickY = self.leftThumbstick.yAxis.value,
		.rightThumbstickX = self.rightThumbstick.xAxis.value,
		.rightThumbstickY = self.rightThumbstick.yAxis.value,
		.leftTrigger = self.leftTrigger.value,
		.rightTrigger = self.rightTrigger.value,
	};
	
	return NSDataFromGCExtendedGamepadSnapShotDataV100(&snapshot);
}

@end
