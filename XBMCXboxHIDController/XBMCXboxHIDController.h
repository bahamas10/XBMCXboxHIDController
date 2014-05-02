//
//  XBOXHID.h
//  XBOXHIDController
//
//  Created by Dave Eddy on 12/4/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <Foundation/Foundation.h>

#define XBOX_BTN_A 0x01
#define XBOX_BTN_B 0x02
#define XBOX_BTN_X 0x03
#define XBOX_BTN_Y 0x04
#define XBOX_BTN_BLACK 0x05
#define XBOX_BTN_WHITE 0x06
#define XBOX_BTN_START 0x07
#define XBOX_BTN_BACK 0x08
#define XBOX_BTN_LAS 0x09
#define XBOX_BTN_RAS 0x0a
#define XBOX_BTN_UP 0x0b
#define XBOX_BTN_DOWN 0x0c
#define XBOX_BTN_LEFT 0x0d
#define XBOX_BTN_RIGHT 0x0e
#define XBOX_LAS_X 0x30
#define XBOX_LAS_Y 0x31
#define XBOX_LTRIGGER 0x32
#define XBOX_RAS_Y 0x34
#define XBOX_RAS_X 0x33
#define XBOX_RTRIGGER 0x35

@interface XBMCXboxHIDController : NSObject
@property (assign, nonatomic) NSInteger deadzone;
@property (assign, nonatomic) BOOL debug;
@property (assign, nonatomic) BOOL always;
@property (assign, nonatomic) BOOL xbmcHasFocus;
- (id)initWithOptions:(NSDictionary *)options;
- (void)setupGamepad;
@end
