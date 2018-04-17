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

// Wifi newtork details.
const char* ssid = "YOURSSID";
const char* password = "YOURPASS";

// Cloud IoT configuration that you must change
const char* project_id = "your-projectid-1234";
const char* location = "us-central1";
const char* registry_id = "your-registry-id";
const char* device_id = "your-device-id";
String jwt;

// From openssl ec -in certificate.pem -noout --text
const char* private_key_str =
    "e0:14:62:40:1c:d5:0b:78:cb:5e:7b:f9:ba:a7:08:"
    "0d:fa:41:34:48:69:56:e5:4a:d0:a3:a5:a4:c8:4b:"
    "ca:69";

const char* root_cert =
    "-----BEGIN CERTIFICATE-----\n"
    "MIIEXDCCA0SgAwIBAgINAeOpMBz8cgY4P5pTHTANBgkqhkiG9w0BAQsFADBMMSAw\n"
    "HgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMjETMBEGA1UEChMKR2xvYmFs\n"
    "U2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xNzA2MTUwMDAwNDJaFw0yMTEy\n"
    "MTUwMDAwNDJaMFQxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVHb29nbGUgVHJ1c3Qg\n"
    "U2VydmljZXMxJTAjBgNVBAMTHEdvb2dsZSBJbnRlcm5ldCBBdXRob3JpdHkgRzMw\n"
    "ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDKUkvqHv/OJGuo2nIYaNVW\n"
    "XQ5IWi01CXZaz6TIHLGp/lOJ+600/4hbn7vn6AAB3DVzdQOts7G5pH0rJnnOFUAK\n"
    "71G4nzKMfHCGUksW/mona+Y2emJQ2N+aicwJKetPKRSIgAuPOB6Aahh8Hb2XO3h9\n"
    "RUk2T0HNouB2VzxoMXlkyW7XUR5mw6JkLHnA52XDVoRTWkNty5oCINLvGmnRsJ1z\n"
    "ouAqYGVQMc/7sy+/EYhALrVJEA8KbtyX+r8snwU5C1hUrwaW6MWOARa8qBpNQcWT\n"
    "kaIeoYvy/sGIJEmjR0vFEwHdp1cSaWIr6/4g72n7OqXwfinu7ZYW97EfoOSQJeAz\n"
    "AgMBAAGjggEzMIIBLzAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0lBBYwFAYIKwYBBQUH\n"
    "AwEGCCsGAQUFBwMCMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFHfCuFCa\n"
    "Z3Z2sS3ChtCDoH6mfrpLMB8GA1UdIwQYMBaAFJviB1dnHB7AagbeWbSaLd/cGYYu\n"
    "MDUGCCsGAQUFBwEBBCkwJzAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AucGtpLmdv\n"
    "b2cvZ3NyMjAyBgNVHR8EKzApMCegJaAjhiFodHRwOi8vY3JsLnBraS5nb29nL2dz\n"
    "cjIvZ3NyMi5jcmwwPwYDVR0gBDgwNjA0BgZngQwBAgIwKjAoBggrBgEFBQcCARYc\n"
    "aHR0cHM6Ly9wa2kuZ29vZy9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsFAAOCAQEA\n"
    "HLeJluRT7bvs26gyAZ8so81trUISd7O45skDUmAge1cnxhG1P2cNmSxbWsoiCt2e\n"
    "ux9LSD+PAj2LIYRFHW31/6xoic1k4tbWXkDCjir37xTTNqRAMPUyFRWSdvt+nlPq\n"
    "wnb8Oa2I/maSJukcxDjNSfpDh/Bd1lZNgdd/8cLdsE3+wypufJ9uXO1iQpnh9zbu\n"
    "FIwsIONGl1p3A8CgxkqI/UAih3JaGOqcpcdaCIzkBaR9uYQ1X4k2Vg5APRLouzVy\n"
    "7a8IVk6wuy6pm+T7HT4LY8ibS5FEZlfAFLSW8NwsVz9SBK2Vqn1N0PIMn5xA6NZV\n"
    "c7o835DLAFshEWfC7TIe3g==\n"
    "-----END CERTIFICATE-----\n";

// Clout IoT configuration that you don't need to change
const char* host = CLOUD_IOT_CORE_HTTP_HOST;
const int httpsPort = CLOUD_IOT_CORE_HTTP_PORT;
WiFiClientSecure* client;
CloudIoTCoreDevice device(project_id, location, registry_id, device_id,
                          private_key_str);

String jwt;

// SSD1306 display configuration
SSD1306* display;  // Wemos is (0x3c, 4, 5), feather is on SDA/SCL

// Button / Potentiometer configuration
int sensorPin = 12;  // select the input pin for the potentiometer
int buttonPin = 16;

String getJwt() {
  jwt = device.createJWT(time(nullptr));
  return jwt;
}

void show_text(String top, String mid, String bot) {
  display->clear();
  display->setTextAlignment(TEXT_ALIGN_LEFT);
  display->setFont(ArialMT_Plain_24);
  display->drawString(0, 0, top);
  display->setFont(ArialMT_Plain_16);
  display->drawString(0, 26, mid);
  display->setFont(ArialMT_Plain_10);
  display->drawString(0, 44, bot);
  display->display();
}
void show_text(String val) { show_text(val, val, val); }

// Start helper functions
void buttonPoll() {
  // read the value from the sensor:
  int sensorValue = analogRead(sensorPin);
  Serial.println(digitalRead(buttonPin));
  Serial.println(sensorValue);
  show_text("Input", String(digitalRead(buttonPin)), String(sensorValue));
  delay(100);
}

// IoT functions
void getConfig() {
  // TODO(class): Move to common section
  String header =
      String("GET ") + device.getLastConfigPath().c_str() + String(" HTTP/1.1");
  String authstring = "authorization: Bearer " + String(jwt.c_str());

  // Connect via https.
  client->println(header);
  client->println("host: cloudiotdevice.googleapis.com");
  client->println("method: get");
  client->println("cache-control: no-cache");
  client->println(authstring);
  client->println();

  while (client->connected()) {
    String line = client->readStringUntil('\n');
    if (line == "\r") {
      Serial.println("headers received");
      break;
    }
  }
  while (client->available()) {
    String line = client->readStringUntil('\n');
    Serial.println(line);
    if (line.indexOf("binaryData") > 0) {
      String val = line.substring(line.indexOf(": ") + 3, line.indexOf("\","));
      Serial.println(val);
      size_t len = rbase64.decode(val);
      show_text("Config", String(len), val);
      if (val == "MQ==") {
        Serial.println("LED ON");
        digitalWrite(LED_BUILTIN, HIGH);
      } else {
        Serial.println("LED OFF");
        digitalWrite(LED_BUILTIN, LOW);
      }
    }
  }
}

void sendTelemetry(String data) {
  String postdata =
      String("{\"binary_data\": \"") + rbase64.encode(data) + String("\"}");

  // TODO(class): Move to common helper
  String header = String("POST  ") + device.getSendTelemetryPath().c_str() +
                  String(" HTTP/1.1");
  String authstring = "authorization: Bearer " + String(jwt.c_str());

  Serial.println("Sending telemetry");

  client->println(header);
  client->println("host: cloudiotdevice.googleapis.com");
  client->println("method: post");
  client->println("cache-control: no-cache");
  client->println(authstring);
  client->println("content-type: application/json");
  client->print("content-length:");
  client->println(postdata.length());
  client->println();
  client->println(postdata);
  client->println();
  client->println();

  while (!client->available()) {
    delay(100);
    Serial.print('.');
  }
  Serial.println();

  while (client->connected()) {
    String line = client->readStringUntil('\n');
    if (line == "\r") {
      break;
    }
  }
  while (client->available()) {
    String line = client->readStringUntil('\n');
  }
  Serial.println("Complete.");
}

// Arduino functions
void setup() {
  Serial.begin(115200);

  display = new SSD1306(0x3c, 5, 4);

  display->init();
  display->flipScreenVertically();
  display->setFont(ArialMT_Plain_10);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  show_text("Wifi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
  }

  client = new WiFiClientSecure();

  show_text("Time");
  configTime(0, 0, "time.google.com", "time.nist.gov");
  Serial.println("Waiting on time sync...");
  while (time(nullptr) < 1510644967) {
    delay(10);
  }

  // FIXME: Avoid MITM, validate the server.
  client->setCACert(root_cert);
  // client.setCertificate(test_client_key); // for client verification
  // client.setPrivateKey(test_client_cert); // for client verification

  Serial.println("Connecting to : " + String(host));
  delay(100);
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.println("...");
  if (!client->connect(host, httpsPort)) {
    Serial.println("Connection failed!");
  } else {
    Serial.println("Getting JWT: ");
    getJwt();
    getConfig();
    // sendTelemetry(String("Device:") + String(device_id) + String(">
    // connected"));
  }
}

void loop() {
  delay(2000);
  getConfig();
  // buttonPoll();
}
