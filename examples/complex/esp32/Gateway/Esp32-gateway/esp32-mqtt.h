/******************************************************************************
 * Copyright 2018 Google
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
#ifndef __ESP32_MQTT_H__
#define __ESP32_MQTT_H__

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
String jwt,incoming_payload,incoming_command, input="NOT FOUND";

///////////////////////////////
// Helpers specific to this board
///////////////////////////////

void getDeviceID(String payload)
{
  char buf[payload.length() + 1];
  payload.toCharArray(buf, payload.length() + 1);
  char *pars = strtok(buf, ",");
  staticBTDeviceID = pars;
  pars = strtok(NULL, ",");
  incoming_command = pars;
  
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
  //WiFi.setSleep(false); // May help with disconnect? Seems to have been removed from WiFi
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  WiFi.begin(ssid, password);
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


void detachDelegate(String delegate_id) {

   
  //subscribe to delegate configuration
  mqttClient->unsubscribe("/devices/"+ delegate_id +"/config");

  //subscribe to delegate commands
  mqttClient->unsubscribe("/devices/"+ delegate_id +"/commands/#");
  
    //attach to delegate device
  String dat = "{}";
  mqttClient->publish(String("/devices/"+ delegate_id +"/detach").c_str(),dat.c_str(),false,1);
}

bool attachAndSubscribe(String delegate_id) {

  //attach to delegate device
  String dat = "{}";
  mqttClient->publish(String("/devices/"+ delegate_id +"/attach").c_str(),dat.c_str(),false,1);

  //subscribe to delegate configuration
  mqttClient->subscribe("/devices/"+ delegate_id +"/config",1);

  //subscribe to delegate commands
  mqttClient->subscribe("/devices/"+ delegate_id +"/commands/#",0);
}

// !!REPLACEME!!
// The MQTT callback function for commands and configuration updates
// Place your message handler code here.
void messageReceived(String &topic, String &payload) {
  int size = sizeof(delegate_device_id) / sizeof(delegate_device_id[0]);
  Serial.println("incoming: " + topic + " - " + payload);
  getDeviceID(payload);
  incoming_payload = payload;

  if(payload == "attach")
  {
    for(int i = 0; i < size;i++) {
      attachAndSubscribe(delegate_device_id[i]);
      mqttClient->loop();
    }
  }
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


bool publishDelegateTelemetry(String delegate_id,String data) {
  return mqttClient->publish(String("/devices/" + delegate_id + "/events").c_str(), String(data).c_str(), false, 1);
}

bool publishDelegateState(String delegate_id,String data) {
  return mqttClient->publish(String("/devices/"+ delegate_id +"/state").c_str(),String(data).c_str(),false,1);
}

String pollDelegate() {
  if (incoming_payload != "") {
    setupSerialBT();
    forwardComand(incoming_payload);
    incoming_payload = "";

    if (Serial.available()) {
      SerialBT.write(Serial.read());
    }

    while (!SerialBT.available()) {
      Serial.println(".");
      delay(500);
    }
    
    input = (SerialBT.readStringUntil(';'));

    if(incoming_command == "event") {
      publishDelegateTelemetry(staticBTDeviceID,input);
    }
    else if(incoming_command == "state") { 
      publishDelegateState(staticBTDeviceID,input);
    }

    Serial.println("Delegate Published");

    disconnectSerialBT();
  }
  else {
    Serial.println("Connect - No Incoming Commands ");
  }
  
  return input;
}

void connect() {
  connectWifi();
  mqtt->mqttConnect();
  delay(500); // <- fixes some issues with WiFi stability
}

void setupCloudIoT(){
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
  mqttClient->subscribe("/devices/"+String(device_id)+"/errors",1);
}
#endif //__ESP32_MQTT_H__
