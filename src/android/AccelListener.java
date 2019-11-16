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
package org.apache.cordova.devicemotion;

import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONObject;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

public class AccelListener extends CordovaPlugin implements SensorEventListener {
    // From the docs: The desired delay between two consecutive events in microseconds.
    // This is only a hint to the system. Events may be received faster or slower
    // than the specified rate. Usually events are received faster.
    // There are 1000000 microseconds in 1 second.
    private int delayMicroseconds = (int) 1000000; // This value is never used - gets overwritten by js default.

    // Keep track of whether we're running. Note that this is separate from whether
    // we're actually getting events, because if the app pauses, we temporarily unregister
    // from getting events in order to save battery life.
    private boolean isRunning = false;

    private CallbackContext jsCallbackContext;
    private SensorManager sensorManager;
    private Sensor mAccelSensor;

    public AccelListener() {

    }

    /**
     * Sets the context of the Command. This can then be used to do things like
     * get file paths associated with the Activity.
     *
     * @param cordova The context of the main Activity.
     * @param webView The associated CordovaWebView.
     */
    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        this.sensorManager = (SensorManager) cordova.getActivity().getSystemService(Context.SENSOR_SERVICE);
        this.mAccelSensor = this.sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
    }

    /**
     * Executes the request.
     *
     * @param action          The action to execute.
     * @param args            The exec() arguments.
     * @param callbackContext The callback context used when calling back into JavaScript.
     * @return                Whether the action was valid.
     */
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
        try {
            this.jsCallbackContext = callbackContext;
            if (action.equals("start")) {
                // We expect to be passed a delay in milliseconds, so convert to microseconds.
                this.delayMicroseconds = args.getInt(0) * 1000;

                // If already running, re-register the listener so that we use the new delay.
                if (this.isRunning) this.unregisterListener();

                boolean success = this.registerListener();
                if (success) {
                    this.isRunning = true;

                    // Send no result so that it saves the callback info, so that we can send updates later.
                    PluginResult result = new PluginResult(PluginResult.Status.NO_RESULT, "");
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                } else {
                    this.isRunning = false;
                    // registerListener sends a fail result on error, so nothing to do here.
                    // The error handling code is in registerListener, so that we send the same error
                    // in the onResume method if it errors.
                }
                return true;
            }
            else if (action.equals("stop")) {
                this.unregisterListener();
                this.isRunning = false;

                PluginResult result = new PluginResult(PluginResult.Status.OK, "");
                callbackContext.sendPluginResult(result);
                return true;
            }
            else {
                this.fail("Invalid action: " + action);
                return false;
            }
        } catch (Exception e) {
            e.printStackTrace();
            this.fail("execute: " + e.getMessage());
            return false;
        }
    }

    public void onDestroy() {
        try {
            if (this.isRunning) this.unregisterListener();
        } catch (Exception e) {
            e.printStackTrace();
            this.fail("onDestroy: " + e.getMessage());
        }
    }

    // On pause, we're supposed to unregister any sensors we're using. If we don't,
    // they'll continue to run while the app is closed and will drain battery life.
    @Override
    public void onPause(boolean multitasking) {
        try {
            if (this.isRunning) this.unregisterListener();
        } catch (Exception e) {
            e.printStackTrace();
            this.fail("onPause: " + e.getMessage());
        }
    }

    @Override
    public void onResume(boolean multitasking) {
        try {
            if (this.isRunning) this.registerListener();
        } catch (Exception e) {
            e.printStackTrace();
            this.fail("onResume: " + e.getMessage());
        }
    }

    // Called when the webview navigates or reloads.
    @Override
    public void onReset() {
        try {
            this.unregisterListener();
            this.isRunning = false;
        } catch (Exception e) {
            e.printStackTrace();
            this.fail("onReset: " + e.getMessage());
        }
    }

    //--------------------------------------------------------------------------
    // SENSOR METHODS
    //--------------------------------------------------------------------------
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // Ignore accuracy because even low accuracy data is better than none.
        // This shouldn't really be an issue for the accelerometer anyways.
    }

    public void onSensorChanged(SensorEvent event) {
        try {
            // Only look at accelerometer events
            if (event.sensor.getType() != Sensor.TYPE_ACCELEROMETER) return;

            JSONObject json = new JSONObject();
            json.put("x", event.values[0]);
            json.put("y", event.values[1]);
            json.put("z", event.values[2]);
            json.put("timestamp", System.currentTimeMillis());

            PluginResult result = new PluginResult(PluginResult.Status.OK, json);
            result.setKeepCallback(true);
            jsCallbackContext.sendPluginResult(result);
        } catch (Exception e) {
            e.printStackTrace();
            this.fail("onSensorChanged: " + e.getMessage());
        }
    }

    //--------------------------------------------------------------------------
    // LOCAL METHODS
    //--------------------------------------------------------------------------

    private boolean registerListener() {
        // This can be null if the device doesn't have an accelerometer.
        if (this.mAccelSensor != null) {
            // This returns false if there's an error
            boolean success = this.sensorManager.registerListener(this, this.mAccelSensor, delayMicroseconds);
            if (!success) this.fail("Device sensor returned an error.");
            return success;
        } else {
            this.fail("No accelerometer found.");
        }
        return false;
    }

    private void unregisterListener() {
        // This can be null if the device doesn't have an accelerometer.
        if (this.mAccelSensor != null) {
            this.sensorManager.unregisterListener(this);
        }
    }

    // Sends an error back to JS
    private void fail(String message) {
        Log.e("CordovaPluginDeviceMotion", message);
        if (jsCallbackContext != null) {
            PluginResult err = new PluginResult(PluginResult.Status.ERROR,
                    "CordovaPluginDeviceMotion error: " + message);
            err.setKeepCallback(true);
            jsCallbackContext.sendPluginResult(err);
        }
    }
}
