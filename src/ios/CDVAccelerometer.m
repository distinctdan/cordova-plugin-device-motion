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

NSString* callbackId;
bool hasAddedAccelCallback = false;
bool isStarted = false;
double updateIntervalMs = 1000; // This value is overwritten by the js default


// g constant: -9.81 m/s^2
#define kGravitationalConstant -9.81

- (void)pluginInitialize
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPause) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onResume) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)dealloc
{
    [self stop:nil];
    // Notifications are unbound in CDVPlugin
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

            callbackId = command.callbackId;
            isStarted = true;
            updateIntervalMs = [[command.arguments objectAtIndex:0] floatValue];
            [self _startAccelUpdates];
        }
        else {

            NSLog(@"Running in Simulator? All gyro tests will fail.");
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Error. Accelerometer Not Available."];

            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    } @catch (NSException *exception) {
       [self onErrorWithMethodName:@"start" withException:exception];
   }
}

- (void)_startAccelUpdates
{
    hasAddedAccelCallback = true;

    [self.motionManager setAccelerometerUpdateInterval:updateIntervalMs/1000]; // expected in seconds
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {

        // Create an acceleration object
        NSMutableDictionary* accelProps = [NSMutableDictionary dictionaryWithCapacity:4];
        accelProps[@"x"] = [NSNumber numberWithDouble:accelerometerData.acceleration.x * kGravitationalConstant];
        accelProps[@"y"] = [NSNumber numberWithDouble:accelerometerData.acceleration.y * kGravitationalConstant];
        accelProps[@"z"] = [NSNumber numberWithDouble:accelerometerData.acceleration.z * kGravitationalConstant];
        accelProps[@"timestamp"] = [NSNumber numberWithDouble:([[NSDate date] timeIntervalSince1970] * 1000)];

        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:accelProps];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    @try {
        if (self.motionManager && self.motionManager.isAccelerometerActive) {
            [self.motionManager stopAccelerometerUpdates];
        }

        callbackId = nil;
        isStarted = false;
        hasAddedAccelCallback = false;

        if (command) {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    } @catch (NSException *exception) {
        [self onErrorWithMethodName:@"stop" withException:exception];
    }
}

- (void)onReset
{
    @try {
        [self stop:nil];
    } @catch (NSException *exception) {
        [self onErrorWithMethodName:@"onReset" withException:exception];
    }
}

- (void)onPause
{
    @try {
        // Stop getting motion updates to avoid wasting battery while we're in the background.
        if (self.motionManager && self.motionManager.isAccelerometerActive) {
            [self.motionManager stopAccelerometerUpdates];
            hasAddedAccelCallback = false;
        }
    } @catch (NSException *exception) {
        [self onErrorWithMethodName:@"onPause" withException:exception];
    }
}

- (void)onResume
{
    @try {
        // Restart watching the accelerometer if we were already started.
        if (isStarted && self.motionManager && !hasAddedAccelCallback) {
            [self _startAccelUpdates];
        }
    } @catch (NSException *exception) {
        [self onErrorWithMethodName:@"onResume" withException:exception];
    }
}

- (void) onErrorWithMethodName:(NSString*)methodName withException:(NSException*)e {
    NSString* err = [NSString stringWithFormat:@"CDVAccelerometer - %@ ERROR: %@ - %@", methodName, e.name, e.reason];
    NSLog(@"%@", err);

    if (callbackId) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:err];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }
}

@end
