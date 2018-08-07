/*****************************************************************************
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
#include <CloudIoTCore.h>
#include <WiFiClientSecure.h>
#include <rBase64.h>
#include <time.h>
#include "SSD1306.h"
#include "backoff.h"

#include "ciotc_config.h"
String jwt;

//#define NETDEBUG  // Uncomment to enable network debugging

// Clout IoT configuration that you don't need to change
const char* host = CLOUD_IOT_CORE_HTTP_HOST;
const int httpsPort = CLOUD_IOT_CORE_HTTP_PORT;
WiFiClientSecure client;
CloudIoTCoreDevice device(project_id, location, registry_id, device_id,
                          private_key_str);

// SSD1306 display configuration
// #define DISPLAY // ENABLE ssd1306
#ifdef DISPLAY
SSD1306* display;  // Wemos is (0x3c, 4, 5), feather is on SDA/SCL
#endif

#ifndef LED_BUILTIN
#define LED_BUILTIN 16
#endif

// Button / Potentiometer configuration
int sensorPin = 12;  // select the input pin for the potentiometer
int buttonPin = 16;

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

void show_text(String top, String mid, String bot) {
  #ifdef DISPLAY
  display->clear();
  display->setTextAlignment(TEXT_ALIGN_LEFT);
  display->setFont(ArialMT_Plain_24);
  display->drawString(0, 0, top);
  display->setFont(ArialMT_Plain_16);
  display->drawString(0, 26, mid);
  display->setFont(ArialMT_Plain_10);
  display->drawString(0, 44, bot);
  display->display();
  #endif
}
void show_text(String val) { show_text(val, val, val); }

String getDefaultSensor() {
  return  "Wifi: " + String(WiFi.RSSI()) + "db";
}

// Start helper functions
void buttonPoll() {
  // read the value from the sensor:
  int sensorValue = analogRead(sensorPin);
  show_text("Input", String(digitalRead(buttonPin)), String(sensorValue));
  delay(100);
}

// IoT functions
void getConfig() {
  getJwt();

  // TODO: Move to library
  String header =
      String("GET ") + device.getLastConfigPath().c_str() + String(" HTTP/1.1");
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

void sendState(String data) {
  client.stop();
  delay(50);
  if (!client.connect(host, httpsPort)) {
    Serial.println("Connection failed!");
  } else {
    getJwt();

    rbase64.encode(data);
    String postdata =
        String("{\"state\": {\"binary_data\": \"") + rbase64.result() + 
        String("\"}}");

    // TODO(class): Move to common helper
    String header = String("POST  ") + device.getSendStatePath() +
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
}


// Arduino functions
void setup() {
  Serial.begin(115200);

  #ifdef DISPLAY
  display = new SSD1306(0x3c, 5, 4);
  display->init();
  display->flipScreenVertically();
  display->setFont(ArialMT_Plain_10);
  #endif

  delay(150);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  show_text("Wifi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print(".");
  }
  Serial.println();

  show_text("Time");
  configTime(0, 0, "time.google.com", "time.nist.gov");
  Serial.println("Waiting on time sync...");
  while (time(nullptr) < 1510644967) {
    delay(10);
  }

  // FIXME: Avoid MITM, validate the server.
  client.setCACert(root_cert);
  // client.setCertificate(test_client_key); // for client verification
  // client.setPrivateKey(test_client_cert); // for client verification

  Serial.println("Connecting to : " + String(host));
  delay(100);
  pinMode(LED_BUILTIN, OUTPUT);

  Serial.println("Getting JWT: ");
  Serial.println(getJwt());

  Serial.println("Getting Config / Sending Telem: ");
  getConfig();
  sendState(String("Device:") + String(device_id) +
      String(">connected"));
}

void loop() {
  delay(10000);
  //backoff();
  getConfig();
  sendState(getDefaultSensor());
  // buttonPoll();
}
