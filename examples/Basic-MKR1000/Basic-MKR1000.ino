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
#include <String.h>
#include <WiFi101.h>
#include <WiFiSSLClient.h>

#include <rBase64.h>
#include <CloudIoTCore.h>
#include "ciotc_config.h" // Update this file with your configuration

// Initialize the Genuino WiFi SSL client library / RTC
WiFiSSLClient* client;

// TODO(you): Install root certificate to verify tls connection as described
// in https://www.hackster.io/arichetta/add-ssl-certificates-to-mkr1000-93c89d
NN_DIGIT priv_key[9];

// Clout IoT configuration that you don't need to change
const char* host = CLOUD_IOT_CORE_HTTP_HOST;
const int httpsPort = CLOUD_IOT_CORE_HTTP_PORT;
CloudIoTCoreDevice device(project_id, location, registry_id, device_id,
                          private_key_str);

unsigned long iss = 0;
String jwt;

String getJwt() {
  if (iss == 0 || WiFi.getTime() - iss > 3600) {  // TODO: exp in device
    // Disable software watchdog as these operations can take a while.
    Serial.println("Refreshing JWT");
    iss = WiFi.getTime();
    jwt = device.createJWT(iss);
  }
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


void setup() {
  fill_priv_key(private_key_str);

  // put your setup code here, to run once:
  Serial.begin(9600);
  delay(500);
  Serial.println("Starting wifi");

  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
  }

  Serial.println("Waiting on time sync...");
  while (WiFi.getTime() < 1510644967) {
    delay(10);
  }

  client = new WiFiSSLClient;
  Serial.println("Connecting to: " + String(host));
  client->connect(host, httpsPort);

  Serial.println("Getting jwt.");
  Serial.println(getJwt());

  // Update configuration.
  getConfig();
}


void getConfig() {
  getJwt();

  // Connect via https.
  String handshake =
      String("GET ") + device.getLastConfigPath().c_str() + String(" HTTP/1.1\n") +
      "authorization: Bearer " + String(jwt.c_str()) + "\n"+
      "Host: cloudiotdevice.googleapis.com\n" +
      "cache-control: no-cache\n" + "\n\n";

  client->write((const uint8_t*)handshake.c_str(), (int)handshake.length());
  client->flush();

  int tries = 500;
  while (!client->available() && (tries-- > 0)) delay(10);
  while (client->connected()) {
    String line = client->readStringUntil('\n');
    if (line == "\r") {
      //Serial.println("headers received");
      break;
    }
  }
  while (client->available()) {
    String line = client->readStringUntil('\n');
    // DEBUG
    //Serial.println(line);
    if (line.indexOf("binaryData") > 0) {
      String val =
          line.substring(line.indexOf(": ") + 3,line.indexOf("\","));

      Serial.println(val);
      rbase64.decode(val);
      Serial.println(rbase64.result());

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
