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
#ifdef ESP32 // Prevent compilation on Genuino for now
#include "CloudIoTCoreMQTTClient.h"
#include <time.h>

CONFIG_CALLBACK_SIGNATURE = NULL;

void callback(char *topic, uint8_t *payload, unsigned int length) {
  #ifdef CIOTC_DEBUG
  Serial.println(String("Message received on ") + String(topic));
  #endif
  if (configCallback != NULL) {
    configCallback(payload, length);
  }
}

CloudIoTCoreMQTTClient::CloudIoTCoreMQTTClient(CloudIoTCoreDevice *_device,
    WiFiClientSecure *_client, PubSubClient *_mqttClient) {
  this->device = _device;
  this->client = _client;
  this->mqttClient = _mqttClient;
  this->mqttClient->setClient(*(this->client));
  this->mqttClient->setStream(buffer);
}

CloudIoTCoreMQTTClient::CloudIoTCoreMQTTClient(CloudIoTCoreDevice *_device) {
  this->device = _device;
  this->client = new WiFiClientSecure();
  this->mqttClient = new PubSubClient();
  this->mqttClient->setClient(*(this->client));
  this->mqttClient->setStream(buffer);
}

CloudIoTCoreMQTTClient::CloudIoTCoreMQTTClient(const char *project_id,
                                               const char *location,
                                               const char *registry_id,
                                               const char *device_id,
                                               const char *private_key) {
  this->device = new CloudIoTCoreDevice(
      project_id, location, registry_id, device_id, private_key);
  this->client = new WiFiClientSecure();
  this->mqttClient = new PubSubClient();
  this->mqttClient->setClient(*(this->client));
  this->mqttClient->setStream(buffer);
}

void CloudIoTCoreMQTTClient::connect() {
  mqttClient->setServer(GOOGLE_APIS_MQTT_HOST, GOOGLE_APIS_MQTT_PORT);
  mqttClient->setCallback(callback);
  this->mqttClient->setStream(buffer);
}

#ifndef ESP8266
void CloudIoTCoreMQTTClient::connectSecure(const char *root_cert) {
  client->setCACert(root_cert);
  this->connect();
}
#endif

void CloudIoTCoreMQTTClient::setJwtExpSecs(int jwt_in_secs) {
  this->jwt_exp_secs = jwt_in_secs;
}

String CloudIoTCoreMQTTClient::getJWT() {
  // Refresh credential if it's expired.
  if (this->mqtt_iss == 0 || ((time(nullptr) - this->mqtt_iss) > this->jwt_exp_secs)) {
    this->mqtt_iss = time(nullptr);
    jwt = device->createJWT(this->mqtt_iss, this->jwt_exp_secs);
  }
  return jwt;
}

void CloudIoTCoreMQTTClient::mqttConnect() {
  /* Loop until reconnected */
  while (!client->connected()) {
    if(debugLog)
      Serial.println("MQTT connecting ...");
    String pass = this->getJWT();

    const char *user = "unused";
    String clientId = device->getClientId();

    if (debugLog) {
      Serial.println(clientId.c_str());
      Serial.println(pass.c_str());
    }

    if (mqttClient->connect(clientId.c_str(), user, pass.c_str())) {
      if (debugLog)
        Serial.println("connected");
      backOffCount = 0;
      if (configCallback != NULL) {
        String configTopic = device->getConfigTopic();
        if (debugLog)
          Serial.println(configTopic.c_str());
        mqttClient->setCallback(callback);
        mqttClient->setStream(buffer);
        mqttClient->subscribe(configTopic.c_str(), 0);
      }
    } else {
      Serial.print("failed, status code =");
      Serial.print(mqttClient->state());

      backOffCount++;
      int currDelay = (backOffCount * backOffCount * minBackoff) +
          random(minJitter,maxJitter);
      if (currDelay > maxBackoff) {
        currDelay = maxBackoff;
      }
      if (debugLog)
        Serial.printf("Waiting: %ld\n", currDelay);
      delay(currDelay);

      // If you don't set the server, does not reconnect
      mqttClient->setServer(GOOGLE_APIS_MQTT_HOST, GOOGLE_APIS_MQTT_PORT);
    }
  }
}

bool CloudIoTCoreMQTTClient::connected() {
  return this->mqttClient->connected();
}

void CloudIoTCoreMQTTClient::loop() {
  if (!this->connected()) {
    this->mqttConnect();
  }

  this->mqttClient->loop();
  delay(10);
}

void CloudIoTCoreMQTTClient::debugEnable(bool isEnable) {
    this->debugLog = isEnable;
}

void CloudIoTCoreMQTTClient::publishTelemetry(String binaryData) {
  this->publishTelemetry(binaryData.c_str());
}

void CloudIoTCoreMQTTClient::publishTelemetry(const char *binaryData) {
  String topic = device->getEventsTopic();
  mqttClient->publish(topic.c_str(), binaryData);
}

void CloudIoTCoreMQTTClient::publishState(String binaryData) {
  this->publishState(binaryData.c_str());
}

void CloudIoTCoreMQTTClient::publishState(const char *binaryData) {
  String topic = device->getStateTopic();
  mqttClient->publish(topic.c_str(), binaryData);
}

void CloudIoTCoreMQTTClient::setConfigCallback(
    CONFIG_CALLBACK_SIGNATURE_PARAM) {
  configCallback = configCallbackParam;
}
#endif
