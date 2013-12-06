//
//  XBOXHID.m
//  XBOXHIDController
//
//  Created by Dave Eddy on 12/4/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import "XBMCXboxHIDController.h"
#include "xbmcclient.h"

#import <IOKit/hid/IOHIDLib.h>

#define LOG(fmt, ...) do { if (self.debug) printf("%s\n", [[NSString stringWithFormat:fmt, ##__VA_ARGS__] UTF8String]); } while (0)

@implementation XBMCXboxHIDController {
    IOHIDManagerRef hidManager;
    CXBMCClient xbmc;
    NSMutableDictionary *cache;
}

- (id)initWithOptions:(NSDictionary *)options
{
    self = [super init];
    if (!self)
        return self;

    cache = [NSMutableDictionary new];

    const char *host = "127.0.0.1";
    int port = 9777;
    self.deadzone = 30;
    self.debug = NO;

    if (options[@"host"])
        host = [options[@"host"] UTF8String];
    if (options[@"port"])
        port = [options[@"port"] intValue];
    if (options[@"deadzone"])
        self.deadzone = [options[@"deadzone"] integerValue];
    if ([options[@"debug"] boolValue])
        self.debug = YES;

    xbmc = CXBMCClient(host, port);
    xbmc.SendHELO("XBMCXboxHIDController", ICON_NONE);

    return self;
}

- (id)init
{
    return [self initWithOptions:nil];
}

void gamepadWasAdded(void* inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef device) {
    XBMCXboxHIDController *self = (__bridge XBMCXboxHIDController *)inContext;
    LOG(@"%@", @"controller detected");
}

void gamepadWasRemoved(void* inContext, IOReturn inResult, void* inSender, IOHIDDeviceRef device) {
    XBMCXboxHIDController *self = (__bridge XBMCXboxHIDController *)inContext;
    LOG(@"%@", @"controller unplugged");
}

void gamepadAction(void* inContext, IOReturn inResult, void* inSender, IOHIDValueRef value) {
    XBMCXboxHIDController *self = (__bridge XBMCXboxHIDController *)inContext;
    IOHIDElementRef element = IOHIDValueGetElement(value);
    int usage = IOHIDElementGetUsage(element);
    long elementValue = IOHIDValueGetIntegerValue(value);

    [self buttonPressed:usage withValue:elementValue];
}

- (void)buttonPressed:(int)button withValue:(long)value
{
    // modify certain values to be acceptable to XBMC
    switch (button) {
        case XBOX_RAS_X: case XBOX_RAS_Y:
        case XBOX_LAS_X: case XBOX_LAS_Y:
            // modify analog sticks values (deadzone and *2)
            if (fabsl(value * 2 / 65536.0) < (self.deadzone / 100.0))
                value = 0;
            value *= 2;
            break;
        case XBOX_RTRIGGER: case XBOX_LTRIGGER:
            // modify trigger values (8 bit to 16 bit)
            value *= 256;
            break;
    }

    // cache values (important for deadzone, this way we don't spam XBMC)
    NSString *buttonString = [[NSNumber numberWithInt:button] stringValue];
    long oldvalue = [cache[buttonString] longValue];

    // value hasn't changed, don't do anything
    if (value == oldvalue)
        return;

    // NSNumber's are required to pass via NSDictionary
    NSNumber *valueNSNumber = [NSNumber numberWithLong:value];
    NSNumber *valueNSNumberAbs = [NSNumber numberWithLong:labs(value)];

    NSMutableArray *packets = [NSMutableArray new];
    NSDictionary *templ = @{
                            @"map": @"XG",
                            @"down": value ? @YES : @NO
                            };
    // switch the buttons
    switch (button) {
        case XBOX_BTN_A: [packets addObject:@{@"button": @"A"}]; break;
        case XBOX_BTN_B: [packets addObject:@{@"button": @"B"}]; break;
        case XBOX_BTN_X: [packets addObject:@{@"button": @"X"}]; break;
        case XBOX_BTN_Y: [packets addObject:@{@"button": @"Y"}]; break;

        case XBOX_BTN_BLACK: [packets addObject:@{@"button": @"black"}]; break;
        case XBOX_BTN_WHITE: [packets addObject:@{@"button": @"white"}]; break;
        case XBOX_BTN_START: [packets addObject:@{@"button": @"start"}]; break;
        case XBOX_BTN_BACK:  [packets addObject:@{@"button": @"back"}]; break;

        case XBOX_BTN_LAS: [packets addObject:@{@"button": @"leftthumbbutton"}]; break;
        case XBOX_BTN_RAS: [packets addObject:@{@"button": @"rightthumbbutton"}]; break;

        case XBOX_BTN_UP:    [packets addObject:@{@"button": @"dpadup"}]; break;
        case XBOX_BTN_DOWN:  [packets addObject:@{@"button": @"dpaddown"}]; break;
        case XBOX_BTN_LEFT:  [packets addObject:@{@"button": @"dpadleft"}]; break;
        case XBOX_BTN_RIGHT: [packets addObject:@{@"button": @"dpadright"}]; break;

        case XBOX_RTRIGGER: [packets addObject:@{@"button": @"rightanalogtrigger", @"amount": valueNSNumber}]; break;
        case XBOX_LTRIGGER: [packets addObject:@{@"button": @"leftanalogtrigger", @"amount": valueNSNumber}]; break;

        case XBOX_RAS_X:
            [packets addObject:@{@"button": value > 0 ? @"rightthumbstickright" : @"rightthumbstickleft", @"amount": valueNSNumberAbs, @"axis": @1}];
            [packets addObject:@{@"button": value > 0 ? @"rightthumbstickleft" : @"rightthumbstickright", @"down": @0, @"amount": @0, @"axis": @1}];
            break;
        case XBOX_RAS_Y:
            [packets addObject:@{@"button": value > 0 ? @"rightthumbstickdown" : @"rightthumbstickup", @"amount": valueNSNumberAbs, @"axis": @1}];
            [packets addObject:@{@"button": value > 0 ? @"rightthumbstickup" : @"rightthumbstickdown", @"down": @0, @"amount": @0, @"axis": @1}];
            break;
        case XBOX_LAS_X:
            [packets addObject:@{@"button": value > 0 ? @"leftthumbstickright" : @"leftthumbstickleft", @"amount": valueNSNumberAbs, @"axis": @1}];
            [packets addObject:@{@"button": value > 0 ? @"leftthumbstickleft" : @"leftthumbstickright", @"down": @0, @"amount": @0, @"axis": @1}];
            break;
        case XBOX_LAS_Y:
            [packets addObject:@{@"button": value > 0 ? @"leftthumbstickdown" : @"leftthumbstickup", @"amount": valueNSNumberAbs, @"axis": @1}];
            [packets addObject:@{@"button": value > 0 ? @"leftthumbstickup" : @"leftthumbstickdown", @"down": @0, @"amount": @0, @"axis": @1}];
            break;
    }

    for (NSDictionary *packet in packets) {
        // add missing data if necessary
        NSMutableDictionary *mutablePacket = [packet mutableCopy];
        for (NSString *key in templ.allKeys) {
            if (!mutablePacket[key])
                mutablePacket[key] = templ[key];
        }

        unsigned short amount = [mutablePacket[@"amount"] integerValue];
        unsigned short flags = 0;
        NSInteger axis = [mutablePacket[@"axis"] integerValue];
        if (amount)
            flags |= BTN_USE_AMOUNT;
        if ([mutablePacket[@"down"] boolValue])
            flags |= BTN_DOWN;
        else
            flags |= BTN_UP;
        if (axis)
            flags |= BTN_AXIS;

        const char *button = [mutablePacket[@"button"] UTF8String];
        const char *map = [mutablePacket[@"map"] UTF8String];

        if (self.debug) {
            NSMutableString *s = [NSMutableString stringWithString:@"{"];
            [mutablePacket enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [s appendFormat:@"%@: %@, ", key, obj];
            }];
            [s appendString:@"}"];
            LOG(@"%@", s);
        }
        xbmc.SendButton(button, map, flags, amount);
    }

    cache[buttonString] = valueNSNumber;
}

- (void)setupGamepad
{
    hidManager = IOHIDManagerCreate( kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    NSDictionary *criterion = @{
                                @kIOHIDDeviceUsagePageKey: [NSNumber numberWithInt:kHIDPage_GenericDesktop],
                                @kIOHIDDeviceUsageKey: [NSNumber numberWithInt:kHIDUsage_GD_GamePad]
                               };
    IOHIDManagerSetDeviceMatching(hidManager, (__bridge CFDictionaryRef)(criterion));
    IOHIDManagerRegisterDeviceMatchingCallback(hidManager, gamepadWasAdded, (__bridge void*)self);
    IOHIDManagerRegisterDeviceRemovalCallback(hidManager, gamepadWasRemoved, (__bridge void*)self);
    IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDManagerRegisterInputValueCallback(hidManager, gamepadAction, (__bridge void*)self);
    //IOReturn tIOReturn = IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);
    IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);
}

@end
