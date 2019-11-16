/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

/**
 * This class provides access to device accelerometer data.
 * @constructor
 */
var exec = require("cordova/exec");

// Array of listeners; used to keep track of when we should call start and stop.
var listeners = [];

var accelerometer = {
    x: 0,
    y: 0,
    z: 0,
    timestamp: -1,

    /**
     * Asynchronously acquires the acceleration repeatedly at a given interval.
     *
     * @param {Function} successCallback    The function to call each time the acceleration data is available
     * @param {Function} errorCallback      The function to call when there is an error getting the acceleration data. (OPTIONAL)
     * @param {AccelerationOptions} options The options for getting the accelerometer data such as timeout. (OPTIONAL)
     * @return {Function} unregister        A function that can be called to unregister the success callback from getting called (OPTIONAL)
     */
    watchAcceleration: function (successCallback, errorCallback, options) {
        var frequency = (options && options.frequency && typeof options.frequency == 'number') ? options.frequency : 1000/30;
    
        var newListener = {
            success: successCallback,
            error: errorCallback,
        };
        listeners.push(newListener);
        
        exec(function (accel) {
            accelerometer.x = accel.x;
            accelerometer.y = accel.y;
            accelerometer.z = accel.z;
            accelerometer.timestamp = accel.timestamp;
            
            for (var i = 0; i < listeners.length; i++) {
                if (listeners[i].success) {
                    listeners[i].success(accel);
                }
            }
        }, function (error) {
            for (var i = 0; i < listeners.length; i++) {
                if (listeners[i].error) {
                    listeners[i].error(error);
                }
            }
        }, "Accelerometer", "start", [frequency]);
        
        // Unregister function - If the last callback is unregistered, call the native "stop" method.
        // The caller can optionally pass success/error callbacks to get any native errors from calling "stop".
        let hasRunCancel = false;
        return function(unregisterSuccessCallback, unregisterErrorCallback) {
            if (hasRunCancel) {
                console.log('Accelerometer: unregister was called twice, doing nothing.');
                return;
            }
            hasRunCancel = true;
            
            var i = listeners.indexOf(newListener);
            if (i !== -1) {
                listeners.splice(i, 1);
            }
            
            if (listeners.length === 0) {
                exec(unregisterSuccessCallback, unregisterErrorCallback, "Accelerometer", "stop", []);
            } else {
                unregisterSuccessCallback();
            }
        };
    },
};
module.exports = accelerometer;

