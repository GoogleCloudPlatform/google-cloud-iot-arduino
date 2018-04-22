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

#ifndef __ESP8266_WIFI_H__
#define __ESP8266_WIFI_H__
#include <ESP8266WiFi.h>
#include <WiFiClientSecure.h>
#include <time.h>
#include <rBase64.h>

#include "ciotc_config.h" // Wifi configuration here

// Clout IoT configuration that you don't need to change
const char* host = CLOUD_IOT_CORE_HTTP_HOST;
const int httpsPort = CLOUD_IOT_CORE_HTTP_PORT;
CloudIoTCoreDevice* device;

unsigned int priv_key[8];
unsigned long iss = 0;
String jwt;
boolean wasErr;

// Helpers for this board
String getDefaultSensor() {
  return  "Wifi: " + String(WiFi.RSSI()) + "db";
}

String getJwt() {
  if (iss == 0 || time(nullptr) - iss > 3600) {  // TODO: exp in device
    // Disable software watchdog as these operations can take a while.
    ESP.wdtDisable();
    Serial.println("Refrehsing JWT");
    iss = time(nullptr);
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

  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("Waiting on time sync...");
  while (time(nullptr) < 1510644967) {
    delay(10);
  }

  device = new CloudIoTCoreDevice(
    project_id, location, registry_id, device_id, private_key_str);

  // Device/Time OK, refresh JWT
  Serial.println(getJwt());
}

void doRequest(WiFiClientSecure* client, boolean isGet, String postData) {
  String header =
      String("POST  ") +
      device->getSendTelemetryPath().c_str() +
      String(" HTTP/1.1");
  String authstring = "authorization: Bearer " + String(getJwt().c_str());

  if (isGet) {
    header = String("GET ") + device->getLastConfigPath() + " HTTP/1.1";
    authstring = "authorization: Bearer " + getJwt();
  }

  String request = header + "\n" +
    "host: cloudiotdevice.googleapis.com\n" +
    "cache-control: no-cache\n" +
    authstring + "\n";
    
  if (isGet) {
    request = request + String("\n");
  } else {
    request = request + 
        "method: post\n" + 
        "content-type: application/json\n" + 
        "content-length:" + String(postData.length()) +
        "\n\n" + postData + "\n\n";
  }

  Serial.println("Connecting to " + String(host));
  client->connect(host, httpsPort);
  Serial.println("Verifying certificate");
  if (!client->verify(fingerprint, host)) {
    Serial.println(
        "Error: Certificate not verified! "
        "Perhaps the fingerprint is outdated.");
    // return;
  }

  // Connect via https.
  Serial.println(request);
  client->print(request);

  unsigned long timeout = millis();
  while (client->available() == 0) {
    if (millis() - timeout > 5000) {
      Serial.println(">>> Client Timeout !");
      delay(10000);
    }
  }
}

void sendTelemetry(String data) {
  String postdata =
      String("{\"binary_data\": \"") + rbase64.encode(data) + String("\"}");

  WiFiClientSecure client;
  doRequest(&client, false, postdata);
  
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
    Serial.println(line);
    if (line == "\r") {
      break;
    }
  }
  while (client.available()) {
    String line = client.readStringUntil('\n');
    Serial.println(line);
  }
  Serial.println("Complete.");
}
// Helper that just sends default sensor
void sendTelemetry() {
  sendTelemetry(getDefaultSensor());
}

void getConfig() {
  WiFiClientSecure client;
  doRequest(&client, true, "");

  // Handle headers here
  while (client.connected()) {
    String line = client.readStringUntil('\n');
    Serial.println(line);
    if (line == "\r") {
      Serial.println("--");
      break;
    }
  }
  // Handle respone body here
  while (client.available()) {
    String line = client.readStringUntil('\n');
    Serial.println(line);
    if (line.indexOf("binaryData") > 0) {
      // Reset backoff
      resetBackoff();
      String val =
          line.substring(line.indexOf(": ") + 3,line.indexOf("\","));
      if (val == "MQ==") {
        Serial.println("LED ON");
        digitalWrite(LED_BUILTIN, HIGH);
      } else {
        Serial.println("LED OFF");
        digitalWrite(LED_BUILTIN, LOW);
      }
    }
  }

  client.stop();
}

#endif //__ESP8266_WIFI_
