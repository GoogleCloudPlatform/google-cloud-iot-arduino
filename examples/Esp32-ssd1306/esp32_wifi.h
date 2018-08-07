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
// TODO: abstract to interface / template?
#ifndef __ESP32_WIFI_H__
#define __ESP32_WIFI_H__
#include <WiFiClientSecure.h>
#include <time.h>
#include <rBase64.h>

#include <CloudIoTCore.h>
#include "backoff.h"
#include "ciotc_config.h" // Wifi configuration here

String jwt;
// Clout IoT configuration that you don't need to change
const char* host = CLOUD_IOT_CORE_HTTP_HOST;
const int httpsPort = CLOUD_IOT_CORE_HTTP_PORT;
CloudIoTCoreDevice device(project_id, location, registry_id, device_id,
                          private_key_str);

unsigned int priv_key[8];
boolean wasErr;
WiFiClientSecure client;

// Configuration / constants
const int maxTelemRetries = 25;
#define NETDEBUG  // Uncomment to enable network debugging


// Helpers for this board
String getDefaultSensor() {
  return  "Wifi: " + String(WiFi.RSSI()) + "db";
}

// Helpers for WiFi on this board
unsigned long iss = 0;
String getJwt() {
  if (iss == 0 || time(nullptr) - iss > 3600) {  // TODO: exp in device
    iss = time(nullptr);
    Serial.println("Refreshing JWT");
    jwt = device.createJWT(iss);
  } else {
    Serial.println("Reusing still-valid JWT");
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

  // FIXME: Avoid MITM, validate the server.
  client.setCACert(root_cert);
  // client.setCertificate(test_client_key); // for client verification
  // client.setPrivateKey(test_client_cert); // for client verification

  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("Waiting on time sync...");
  while (time(nullptr) < 1510644967) {
    delay(10);
  }

  // Device/Time OK, refresh JWT
  Serial.println(getJwt());
}


// IoT functions
void getConfig() {
  if (!client.connect(host, httpsPort)) {
    Serial.println("connection failed");
    return;
  }

  getJwt();

  // TODO: Move to library
  String header =
      String("GET ") + device.getLastConfigPath().c_str() + String(" HTTP/1.1");
  String authstring = "authorization: Bearer " + String(jwt.c_str());

  // Connect via https.
  client.println(header.c_str());
  client.println(authstring.c_str());
  client.println("host: cloudiotdevice.googleapis.com");
  client.println("method: get");
  client.println("cache-control: no-cache");
  client.println();

  while (client.connected()) {
    String line = client.readStringUntil('\n');
    #ifdef NETDEBUG
      Serial.println(line);
    #endif
    if (line == "\r") {
      Serial.println("headers received");
      break;
    }
  }
  while (client.available()) {
    String line = client.readStringUntil('\n');
    #ifdef NETDEBUG
      Serial.println(line);
    #endif
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

void setState(String data) {
  delay(50);
  if (!client.connect(host, httpsPort)) {
    Serial.println("Connection failed!");
    return;
  }
  getJwt();

  rbase64.encode(data);
  String postdata =
      String("{\"state\": {\"binary_data\": \"") + rbase64.result() +
      String("\"}}");

  // TODO(class): Move to common helper
  String header = String("POST  ") + device.getSetStatePath() +
    String(" HTTP/1.1");
  String authstring = "authorization: Bearer " + String(jwt.c_str());
  String extraHeaders =
    "host: cloudiotdevice.googleapis.com\n"
    "method: post\n"
    "cache-control: no-cache\n"
    "content-type: application/json\n"
    "Accept: application/json\n";

  Serial.println("Setting state");

  client.println(header);
  client.println(authstring);
  client.print(extraHeaders);

  client.print("content-length:");
  client.println(postdata.length());
  client.println();
  client.println(postdata);
  client.println();
  client.println();

  #ifdef NETDEBUG
  Serial.println(header);
  Serial.println(authstring);
  Serial.print(extraHeaders);
  Serial.print("content-length:");
  Serial.println(postdata.length());
  Serial.println();
  Serial.println(postdata);
  Serial.println();
  Serial.println();
  #endif

  int unavailCount = 0;
  while (!client.available() && unavailCount < 50) {
    delay(100);
    Serial.print('.');
    unavailCount++;
  }
  Serial.println();

  while (client.connected()) {
    String line = client.readStringUntil('\n');
    #ifdef NETDEBUG
    Serial.println(line);
    #endif
    if (line.startsWith("HTTP/1.1 200 OK")) {
      resetBackoff();
    }
    if (line == "\r") {
      break;
    }
  }
  while (client.available()) {
    String line = client.readStringUntil('\n');
    #ifdef NETDEBUG
    Serial.println(line);
    #endif
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
  String header = String("POST  ") + device.getSendTelemetryPath().c_str() +
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

  int retryCount = 0;
  while (!client.available() && retryCount < maxTelemRetries) {
    delay(100);
    Serial.print('.');
    retryCount++;
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

#endif //__ESP32_WIFI_
