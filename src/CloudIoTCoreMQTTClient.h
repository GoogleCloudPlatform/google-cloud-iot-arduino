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

#ifndef CloudIoTCoreMQTTClient_h
#define CloudIoTCoreMQTTClient_h

#include <Arduino.h>
#include <WiFiClientSecure.h>
#define MQTT_MAX_PACKET_SIZE 512
#include <PubSubClient.h>

#include <CloudIoTCoreDevice.h>

#ifndef GOOGLE_APIS_MQTT_HOST
#define GOOGLE_APIS_MQTT_HOST "mqtt.googleapis.com"
#endif

#ifndef GOOGLE_APIS_MQTT_PORT
#define GOOGLE_APIS_MQTT_PORT 8883
#endif

#ifdef ESP8266
#include <functional>
#define CONFIG_CALLBACK_SIGNATURE \
  std::function<void(uint8_t *, unsigned int)> configCallback
#define CONFIG_CALLBACK_SIGNATURE_PARAM \
  std::function<void(uint8_t *, unsigned int)> configCallbackParam
#else
#define CONFIG_CALLBACK_SIGNATURE \
  void (*configCallback)(uint8_t *, unsigned int)
#define CONFIG_CALLBACK_SIGNATURE_PARAM \
  void (*configCallbackParam)(uint8_t *, unsigned int)
#endif

class CloudIoTCoreMQTTClient {
 private:
  CloudIoTCoreDevice device;
  WiFiClientSecure client;
  PubSubClient mqttClient;
  String jwt;

  void mqttConnect();
  String getJWT();

 public:
  CloudIoTCoreMQTTClient(CloudIoTCoreDevice &device);
  CloudIoTCoreMQTTClient(const char *project_id, const char *location,
                         const char *registry_id, const char *device_id,
                         const char *private_key);
  bool connected();
  void loop();

  void connect();
#ifndef ESP8266
  void connectSecure(const char *root_cert);
#endif
  /* MQTT methods */
  void publishTelemetry(String binaryData);
  void publishTelemetry(const char *binaryData);
  void publishState(String binaryData);
  void publishState(const char *binaryData);
  void setConfigCallback(CONFIG_CALLBACK_SIGNATURE);
};
#endif  // CloudIoTCoreMQTTClient_h
