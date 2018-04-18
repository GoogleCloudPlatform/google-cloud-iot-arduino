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

#include <ESP8266WiFi.h>
#include <String.h>
#include <WiFiClientSecure.h>
#include <jwt.h>
#include <time.h>

#include "ciotc_config.h" // Configure with your settings

unsigned int priv_key[8];

String getJwt() {
  // Disable software watchdog as these operations can take a while.
  ESP.wdtDisable();
  String jwt = CreateJwt(project_id, time(nullptr), priv_key);
  ESP.wdtEnable(0);
  return jwt;
}

const char* host = "cloudiotdevice.googleapis.com";
const int httpsPort = 443;

WiFiClientSecure* client;
String pwd;

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

void setup() {
  fill_priv_key(private_key_str);

  // put your setup code here, to run once:
  Serial.begin(115200);

  pinMode(LED_BUILTIN, OUTPUT);

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

  client = new WiFiClientSecure;
  Serial.println("Connecting to mqtt.googleapis.com");
  client->connect(host, httpsPort);
  Serial.println("Verifying certificate");
  if (!client->verify(fingerprint, host)) {
    Serial.println(
        "Error: Certificate not verified! "
        "Perhaps the fingerprint is outdated.");
    // return;
  } else {
    Serial.println("Fingerprint verified!");
  }

  Serial.println("Getting jwt.");
  pwd = getJwt();
  Serial.println(pwd.c_str());

  // Connect via https.
  String handshake =
      "GET " + get_path(project_id, location, registry_id, device_id) +
      "/config?local_version=1 HTTP/1.1\n"
      "Host: cloudiotdevice.googleapis.com\n"
      "cache-control: no-cache\n"
      "authorization: Bearer " +
      pwd +
      "\n"
      "\n";
  Serial.println("Sending: '");
  Serial.print(handshake.c_str());
  Serial.println("'");
  client->write((const uint8_t*)handshake.c_str(), (int)handshake.length());
  client->flush();

  int tries = 500;
  while (!client->available() && (tries-- > 0)) delay(10);

  if (client->available()) {
    char rdBuf[1000];
    int bread = client->read((uint8_t*)rdBuf, 1000);
    Serial.println("Response: ");
    Serial.write(rdBuf, bread);
  } else {
    Serial.println("No response, something went wrong.");
  }
}


void getConfig() {
  // TODO(class): Move to helper function, e.g. buildHeader(method, jwt)...
  String header = String("GET ") +
      get_path(project_id, location, registry_id, device_id).c_str() +
      String("/config?local_version=0 HTTP/1.1");
  String authstring = "authorization: Bearer " + String(getJwt().c_str());

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

void loop() {
  delay(2000);
  getConfig();
}
