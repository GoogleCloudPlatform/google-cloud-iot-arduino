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

#include "CloudIoTCoreMQTTClient.h"
#include <time.h>

CONFIG_CALLBACK_SIGNATURE = NULL;

void callback(char *topic, uint8_t *payload, unsigned int length) {
  Serial.print("Message received: ");
  Serial.println(topic);

  if (configCallback != NULL) {
    configCallback(payload, length);
  }
}

CloudIoTCoreMQTTClient::CloudIoTCoreMQTTClient(CloudIoTCoreDevice &device) {
  this->device = device;
  this->mqttClient.setClient(this->client);
}

CloudIoTCoreMQTTClient::CloudIoTCoreMQTTClient(const char *project_id,
                                               const char *location,
                                               const char *registry_id,
                                               const char *device_id,
                                               const char *private_key) {
  this->device = CloudIoTCoreDevice(project_id, location, registry_id,
                                    device_id, private_key);
  this->mqttClient.setClient(this->client);
}

void CloudIoTCoreMQTTClient::connect() {
  mqttClient.setServer(GOOGLE_APIS_MQTT_HOST, GOOGLE_APIS_MQTT_PORT);
  mqttClient.setCallback(callback);
}

#ifndef ESP8266
void CloudIoTCoreMQTTClient::connectSecure(const char *root_cert) {
  client.setCACert(root_cert);
  this->connect();
}
#endif

String CloudIoTCoreMQTTClient::getJWT() {
  if (iss == 0 || time(nullptr) - iss > 3600) {
    iss = time(nullptr);
    jwt = device.createJWT(iss);
  }
  return jwt;
}

void CloudIoTCoreMQTTClient::mqttConnect() {
  /* Loop until reconnected */
  while (!client.connected()) {
    Serial.println("MQTT connecting ...");
    String pass = this->getJWT();
    Serial.println(pass.c_str());
    const char *user = "unused";
    String clientId = device.getClientId();
    Serial.println(clientId.c_str());
    if (mqttClient.connect(clientId.c_str(), user, pass.c_str())) {
      Serial.println("connected");
      if (configCallback != NULL) {
        String configTopic = device.getConfigTopic();
        Serial.println(configTopic.c_str());
        mqttClient.setCallback(callback);
        mqttClient.subscribe(configTopic.c_str(), 0);
      }
    } else {
      Serial.print("failed, status code =");
      Serial.print(mqttClient.state());
      Serial.println(" try again in 5 seconds");
      /* Wait 5 seconds before retrying */
      delay(5000);
    }
  }
}

bool CloudIoTCoreMQTTClient::connected() {
  return this->mqttClient.connected();
}

void CloudIoTCoreMQTTClient::loop() {
  if (!this->connected()) {
    this->mqttConnect();
  }

  this->mqttClient.loop();
  delay(10);
}

void CloudIoTCoreMQTTClient::publishTelemetry(String binaryData) {
  this->publishTelemetry(binaryData.c_str());
}

void CloudIoTCoreMQTTClient::publishTelemetry(const char *binaryData) {
  String topic = device.getEventsTopic();
  mqttClient.publish(topic.c_str(), binaryData);
}

void CloudIoTCoreMQTTClient::publishState(String binaryData) {
  this->publishState(binaryData.c_str());
}

void CloudIoTCoreMQTTClient::publishState(const char *binaryData) {
  String topic = device.getStateTopic();
  mqttClient.publish(topic.c_str(), binaryData);
}

void CloudIoTCoreMQTTClient::setConfigCallback(
    CONFIG_CALLBACK_SIGNATURE_PARAM) {
  configCallback = configCallbackParam;
}
