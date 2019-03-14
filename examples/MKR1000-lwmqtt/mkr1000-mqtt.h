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
// This file contains static methods for API requests using Wifi / MQTT
#ifndef __MKR1000_MQTT_H__
#define __MKR1000_MQTT_H__
#include <WiFi101.h>
#include <WiFiSSLClient.h>

#include <MQTT.h>

#include <CloudIoTCore.h>
#include "ciotc_config.h" // Update this file with your configuration

// Initialize the Genuino WiFi SSL client library / RTC
WiFiSSLClient *netClient;
MQTTClient *mqttClient;

// Clout IoT configuration that you don't need to change
CloudIoTCoreDevice *device;
unsigned long iss = 0;
String jwt;

///////////////////////////////
// Helpers specific to this board
///////////////////////////////
String getDefaultSensor() {
  return  "Wifi: " + String(WiFi.RSSI()) + "db";
}

String getJwt() {
  if (iss == 0 || WiFi.getTime() - iss > 3600) {  // TODO: exp in device
    // Disable software watchdog as these operations can take a while.
    Serial.println("Refreshing JWT");
    iss = WiFi.getTime();
    jwt = device->createJWT(iss);
  }
  return jwt;
}

void setupWifi() {
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
}


///////////////////////////////
// MQTT common functions
///////////////////////////////
void messageReceived(String &topic, String &payload) {
  Serial.println("incoming: " + topic + " - " + payload);
}

void startMQTT() {
  mqttClient->begin("mqtt.googleapis.com", 8883, *netClient);
  mqttClient->onMessage(messageReceived);
}

void publishTelemetry(String data) {
  mqttClient->publish(device->getEventsTopic(), data);
}

// Helper that just sends default sensor
void publishState(String data) {
  mqttClient->publish(device->getStateTopic(), data);
}

// FIXME: Move to config?
int __backoff__ = 1000; // current backoff, milliseconds
int __factor__ = 2.5f;
int __minbackoff__ = 1000; // minimum backoff, ms
int __max_backoff__ = 60000; // maximum backoff, ms
int __jitter__ = 500; // max random jitter, ms
void mqttConnect() {
  Serial.print("\nconnecting...");
  bool keepgoing = true;
  while (keepgoing) {
    mqttClient->connect(device->getClientId().c_str(), "unused", getJwt().c_str(), false);

    if (mqttClient->lastError() != LWMQTT_SUCCESS){
      Serial.println(mqttClient->lastError());
      switch(mqttClient->lastError()) {
        case (LWMQTT_BUFFER_TOO_SHORT):
          Serial.println("LWMQTT_BUFFER_TOO_SHORT");
          break;
        case (LWMQTT_VARNUM_OVERFLOW):
          Serial.println("LWMQTT_VARNUM_OVERFLOW");
          break;
        case (LWMQTT_NETWORK_FAILED_CONNECT):
          Serial.println("LWMQTT_NETWORK_FAILED_CONNECT");
          break;
        case (LWMQTT_NETWORK_TIMEOUT):
          Serial.println("LWMQTT_NETWORK_TIMEOUT");
          break;
        case (LWMQTT_NETWORK_FAILED_READ):
          Serial.println("LWMQTT_NETWORK_FAILED_READ");
          break;
        case (LWMQTT_NETWORK_FAILED_WRITE):
          Serial.println("LWMQTT_NETWORK_FAILED_WRITE");
          break;
        case (LWMQTT_REMAINING_LENGTH_OVERFLOW):
          Serial.println("LWMQTT_REMAINING_LENGTH_OVERFLOW");
          break;
        case (LWMQTT_REMAINING_LENGTH_MISMATCH):
          Serial.println("LWMQTT_REMAINING_LENGTH_MISMATCH");
          break;
        case (LWMQTT_MISSING_OR_WRONG_PACKET):
          Serial.println("LWMQTT_MISSING_OR_WRONG_PACKET");
          break;
        case (LWMQTT_CONNECTION_DENIED):
          Serial.println("LWMQTT_CONNECTION_DENIED");
          break;
        case (LWMQTT_FAILED_SUBSCRIPTION):
          Serial.println("LWMQTT_FAILED_SUBSCRIPTION");
          break;
        case (LWMQTT_SUBACK_ARRAY_OVERFLOW):
          Serial.println("LWMQTT_SUBACK_ARRAY_OVERFLOW");
          break;
        case (LWMQTT_PONG_TIMEOUT):
          Serial.println("LWMQTT_PONG_TIMEOUT");
          break;
        default:
          Serial.println("This error code should never be reached.");
          break;
      }

      Serial.println(mqttClient->returnCode());
      switch(mqttClient->returnCode()) {
        case (LWMQTT_CONNECTION_ACCEPTED):
          Serial.println("OK");
          break;
        case (LWMQTT_UNACCEPTABLE_PROTOCOL):
          Serial.println("LWMQTT_UNACCEPTABLE_PROTOCOLL");
          break;
        case (LWMQTT_IDENTIFIER_REJECTED):
          Serial.println("LWMQTT_IDENTIFIER_REJECTED");
          break;
        case (LWMQTT_SERVER_UNAVAILABLE):
          Serial.println("LWMQTT_SERVER_UNAVAILABLE");
          break;
        case (LWMQTT_BAD_USERNAME_OR_PASSWORD):
          Serial.println("LWMQTT_BAD_USERNAME_OR_PASSWORD");
          iss = 0; // Force JWT regeneration
          break;
        case (LWMQTT_NOT_AUTHORIZED):
          Serial.println("LWMQTT_NOT_AUTHORIZED");
          iss = 0; // Force JWT regeneration
          break;
        case (LWMQTT_UNKNOWN_RETURN_CODE):
          Serial.println("LWMQTT_UNKNOWN_RETURN_CODE");
          break;
        default:
          Serial.println("This return code should never be reached.");
          break;
      }
      // See https://cloud.google.com/iot/docs/how-tos/exponential-backoff
      if (__backoff__ < __minbackoff__) {
        __backoff__ = __minbackoff__;
      }
      __backoff__ = (__backoff__ * __factor__) + random(__jitter__);
      if (__backoff__ > __max_backoff__) {
        __backoff__ = __max_backoff__;
      }

      // Clean up the client
      mqttClient->disconnect();
      Serial.println("Delaying " + String(__backoff__) + "ms");
      delay(__backoff__);
      keepgoing = true;
    } else {
      // We're now connected
      Serial.println("\nconnected!");
      keepgoing = false;
      __backoff__ = __minbackoff__;
    }
  }

  mqttClient->subscribe(device->getConfigTopic(), 1); // Set QoS to 1 (ack) for configuration messages
  mqttClient->subscribe(device->getCommandsTopic(), 0); // QoS 0 (no ack) for commands
  if (ex_num_topics > 0) { // Subscribe to the extra topics
    for (int i=0; i < ex_num_topics; i++) {
        mqttClient->subscribe(ex_topics[i], 0); // QoS 0 (no ack) for commands
    }
  }

  publishState("connected");
}

///////////////////////////////
// Orchestrates various methods from preceeding code.
///////////////////////////////
void connect() {
  Serial.print("checking wifi...");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }
  mqttConnect();
}

void setupCloudIoT() {
  device = new CloudIoTCoreDevice(
      project_id, location, registry_id, device_id,
      private_key_str);

  setupWifi();
  netClient = new WiFiSSLClient;

  mqttClient = new MQTTClient(512);
  mqttClient->setOptions(180, true, 1000); // keepAlive, cleanSession, timeout
  startMQTT();
}
#endif //__MKR1000_MQTT_H__
