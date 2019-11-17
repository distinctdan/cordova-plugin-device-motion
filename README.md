---
title: Device Motion
description: Access accelerometer data.
---
<!---
# license: Licensed to the Apache Software Foundation (ASF) under one
#         or more contributor license agreements.  See the NOTICE file
#         distributed with this work for additional information
#         regarding copyright ownership.  The ASF licenses this file
#         to you under the Apache License, Version 2.0 (the
#         "License"); you may not use this file except in compliance
#         with the License.  You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#         Unless required by applicable law or agreed to in writing,
#         software distributed under the License is distributed on an
#         "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#         KIND, either express or implied.  See the License for the
#         specific language governing permissions and limitations
#         under the License.
-->

# cordova-plugin-device-motion

----

## Installation
    cordova plugin add https://github.com/distinctdan/cordova-plugin-device-motion.git
Tested platforms: Android 7+, iOS 11+
    
## Discussion
This plugin uses the accelerometer to provide motion events from native code. Ideally, this plugin wouldn't be necessary because of the DeviceMotion api's, but iOS 13 has at least 1 deal-breaker bug at the time of writing (2019-11-16). iOS 13 currently requires you to prompt the user to grant motion rights every time your app runs, which is a deal-breaker for me; so I revived this plugin to support my tilt-controlled game.

Current Recommendation: Use the [W3C Device Motion and Orientation API](https://www.w3.org/TR/orientation-event/#introduction) api for all browsers that support it, and fall back on this plugin for iOS 13:

```
if (window.device.platform === 'iOS'
    && window.DeviceMotionEvent
    && DeviceMotionEvent.requestPermission
) {
    navigator.accelerometer.watchAcceleration(this.onAccelerometerEvent, ...);
} else {
    window.addEventListener('devicemotion', this.onDeviceMotion, true);
}
```


Changes from the existing device-motion plugin:
- Updated API to be simpler
- Made frequency actually set the native motion update frequency instead of always being a constant rate.
- JS callbacks are called immediately when we get a motion event, instead of waiting until a setInterval runs. This reduces perceived input lag.
- Automatically unregisters/reregisters native motion handlers when the app pauses/resumes
- Dropped support for all platforms except for Android/iOS
    
## Example Usage

Registering for motion events:
```js
// Register for motion events at 30fps
const unregister = navigator.accelerometer.watchAcceleration((accel) => {
    console.log('Got motion:', accel.x, accel.y, accel.x);
}, (error) => {
    console.log('ERROR: ', error);
}, {frequency: 1000/30});

// Check current motion values
const someCalculation = navigator.accelerometer.x + navigator.accelerometer.z;

// Unregister for motion events when you don't need them anymore.
unregister(() => {
    console.log('Unregister success');
}, (error) => {
    console.log('Unregister error: ', error);
});
```

### onPause/onResume
This plugin automatically unregister/reregisters the native motion stuff when the app pauses or resumes in order to save battery life. There's no need for your app to do anything. 

## API

### navigator.accelerometer.watchAcceleration(success?, error?, options) => unregister
- `success?(accel: Acceleration)` -- Optional success callback that will be passed an Acceleration object that looks like
```js
{
    // Acceleration values are in m/s^2
    x: number,
    y: number,
    z: number,
    timestamp: number,
}
```
- `error?(err: any)` -- Optional error callback that is passed an error from the native side.
- `options` -- Only 1 option is supported, frequency: `{frequency: 1000/30}`. The frequency is passed in milliseconds, and controls the expected interval between motion updates. NOTE - the actual callback rate can be significantly higher on Android by 50% to 100% because the OS doesn't guarantee a perfectly regular interval, so it fires events faster to make sure your expected frequency is met.
- returns an unregister function: `unregister(success?, error?)` -- Call this function when your app is done listening for motion events. The unregister function can also be passed success/error callbacks to be notified of any native errors that may occur.

> PERFORMANCE WARNING: This plugin has a significant performance impact because it calls into js many times per second. If your app is a performance intensive game, you probably don't want to set your `frequency` to more than 30fps. To debug performance issues, you can use chrome's Remote Devices panel to attach to the webview and run a profiling session.

### navigator.accelerometer properties
- `x` - X acceleration value in m/s^2
- `y` - Y acceleration value in m/s^2
- `z` - Z acceleration value in m/s^2
- `timestamp` - The timestamp of the last motion event.
