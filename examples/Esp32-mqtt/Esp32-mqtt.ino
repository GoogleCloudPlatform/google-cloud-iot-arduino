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
#define ESP32
#include <Arduino.h>
#include <CloudIoTCore.h>
#include <CloudIoTCoreMQTTClient.h>
#include <WiFi.h>
#include "ciotc_config.h"  // Configure with your settings
#include <time.h>

CloudIoTCoreDevice device(project_id, location, registry_id, device_id,
                          private_key_str);
CloudIoTCoreMQTTClient client(device);

long lastMsg = 0;
char msg[20];
int counter = 0;

const int LED_PIN = 5;

void callback(uint8_t *payload, unsigned int length) {
  Serial.print("payload: ");
  char val[length];
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
    val[i] = (char)payload[i];
  }
  Serial.println();

  // int ret = rbase64.decode(val);
  int ret = 0;
  if (ret == 0) {
    // we got '1' -> on
    if (val[0] == '1') {
      Serial.println("High");
      digitalWrite(LED_PIN, HIGH);
    } else {
      // we got '0' -> on
      Serial.println("Low");
      digitalWrite(LED_PIN, LOW);
    }
  } else {
    Serial.println("Error decoding");
  }
}

void setup() {
  pinMode(LED_PIN, OUTPUT);

  // put your setup code here, to run once:
  Serial.begin(115200);

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

  Serial.println("Connecting to mqtt.googleapis.com");
  client.connectSecure(root_cert);
  client.setConfigCallback(callback);
}

void loop() {
  client.loop();

  long now = millis();
  if (now - lastMsg > 3000) {
    lastMsg = now;
    if (counter < 1000) {
      counter++;
      snprintf(msg, 20, "%d", counter);
      Serial.println("Publish message");
      /* publish the message */
      client.publishTelemetry(msg);
    } else {
      counter = 0;
    }
  }
}
