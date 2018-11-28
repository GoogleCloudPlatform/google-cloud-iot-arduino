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
#include <String.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

#include <rBase64.h>
#include <MQTT.h>

#include <CloudIoTCore.h>
#include "ciotc_config.h" // Update this file with your configuration

// Initialize the Genuino WiFi SSL client library / RTC
WiFiClientSecure *netClient;
MQTTClient *mqttClient;

// Clout IoT configuration that you don't need to change
CloudIoTCoreDevice *device;
unsigned long iss = 0;
String jwt;

///////////////////////////////
// Helpers specific to this board
///////////////////////////////
String getDefaultSensor() {
  return  "Wifi: " + String(WiFi.RSSI()) + "db";
}

String getJwt() {
  if (iss == 0 || time(nullptr) - iss > 3600) {  // TODO: exp in device
    iss = time(nullptr);
    Serial.println("Refreshing JWT");
    jwt = device->createJWT(iss);
  } else {
    Serial.println("Reusing still-valid JWT");
  }
  return jwt;
}

void setupWifi() {
  Serial.println("Starting wifi");

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
  }

  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("Waiting on time sync...");
  while (time(nullptr) < 1510644967) {
    delay(10);
  }
}


///////////////////////////////
// MQTT common functions
///////////////////////////////
void messageReceived(String &topic, String &payload) {
  Serial.println("incoming: " + topic + " - " + payload);
}

void startMQTT() {
  mqttClient->begin("mqtt.googleapis.com", 8883, *netClient);
  mqttClient->onMessage(messageReceived);
}

void publishTelemetry(String data) {
  mqttClient->publish(device->getEventsTopic(), data);
}

// Helper that just sends default sensor
void publishState(String data) {
  mqttClient->publish(device->getStateTopic(), data);
}

void mqttConnect() {
  Serial.print("\nconnecting...");
  while (!mqttClient->connect(device->getClientId().c_str(), "unused", getJwt().c_str(), false)) {
    Serial.println(mqttClient->lastError());
    Serial.println(mqttClient->returnCode());
    delay(1000);
  }
  Serial.println("\nconnected!");
  mqttClient->subscribe(device->getConfigTopic());
  mqttClient->subscribe(device->getCommandsTopic());
  publishState("connected");
}

///////////////////////////////
// Orchestrates various methods from preceeding code.
///////////////////////////////
void connect() {
  Serial.print("checking wifi...");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }
  mqttConnect();
}

void setupCloudIoT() {
  device = new CloudIoTCoreDevice(
      project_id, location, registry_id, device_id, 
      private_key_str);

  setupWifi();
  netClient = new WiFiClientSecure();
  mqttClient = new MQTTClient(512);
  startMQTT();
}
#endif //__ESP32_MQTT_H__
