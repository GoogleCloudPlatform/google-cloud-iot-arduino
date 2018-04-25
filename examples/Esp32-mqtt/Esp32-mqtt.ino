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
#include <Arduino.h>
#include <CloudIoTCore.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <time.h>
#include <ciotc_config.h> // Configure with your settings

#define MQTT_MAX_PACKET_SIZE 512
#include <PubSubClient.h>

const char *host = "mqtt.googleapis.com";
const int httpsPort = 8883;

WiFiClientSecure client;
PubSubClient mqttClient(client);
CloudIoTCoreDevice device(project_id, location, registry_id, device_id,
                          private_key_str);
String pwd;
String jwt;

long lastMsg = 0;
char msg[20];
int counter = 0;

const int LED_PIN = 5;

String getJwt() {
  jwt = device.createJWT(time(nullptr));
  return jwt;
}

String get_config_topic(const char *device_id) {
  return String("/devices/") + device_id + "/config";
}

String get_events_topic(const char *device_id) {
  return String("/devices/") + device_id + "/events";
}

String get_state_topic(const char *device_id) {
  return String("/devices/") + device_id + "/state";
}

void callback(char *topic, uint8_t *payload, unsigned int length) {
  Serial.print("Message received: ");
  Serial.println(topic);

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

void mqtt_connect() {
  /* Loop until reconnected */
  while (!client.connected()) {
    Serial.println("MQTT connecting ...");
    String pass = getJwt();
    Serial.println(pass.c_str());
    const char *user = "unused";
    String clientId = device.getClientId();
    Serial.println(clientId.c_str());
    if (mqttClient.connect(clientId.c_str(), user, pass.c_str())) {
      Serial.println("connected");
      String configTopic = get_config_topic(device_id);
      Serial.println(configTopic.c_str());
      mqttClient.setCallback(callback);
      mqttClient.subscribe(configTopic.c_str(), 0);
    } else {
      Serial.print("failed, status code =");
      Serial.print(mqttClient.state());
      Serial.println(" try again in 5 seconds");
      /* Wait 5 seconds before retrying */
      delay(5000);
    }
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
  client.setCACert(root_cert);
  mqttClient.setServer(host, httpsPort);
  mqttClient.setCallback(callback);
}

void loop() {
  if (!mqttClient.connected()) {
    mqtt_connect();
  }

  mqttClient.loop();

  long now = millis();
  if (now - lastMsg > 3000) {
    lastMsg = now;
    if (counter < 1000) {
      counter++;
      snprintf(msg, 20, "%d", counter);
      /* publish the message */
      String eventsTopic = get_events_topic(device_id);
      mqttClient.publish(eventsTopic.c_str(), msg);
    } else {
      counter = 0;
    }
  }

  // I had some issues on the PubSubClient without some delay
  delay(10);
}
