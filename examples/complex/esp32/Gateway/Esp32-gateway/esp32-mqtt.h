/******************************************************************************
 * Copyright 2020 Google
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************/
// This file contains static methods for API requests using Wifi / MQTT

#include <Client.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

#include <MQTT.h>

#include <CloudIoTCore.h>
#include <CloudIoTCoreMqtt.h>
#include "ciotc_config.h" // Update this file with your configuration
#include "connect-serial.h"

// Initialize WiFi and MQTT for this board
Client *netClient;
CloudIoTCoreDevice *device;
CloudIoTCoreMqtt *mqtt;
MQTTClient *mqttClient;
unsigned long iss = 0;
String jwt, incomingPayload, incomingCommand, input="NOT FOUND";

///////////////////////////////
// Helpers specific to this board
///////////////////////////////

void getDeviceID(String payload) {
  char buf[payload.length() + 1];
  payload.toCharArray(buf, payload.length() + 1);
  char *pars = strtok(buf, ",");
  staticBTDeviceID = pars;
  pars = strtok(NULL, ",");
  incomingCommand = pars;
}


String getJwt() {
  iss = time(nullptr);
  Serial.println("Refreshing JWT");
  jwt = device->createJWT(iss, jwt_exp_secs);
  Serial.println(jwt);
  return jwt;
}


void setupWifi() {
  Serial.println("Starting wifi");
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  WiFi.begin(ssid,password);
  Serial.println("Connecting");

  while (WiFi.status() != WL_CONNECTED) {
    Serial.println(".");
    delay(500);
  }

  configTime(0, 0, ntp_primary, ntp_secondary);
  Serial.println("Waiting on time sync...");
  while (time(nullptr) < 1510644967) {
    delay(10);
  }
}


void connectWifi() {
  Serial.print("checking wifi...");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }
}


void detachDelegate(String delegateId) {
  //subscribe to delegate configuration
  mqttClient->unsubscribe("/devices/"+ delegateId +"/config");

  //subscribe to delegate commands
  mqttClient->unsubscribe("/devices/"+ delegateId +"/commands/#");

    //attach to delegate device
  String dat = "{}";
  mqttClient->publish(
      String("/devices/"+ delegateId +"/detach").c_str(),
      dat.c_str(), false, 1);
}


void attachAndSubscribe(String delegateId) {
  //attach to delegate device
  String dat = "{}";
  mqttClient->publish(String("/devices/"+ delegateId +"/attach").c_str(),
      dat.c_str(), false, 1);

  //subscribe to delegate configuration
  mqttClient->subscribe("/devices/"+ delegateId +"/config", 1);

  //subscribe to delegate commands
  mqttClient->subscribe("/devices/"+ delegateId +"/commands/#", 0);
}


// The MQTT callback function for commands and configuration updates
// This is were incoming command from the gateway gets saved,
// to forward to the delegate device
void messageReceived(String &topic, String &payload) {
  int size = sizeof(delegate_device_id) / sizeof(delegate_device_id[0]);
  Serial.println("incoming: " + topic + " - " + payload);
  getDeviceID(payload);
  incomingPayload = payload;

  if(payload == "detach") {
    for(int i = 0; i < size;i++) {
      detachDelegate(delegate_device_id[i]);
      mqttClient->loop();
    }
  }
}
///////////////////////////////

///////////////////////////////
// Orchestrates various methods from preceeding code.
///////////////////////////////


bool publishTelemetry(String data) {
  return mqtt->publishTelemetry(data);
}


bool publishTelemetry(const char* data, int length) {
  return mqtt->publishTelemetry(data, length);
}


bool publishTelemetry(String subfolder, String data) {
  return mqtt->publishTelemetry(subfolder, data);
}


bool publishTelemetry(String subfolder, const char* data, int length) {
  return mqtt->publishTelemetry(subfolder, data, length);
}


bool publishDelegateTelemetry(String delegateId,String data) {
  return mqttClient->publish(
      String("/devices/"+ delegateId +"/events").c_str(),
      String(data).c_str(), false, 1);
}


bool publishDelegateState(String delegateId,String data) {
  return mqttClient->publish(
      String("/devices/"+ delegateId +"/state").c_str(),
      String(data).c_str(), false, 1);
}


// Polls sensor data from the delegate devices and forwards Cloud-to-device messages.
// Message from the delegate device is semicolon terminated and takes the format:
//    <deviceid>,<command>,<payload>;
String pollDelegate() {
  if (incomingPayload != "") {
    setupSerialBT();
    forwardComand(incomingPayload);
    incomingPayload = "";

    if (Serial.available()) {
      SerialBT.write(Serial.read());
    }

    while (!SerialBT.available()) {
      Serial.println(".");
      delay(500);
    }

    input = (SerialBT.readStringUntil(';'));

    if(incomingCommand == "event") {
      publishDelegateTelemetry(staticBTDeviceID,input);
    } else if(incomingCommand == "state") {
      publishDelegateState(staticBTDeviceID,input);
    }

    Serial.println("Delegate Published");

    disconnectSerialBT();
  } else {
    Serial.println("Connect - No Incoming Commands ");
  }
  return input;
}


void connect() {
  connectWifi();
  mqtt->mqttConnect();

  int size = sizeof(delegate_device_id) / sizeof(delegate_device_id[0]);

  for(int i = 0; i < size; i++) {
    attachAndSubscribe(delegate_device_id[i]);
    mqttClient->loop();
  }

  delay(500); // <- fixes some issues with WiFi stability
}


void setupCloudIoT() {
  device = new CloudIoTCoreDevice(
      project_id, location, registry_id, device_id,
      private_key_str);

  setupWifi();
  netClient = new WiFiClientSecure();
  mqttClient = new MQTTClient(360);
  mqttClient->setOptions(180, true, 10000); // keepAlive, cleanSession, timeout
  mqtt = new CloudIoTCoreMqtt(mqttClient, netClient, device);
  mqtt->setUseLts(true);
  mqtt->startMQTT();
  mqttClient->subscribe("/devices/"+ String(device_id) +"/errors",0);
}
