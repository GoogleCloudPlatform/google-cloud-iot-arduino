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
#ifndef __ESP8266_MQTT_H__
#define __ESP8266_MQTT_H__
#include <ESP8266WiFi.h>
#include "FS.h"
#include <WiFiClientSecure.h>
#include <time.h>

#include <MQTT.h>

#include <CloudIoTCore.h>
#include "ciotc_config.h" // Wifi configuration here

unsigned long iss = 0;
String jwt;
boolean wasErr;
WiFiClientSecure *netClient;
MQTTClient *mqttClient;

boolean LOG_CONNECT = true;

///////////////////////////////
// Helpers specific to this board
///////////////////////////////
String getDefaultSensor() {
  return  "Wifi: " + String(WiFi.RSSI()) + "db";
}

String getJwt() {
  if (iss == 0 || time(nullptr) - iss > 3600) {  // TODO: exp in device
    // Disable software watchdog as these operations can take a while.
    ESP.wdtDisable();
    iss = time(nullptr);
    Serial.println("Refreshing JWT");
    jwt = device->createJWT(iss);
    ESP.wdtEnable(0);
  }
  return jwt;
}

void setupCert() {
  // Set CA cert on wifi client
  // If using a static (binary) cert:
  // netClient->setCACert_P(ca_crt, ca_crt_len);

  if (!SPIFFS.begin()) {
    Serial.println("Failed to mount file system");
    return;
  }

  // Set CA cert from SPIFFS
  File ca = SPIFFS.open("/ca.crt", "r"); //replace ca.crt eith your uploaded file name
  if (!ca) {
    Serial.println("Failed to open ca file");
  } else {
    Serial.println("Success to open ca file");
  }

  if(netClient->loadCertificate(ca)) {
    Serial.println("loaded");
  } else {
    Serial.println("not loaded");
  }
}

void setupWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
  }

  configTime(0, 0, ntp_primary, ntp_secondary);
  Serial.println("Waiting on time sync...");
  while (time(nullptr) < 1510644967) {
    delay(10);
  }
}

void connectWifi() {
  Serial.print("checking wifi..."); // TODO: Necessary?
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }
}

void messageReceived(String &topic, String &payload) {
  Serial.println("incoming: " + topic + " - " + payload);
}

///////////////////////////////
// Common MQTT
#include "mqtt_common.h"
///////////////////////////////

///////////////////////////////
// Orchestrates various methods from preceeding code.
///////////////////////////////
void connect() {
  mqttConnect(mqttClient, device);
}

// TODO: fix globals
void setupCloudIoT() {
  // Create the device
  device = new CloudIoTCoreDevice(
      project_id, location, registry_id, device_id,
      private_key_str);

  // ESP8266 WiFi setup
  netClient = new WiFiClientSecure();
  setupWifi();

  // Device/Time OK, ESP8266 refresh JWT
  Serial.println(getJwt());

  // ESP8266 WiFi secure initialization
  setupCert();

  mqttClient = new MQTTClient(512);
  mqttClient->setOptions(180, true, 1000); // keepAlive, cleanSession, timeout
  startMQTT(mqttClient); // Opens connection
}

#endif //__ESP8266_MQTT_H__
