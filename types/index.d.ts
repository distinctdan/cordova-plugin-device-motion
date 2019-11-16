// Type definitions for Apache Cordova Device Motion plugin
// Project: https://github.com/distinctdan/cordova-plugin-device-motion
// Definitions by: Microsoft Open Technologies Inc <http://msopentech.com>
// Definitions: https://github.com/DefinitelyTyped/DefinitelyTyped
//
// Copyright (c) Microsoft Open Technologies Inc
// Licensed under the MIT license.

interface Navigator {
    /**
     * This plugin provides access to the device's accelerometer. The accelerometer is a motion sensor
     * that detects the change (delta) in movement relative to the current device orientation,
     * in three dimensions along the x, y, and z axis.
     */
    accelerometer: Accelerometer;
}

/**
 * Contains Accelerometer data captured at a specific point in time. Acceleration values include
 * the effect of gravity (9.81 m/s^2), so that when a device lies flat and facing up, x, y, and z
 * values returned should be 0, 0, and 9.81.
 */
interface Acceleration {
    /** Amount of acceleration on the x-axis. (in m/s^2) */
    x: number;
    /** Amount of acceleration on the y-axis. (in m/s^2) */
    y: number;
    /** Amount of acceleration on the z-axis. (in m/s^2) */
    z: number;
    /** Creation timestamp in milliseconds. */
    timestamp: number;
}

interface AccelerometerOptions {
    /** How often to retrieve the Acceleration in milliseconds. (Default: 1000/30) */
    frequency?: number;
}

/**
 * This plugin provides access to the device's accelerometer. The accelerometer is a motion sensor
 * that detects the change (delta) in movement relative to the current device orientation,
 * in three dimensions along the x, y, and z axis.
 */
interface Accelerometer {
    x: number;
    y: number;
    z: number;
    timestamp: number;
    watchAcceleration: (
        successCallback?: (accel: Acceleration) => void,
        errorCallback?: (error?: any) => void,
        options?: AccelerometerOptions
    ) => (
            (unregisterSuccessCallback?: () => void,
             unregisterErrorCallback?: (error?: any) => void
        ) => void);
}

