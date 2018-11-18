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

#define MQTT_MAX_PACKET_SIZE 512
#include <Arduino.h>
#include <LoopbackStream.h>
#include <PubSubClient.h>
#include <WiFiClientSecure.h>

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
  bool debugLog = false;
  bool skipReInit = false;
  CloudIoTCoreDevice *device;
  WiFiClientSecure *client;
  PubSubClient *mqttClient;
  String jwt;
  unsigned long mqttIss;
  LoopbackStream buffer;

  int backOffCount = 0;
  long minBackoff = 5000; // 1000 if you don't mind sending lots of data
  long maxBackoff = 60000;
  long minJitter = 50;
  long maxJitter = 1000;
  int jwtExpSeconds = 3600;
  const char* lastRootCert;
  int lastState = 0;

  int mqttConnect();
  String getJWT();

 public:
  CloudIoTCoreMQTTClient(CloudIoTCoreDevice *_device);
  CloudIoTCoreMQTTClient(CloudIoTCoreDevice *_device,
                         WiFiClientSecure *_client,
                         PubSubClient *_mqttClient);
  CloudIoTCoreMQTTClient(const char *project_id, const char *location,
                         const char *registry_id, const char *device_id,
                         const char *private_key);
  int backoff(bool shouldDelay);
  bool connected();
  void connect();
  #ifndef ESP8266
  void connectSecure(const char *root_cert);
  #endif
  void debugEnable(bool isEnable);
  /* MQTT methods */
  PubSubClient* getMqttClient();
  int loop();
  void publishTelemetry(String binaryData);
  void publishTelemetry(const char *binaryData);
  void publishState(String binaryData);
  void publishState(const char *binaryData);
  void setConfigCallback(CONFIG_CALLBACK_SIGNATURE);
  void setJwtExpSecs(int secs);
  void setSkipReinit(bool isSkip);
};
#endif  // CloudIoTCoreMQTTClient_h
