/******************************************************************************
 * Copyright 2019 Google
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
#ifndef __CLOUDIOTCORE_MQTT_H__
#define __CLOUDIOTCORE_MQTT_H__
#include <Arduino.h>
#include "CloudIoTCore.h"
#include "CloudIoTCoreDevice.h"
#include <Client.h>
#include <MQTTClient.h>

class CloudIoTCoreMqtt {
  private:
    int __backoff__ = 1000; // current backoff, milliseconds
    int __factor__ = 2.5f;
    int __minbackoff__ = 1000; // minimum backoff, ms
    int __max_backoff__ = 60000; // maximum backoff, ms
    int __jitter__ = 500; // max random jitter, ms
    unsigned long iss = 0;
    boolean logConnect = true;
    boolean useLts = false;
    String jwt;

    MQTTClient *mqttClient;
    Client *netClient;
    CloudIoTCoreDevice *device;

  public:
    CloudIoTCoreMqtt(MQTTClient *mqttClient, Client *netClient, CloudIoTCoreDevice *device);

    void startMQTT();
    void publishTelemetry(String data);
    void publishTelemetry(const char* data, int length);
    void publishTelemetry(String subtopic, String data);
    void publishTelemetry(String subtopic, const char* data, int length);
    void publishState(String data);
    void publishState(const char* data, int length);
    void onConnect();
    void setLogConnect(boolean enabled);
    void setUseLts(boolean enabled);
    void logError();
    void logReturnCode();
    void mqttConnect();
};
#endif // __CLOUDIOTCORE_MQTT_H__
