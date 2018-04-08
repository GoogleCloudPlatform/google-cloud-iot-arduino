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

#include <WiFi101.h>
#include <WiFiSSLClient.h>

#include <String.h>

#include <rBase64.h>

#include <jwt.h>

// Wifi newtork details.
-const char* ssid = "SSID";
const char* password = "PASSWORD";

// Initialize the Genuino WiFi SSL client library / RTC
WiFiSSLClient* client;

// Cloud iot details.
const char* project_id = "PROJECT-ID";
const char* location = "us-central1";
const char* registry_id = "REGISTRY-ID";
const char* device_id = "DEVICE-ID";
// To get the private key run (where private-key.pem is the ec private key
// used to create the certificate uploaded to google cloud iot):
// openssl ec -in <private-key.pem> -noout -text
// and copy priv: part.
const char* private_key_str =
    "5a:2e:06:b5:c1:f2:9c:b3:77:b2:89:f5:29:29:93:"
    "07:fd:ed:22:0d:03:2b:a6:b1:b6:04:0b:d5:9b:49:"
    "7d:ca";

// TODO: Install root certificate to verify tls connection as described
//       in https://www.hackster.io/arichetta/add-ssl-certificates-to-mkr1000-93c89d
NN_DIGIT priv_key[8];

String getJwt() {
  // Disable software watchdog as these operations can take a while.
  String jwt = CreateJwt(project_id, WiFi.getTime(), priv_key);
  return jwt;
}

const char* host = "cloudiotdevice.googleapis.com";
const int httpsPort = 443;


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
  Serial.begin(9600);

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
  Serial.println("Connecting to mqtt.googleapis.com");
  client->connect(host, httpsPort);

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
      Serial.println(rbase64.decode(val));
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
