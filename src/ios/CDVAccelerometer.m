/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import <CoreMotion/CoreMotion.h>
#import "CDVAccelerometer.h"

@interface CDVAccelerometer () {}
@property (readwrite, strong) CMMotionManager* motionManager;
@end

@implementation CDVAccelerometer


// g constant: -9.81 m/s^2
#define kGravitationalConstant -9.81

- (CDVAccelerometer*)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [self stop:nil];
}

- (void)start:(CDVInvokedUrlCommand*)command
{
    @try {
        if (!self.motionManager)
        {
            self.motionManager = [[CMMotionManager alloc] init];
        }

        if ([self.motionManager isAccelerometerAvailable]) {
            // If we're already running, stop, then start again to set the new interval.
            if (self.motionManager.isAccelerometerActive) {
                [self stop:nil];
            }

            // Assign the update interval to the motion manager and start updates
            float intervalMs = [[command.arguments objectAtIndex:0] floatValue];
            [self.motionManager setAccelerometerUpdateInterval:intervalMs/1000]; // expected in seconds

            [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {

                // Create an acceleration object
                NSMutableDictionary* accelProps = [NSMutableDictionary dictionaryWithCapacity:4];
                accelProps[@"x"] = [NSNumber numberWithDouble:accelerometerData.acceleration.x * kGravitationalConstant];
                accelProps[@"y"] = [NSNumber numberWithDouble:accelerometerData.acceleration.y * kGravitationalConstant];
                accelProps[@"z"] = [NSNumber numberWithDouble:accelerometerData.acceleration.z * kGravitationalConstant];
                accelProps[@"timestamp"] = [NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)];

                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:accelProps];
                [result setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }];
        }
        else {

            NSLog(@"Running in Simulator? All gyro tests will fail.");
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Error. Accelerometer Not Available."];

            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    } @catch (NSException *exception) {
       NSLog(@"CDVAccelerometer-start ERROR: %@", exception.reason);

       CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
       [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   }
}

- (void)onReset
{
    [self stop:nil];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    @try {
        if (self.motionManager && self.motionManager.isAccelerometerActive) {
            [self.motionManager stopAccelerometerUpdates];
        }

        if (command) {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    } @catch (NSException *exception) {
        NSLog(@"CDVAccelerometer-stop ERROR: %@", exception.reason);

        if (command) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
}

@end
