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
#include <WiFiClientSecure.h>
#include "FS.h"
#include <time.h>
#include <rBase64.h>
#include <CloudIoTCore.h>
#include <MQTT.h>

#include "ciotc_config.h" // Wifi configuration here

// Clout IoT configuration that you don't need to change
const char* host = CLOUD_IOT_CORE_HTTP_HOST;
const int httpsPort = CLOUD_IOT_CORE_HTTP_PORT;
CloudIoTCoreDevice *device;

unsigned int priv_key[8];
unsigned long iss = 0;
String jwt;
boolean wasErr;
WiFiClientSecure netClient;
MQTTClient mqttClient(512);

// Helpers for this board
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

void setupWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
  }

  device = new CloudIoTCoreDevice(project_id, location, registry_id, device_id,
                          private_key_str);

  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("Waiting on time sync...");
  while (time(nullptr) < 1510644967) {
    delay(10);
  }

  // Device/Time OK, refresh JWT
  Serial.println(getJwt());

  if (!SPIFFS.begin()) {
    Serial.println("Failed to mount file system");
    return;
  }

  // Set CA cert on wifi client
  // If using a static (binary) cert:
  // client.setCACert_P(ca_crt, ca_crt_len);

  // Set CA cert from SPIFFS
  File ca = SPIFFS.open("/ca.crt", "r"); //replace ca.crt eith your uploaded file name
  if (!ca) {
    Serial.println("Failed to open ca file");
  } else {
    Serial.println("Success to open ca file");
  }

  if(netClient.loadCertificate(ca)) {
    Serial.println("loaded");
  } else {
    Serial.println("not loaded");
  }
}

void messageReceived(String &topic, String &payload) {
  Serial.println("incoming: " + topic + " - " + payload);
}

void startMQTT() {
  mqttClient.begin("mqtt.googleapis.com", 8883, netClient);
  mqttClient.onMessage(messageReceived);
}

void publishTelemetry(String data) {
  mqttClient.publish(device->getEventsTopic(), data);
}

// Helper that just sends default sensor
void publishState(String data) {
  mqttClient.publish(device->getStateTopic(), data);
}

void connect() {
  Serial.print("checking wifi...");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }

  Serial.print("\nconnecting...");
  while (!mqttClient.connect(device->getClientId().c_str(), "unused", getJwt().c_str(), false)) {
    Serial.print(".");
    Serial.println(mqttClient.lastError());
    Serial.println(mqttClient.returnCode());
    delay(1000);
  }
  Serial.println("\nconnected!");
  mqttClient.subscribe(device->getConfigTopic());
  publishState("connected");
}
#endif //__ESP8266_MQTT_H__
