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
// This file contains static methods for API requests using Wifi

#ifndef __ESP8266_WIFI_H__
#define __ESP8266_WIFI_H__
#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include "FS.h"
#include <time.h>
#include <rBase64.h>
#include <CloudIoTCore.h>
#include "backoff.h"

#include "ciotc_config.h" // Wifi configuration here

// Clout IoT configuration that you don't need to change
const char* host = CLOUD_IOT_CORE_HTTP_HOST;
const int httpsPort = CLOUD_IOT_CORE_HTTP_PORT;
CloudIoTCoreDevice *device;

unsigned int priv_key[8];
unsigned long iss = 0;
String jwt;
boolean wasErr;
WiFiClientSecure client;

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

  // Set CA cert on wifi client
  // If using a static (binary) cert:
  // client.setCACert_P(ca_crt, ca_crt_len);

  // Set CA cert from SPIFFS
  if (!SPIFFS.begin()) {
    Serial.println("Failed to mount file system");
    return;
  }
  File ca = SPIFFS.open("/ca.crt", "r"); //replace ca.crt eith your uploaded file name
  if (!ca) {
    Serial.println("Failed to open ca file");
  } else {
    Serial.println("Success to open ca file");
  }

  if(client.loadCertificate(ca)) {
    Serial.println("loaded");
  } else {
    Serial.println("not loaded");
  }
}


// IoT functions
void getConfig() {
  // TODO(class): Move to library
  String header =
      String("GET ") + device->getLastConfigPath().c_str() + String(" HTTP/1.1");
  String authstring = "authorization: Bearer " + String(jwt.c_str());

  if (!client.connect(host, httpsPort)) {
    Serial.println("connection failed");
    return;
  }

  // Connect via https.
  client.println(header.c_str());
  client.println(authstring.c_str());
  client.println("host: cloudiotdevice.googleapis.com");
  client.println("method: get");
  client.println("cache-control: no-cache");
  client.println();

  while (client.connected()) {
    String line = client.readStringUntil('\n');
    if (line == "\r") {
      Serial.println("headers received");
      break;
    }
  }
  while (client.available()) {
    String line = client.readStringUntil('\n');
    if (line.indexOf("binaryData") > 0) {
      String val = line.substring(line.indexOf(": ") + 3, line.indexOf("\","));
      Serial.println(val);
      if (val == "MQ==") {
        Serial.println("LED ON");
        digitalWrite(LED_BUILTIN, HIGH);
      } else {
        Serial.println("LED OFF");
        digitalWrite(LED_BUILTIN, LOW);
      }
      resetBackoff();
    }
  }
  client.stop();
}

void sendTelemetry(String data) {
  if (!client.connect(host, httpsPort)) {
    Serial.println("connection failed");
    return;
  }

  rbase64.encode(data);
  String postdata =
      String("{\"binary_data\": \"") + rbase64.result() + String("\"}");

  // TODO(class): Move to common helper
  String header = String("POST  ") + device->getSendTelemetryPath().c_str() +
                  String(" HTTP/1.1");
  String authstring = "authorization: Bearer " + String(jwt.c_str());

  Serial.println("Sending telemetry");

  client.println(header.c_str());
  client.println("host: cloudiotdevice.googleapis.com");
  client.println("method: post");
  client.println("cache-control: no-cache");
  client.println(authstring.c_str());
  client.println("content-type: application/json");
  client.print("content-length:");
  client.println(postdata.length());
  client.println();
  client.println(postdata);
  client.println();
  client.println();

  while (!client.available()) {
    delay(100);
    Serial.print('.');
  }
  Serial.println();

  while (client.connected()) {
    String line = client.readStringUntil('\n');
    if (line.startsWith("HTTP/1.1 200 OK")) {
      // reset backoff
      resetBackoff();
    }
    if (line == "\r") {
      break;
    }
  }
  while (client.available()) {
    String line = client.readStringUntil('\n');
  }
  Serial.println("Complete.");
  client.stop();
}

// Helper that just sends default sensor
void sendTelemetry() {
  sendTelemetry(getDefaultSensor());
}

#endif //__ESP8266_WIFI_H__
