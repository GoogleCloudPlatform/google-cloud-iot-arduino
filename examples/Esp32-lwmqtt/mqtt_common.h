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
#ifndef __MQTT_COMMON_H__
#define __MQTT_COMMON_H__
///////////////////////////////
// MQTT common functions
///////////////////////////////
void startMQTT(MQTTClient *mqttClient) {
  mqttClient->begin("mqtt.googleapis.com", 8883, *netClient);
  mqttClient->onMessage(messageReceived);
}

void publishTelemetry(MQTTClient *mqttClient, String data) {
  mqttClient->publish(device->getEventsTopic(), data);
}

void publishTelemetry(MQTTClient *mqttClient, String subtopic, String data) {
  mqttClient->publish(device->getEventsTopic() + subtopic, data);
}

// Helper that just sends default sensor
void publishState(MQTTClient *mqttClient, String data) {
  mqttClient->publish(device->getStateTopic(), data);
}

void onConnect(MQTTClient *mqttClient, CloudIoTCoreDevice *device) {
  if (LOG_CONNECT) {
    publishState(mqttClient, "connected");
    publishTelemetry(mqttClient, "/events", device->getDeviceId() + String("-connected"));
  }
}

void logError(MQTTClient *mqttClient) {
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
}

void logReturnCode(MQTTClient *mqttClient) {
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
}

// FIXME: Move to config?
int __backoff__ = 1000; // current backoff, milliseconds
int __factor__ = 2.5f;
int __minbackoff__ = 1000; // minimum backoff, ms
int __max_backoff__ = 60000; // maximum backoff, ms
int __jitter__ = 500; // max random jitter, ms
void mqttConnect(MQTTClient *mqttClient, CloudIoTCoreDevice *device) {
  Serial.print("\nconnecting...");
  bool keepgoing = true;
  while (keepgoing) {
    mqttClient->connect(device->getClientId().c_str(), "unused", getJwt().c_str(), false);

    if (mqttClient->lastError() != LWMQTT_SUCCESS){
      logError(mqttClient);
      logReturnCode(mqttClient);
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

  onConnect(mqttClient, device);
}
#endif // __MQTT_COMMON_H__
