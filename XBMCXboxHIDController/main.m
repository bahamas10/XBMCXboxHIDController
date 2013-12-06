//
//  main.m
//  XBOXHIDController
//
//  Created by Dave Eddy on 12/4/13.
//  Copyright (c) 2013 Dave Eddy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XBMCXboxHIDController.h"

void print_usage(FILE *stream) {
    fprintf(stream, "usage: XBMCXboxHIDController\n");
    fprintf(stream, "\n");
    fprintf(stream, "control XBMC using an original Xbox controller\n");
    fprintf(stream, "\n");
    fprintf(stream, "options\n");
    fprintf(stream, "  -d <deadzone>   deadzone percentage for analog sicks, defaults to 30\n");
    fprintf(stream, "  -h              print this message and exit\n");
    fprintf(stream, "  -H <host>       host on which to listen, defaults to 127.0.0.1\n");
    fprintf(stream, "  -p <port>       port on which to listen, defaults to 9777\n");
    fprintf(stream, "  -v              enable verbose logging\n");
}

int main(int argc, char *argv[])
{
    BOOL debug = NO;
    int port = 9777;
    int deadzone = 30;
    char *host = "127.0.0.1";
    int c;
    while ((c = getopt(argc, argv, "d:hH:p:v")) != EOF) {
        switch (c) {
            case 'd': deadzone = atoi(optarg); break;
            case 'h': print_usage(stdout); return 0;
            case 'H': host = optarg; break;
            case 'p': port = atoi(optarg); break;
            case 'v': debug = YES; break;
            case '?': print_usage(stderr); return 1;
        }
    }

    NSRunLoop *runLoop;
    XBMCXboxHIDController *main;

    NSDictionary *options = @{
                              @"debug": debug ? @YES : @NO,
                              @"host": [NSString stringWithUTF8String:host],
                              @"port": [NSNumber numberWithInt:port],
                              @"deadzone": [NSNumber numberWithInt:deadzone]
                              };
    @autoreleasepool
    {
        printf("analog deadzone of %d%%\n", deadzone);
        printf("sending events to %s:%d\n", host, port);
        printf("starting, ctrl-c to exit\n");
        runLoop = NSRunLoop.currentRunLoop;
        main = [[XBMCXboxHIDController alloc] initWithOptions:options];
        [main setupGamepad];
        while ([runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:2]]);
    };
    return 0;
}
