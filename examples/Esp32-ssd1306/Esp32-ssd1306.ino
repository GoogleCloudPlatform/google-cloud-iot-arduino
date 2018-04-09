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
#include <WiFiClientSecure.h>
#include "jwt.h"
#include <time.h>
#include "SSD1306.h"
#include <rBase64.h>


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

unsigned int priv_key[8];

// Clout IoT configuration that you don't need to change
const char* host = "cloudiotdevice.googleapis.com";
const int httpsPort = 443;

SSD1306* display; // Display - Wemos is (0x3c, 4, 5), others on SDA/SCL
WiFiClientSecure* client; // For WiFi + TLS

// TLS configuration
// TODO: Use root certificate to verify tls connection rather than using a
// fingerprint.
// To get the fingerprint run
// openssl s_client -connect cloudiotdevice.googleapis.com:443 -cipher <cipher>
// Copy the certificate (all lines between and including ---BEGIN CERTIFICATE---
// and --END CERTIFICATE--) to a.cert. Then to get the fingerprint run
// openssl x509 -noout -fingerprint -sha1 -inform pem -in a.cert
// <cipher> is probably ECDHE-RSA-AES128-GCM-SHA256, but if that doesn't work
// try it with other ciphers obtained by sslscan cloudiotdevice.googleapis.com.
//const char* fingerprint =
//    "66:AD:B8:C9:93:C1:58:B0:B8:E5:21:B3:6B:B0:16:8C:58:B0:EF:51";
//
/*
const char* root_ca= \
     "-----BEGIN CERTIFICATE-----\n" \
     "IIE3zCCA8egAwIBAgIIdeZhOZwKoewwDQYJKoZIhvcNAQELBQAwVDELMAkGA1UE\n" \
     "hMCVVMxHjAcBgNVBAoTFUdvb2dsZSBUcnVzdCBTZXJ2aWNlczElMCMGA1UEAxMc\n" \
     "29vZ2xlIEludGVybmV0IEF1dGhvcml0eSBHMzAeFw0xODAyMjgyMzI0NTZaFw0x\n" \
     "DA1MjMyMjEwMDBaMGoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlh\n" \
     "RYwFAYDVQQHDA1Nb3VudGFpbiBWaWV3MRMwEQYDVQQKDApHb29nbGUgSW5jMRkw\n" \
     "wYDVQQDDBAqLmdvb2dsZWFwaXMuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A\n" \
     "IIBCgKCAQEAqniIhIgsIXVnJgE9QNf3NSbKrGkz92h1rfr/70jMZRrFwAgooDHa\n" \
     "/3HfKohm56EN5c0htGKeTCdP+YYoy0+fkI8T0xk80hnJw0r84pooX2qtYZFTS0T\n" \
     "lYkpLSL+B/aDWQJ/jKHEFLpFSzR1s1L2pCR6/cND8ETk4xEFSNRosUTC7+kw2KY\n" \
     "sCxOeaNHvOk1S5aWj1YSYNiNThPaplXvk/8G4t3ArncGNYXmIonwFm6DXGJ7DjN\n" \
     "1/fJmCk5y7AvIXRlT0uIMc/fPT61PXfGXU1vodfKwB300tCJpvWH5Ef88qqyQ9Q\n" \
     "OPim94IcpH0kJk3Fhd89mWpIi1qoZJozwIDAQABo4IBnTCCAZkwEwYDVR0lBAww\n" \
     "gYIKwYBBQUHAwEwdAYDVR0RBG0wa4IQKi5nb29nbGVhcGlzLmNvbYIVKi5jbGll\n" \
     "nRzNi5nb29nbGUuY29tghgqLmNsb3VkZW5kcG9pbnRzYXBpcy5jb22CFmNsb3Vk\n" \
     "W5kcG9pbnRzYXBpcy5jb22CDmdvb2dsZWFwaXMuY29tMGgGCCsGAQUFBwEBBFww\n" \
     "jAtBggrBgEFBQcwAoYhaHR0cDovL3BraS5nb29nL2dzcjIvR1RTR0lBRzMuY3J0\n" \
     "CkGCCsGAQUFBzABhh1odHRwOi8vb2NzcC5wa2kuZ29vZy9HVFNHSUFHMzAdBgNV\n" \
     "Q4EFgQU12VrPwdtSbezCPl5TXlVIgB1XDQwDAYDVR0TAQH/BAIwADAfBgNVHSME\n" \
     "DAWgBR3wrhQmmd2drEtwobQg6B+pn66SzAhBgNVHSAEGjAYMAwGCisGAQQB1nkC\n" \
     "QMwCAYGZ4EMAQICMDEGA1UdHwQqMCgwJqAkoCKGIGh0dHA6Ly9jcmwucGtpLmdv\n" \
     "2cvR1RTR0lBRzMuY3JsMA0GCSqGSIb3DQEBCwUAA4IBAQC+eZjfRbKDDcJ9vXKJ\n" \
     "cIwpU+mw3EsT435B7Z48O60Rm2GXfoGOP0cGeBBtqDnCIMQteL+m9SQsF0YKHih\n" \
     "lwwPm5+IDxzOWSV0GVoXNhmYjWdzcx3mfDJF1OnM7q2dInGnMIru3G2XGnmWaOs\n" \
     "2Rz3Tq+ZKjT7v6fyCPj8gdkNj2sf4he31VoKLdNKb0vlzV8qy1BcgcNBSfJtOZU\n" \
     "AWw9Bokd2APHe477wzEZOPNGuOGnmT1Piyj10rh9kNj7Qg3tdtOZK26FMa0NauI\n" \
     "9mIYTmphKGDqdXh00/DbxN6qTtz9AuaOToxJufrngE6fqFkhvBTQABUTIAdxufj\n" \
     "SrJ\n" \
     "-----END CERTIFICATE-----\n";*/


// Button / Potentiometer configuration
int sensorPin = 12;    // select the input pin for the potentiometer
int buttonPin = 16;
void buttonPoll() {
  // read the value from the sensor:
  int sensorValue = analogRead(sensorPin);
  Serial.println(digitalRead(buttonPin));
  Serial.println(sensorValue);
  show_text("Input", String(digitalRead(buttonPin)), String(sensorValue));
  delay(100);
}


String getJwt() {
  jwt = CreateJwt(project_id, time(nullptr), priv_key);
  return jwt;
}

// Fills the priv_key global variable with private key str which is of the form
// aa:bb:cc:dd:ee:...
void fill_priv_key(const char* priv_key_str) {
  priv_key[8] = 0;
  for (int i = 7; i >= 0; i--) {
    priv_key[i] = 0;
    for (int byte_num = 0; byte_num < 4; byte_num++) {
      priv_key[i] = (priv_key[i] << 8) + strtoul(priv_key_str, NULL, 16);
      priv_key_str += 3;
    }
  }
}

// Gets the google cloud iot http endpoint path.
String get_path(const char* project_id, const char* location,
                     const char* registry_id, const char* device_id) {
  return String("/v1/projects/") + project_id + "/locations/" + location +
         "/registries/" + registry_id + "/devices/" + device_id;
}


void show_text(String top, String mid, String bot){
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
void show_text(String val){
  show_text(val, val, val);
}


// IoT functions
void getConfig() {
  // TODO(class): Move to common section
  String header = String("GET ") +
      get_path(project_id, location, registry_id, device_id).c_str() +
      String("/config?local_version=0 HTTP/1.1");
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
      String val =
          line.substring(line.indexOf(": ") + 3,line.indexOf("\","));
      Serial.println(val);
      show_text("Config", rbase64.decode(val), val);
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
  String postdata = String("{\"binary_data\": \"") + rbase64.encode(data) + String("\"}");

  // TODO(class): Move to common helper
  String header = String("POST  ") +
      get_path(project_id, location, registry_id, device_id).c_str() +
      String(":publishEvent HTTP/1.1");
  String authstring = "authorization: Bearer " + String(jwt.c_str());

  Serial.println("Sending telemetry");

  client->println(header);
  client->println("host: cloudiotdevice.googleapis.com");
  client->println("method: post");
  client->println("cache-control: no-cache");
  client->println(authstring);
  client->println("content-type: application/json");
  client->print("content-length:"); client->println(postdata.length());
  client->println();
  client->println(postdata);
  client->println();
  client->println();

  while(!client->available()){
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

  // To get the private key run (where private-key.pem is the ec private key
  // used to create the certificate uploaded to google cloud iot):
  // openssl ec -in <private-key.pem> -noout -text
  // and copy priv: part.
  fill_priv_key(private_key_str);

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
  //client->setCACert(root_ca);
  //client.setCertificate(test_client_key); // for client verification
  //client.setPrivateKey(test_client_cert); // for client verification


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
    //sendTelemetry(String("Device:") + String(device_id) + String("> connected"));
  }
}

void loop() {
  delay(2000);
  getConfig();
  //buttonPoll();
}
