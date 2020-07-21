/******************************************************************************
 * Copyright 2020 Google
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
#if defined(ESP8266) or defined(ARDUINO_SAMD_MKR1000)
#define __SKIP_ESP32__
#endif

#if defined(ESP32)
#define __ESP32_MQTT__
#endif

#ifdef __SKIP_ESP32__

#include <Arduino.h>

void setup(){
  Serial.begin(115200);
}

void loop(){
  Serial.println("Hello World");
}

#endif

#ifdef __ESP32_MQTT__

#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

const String DeviceID = "my-esp-device";

#ifdef __cplusplus
extern "C" {
#endif
  uint8_t temprature_sens_read();
#ifdef __cplusplus
}
#endif


typedef struct __attribute__((packed)) SERIALBTMSG{
  String deviceid;
  String command;
  String payload;
  String type;
} btMsg;

btMsg incomingMsg;

String input;


// Processes commands sent by the Gateway device that correspond to messages from
// Google Cloud IoT Core. These messages can be 'configuration' for Cloud configuration
// messages, 'event' for requests to transmit telemetry events from the delegate device,
// and 'state' for when the gateway is requesting a state update from the delegate device.
void handleGatewayCommand() {
  if (incomingMsg.deviceid != DeviceID) {
    Serial.println("Connected to wrong Device;");
    return;
  }

  if (incomingMsg.command == "configuration") {
    // Write your code to handle configurations
    Serial.println(incomingMsg.payload);
  } else if (incomingMsg.command == "event") {
    if (incomingMsg.payload == "get temperature") {
      SerialBT.println("type:Command");
      SerialBT.println("data:" + String((temprature_sens_read() - 32) / 1.8) + " C;");
      Serial.println("Sent Data");
    } else {
      Serial.print("Couldn't Find payload");
    }
  } else if (incomingMsg.command == "state") {
    if (incomingMsg.payload == "get state") {
      SerialBT.println("type:Command");
      SerialBT.println("data: Device on;");
      Serial.println("Sent Data");
    }
  }
}


void parseInput(String in) {
  int x = 0;
  char strArray[in.length()+1];
  in.toCharArray(strArray,in.length()+1);
  char* pars = strtok (strArray,",");
  char* msgArray[3];
  while (pars != NULL) {
    msgArray[x] = pars;
    x++;
    pars = strtok (NULL,",");
  }

  incomingMsg.deviceid = String(msgArray[0]);
  incomingMsg.command = String(msgArray[1]);
  incomingMsg.payload = String(msgArray[2]);

  Serial.println(incomingMsg.payload);

  handleGatewayCommand();

  delay(1000);
}


void setup() {
  Serial.begin(115200);
  SerialBT.begin(DeviceID); //Bluetooth device name
  Serial.println("The device started, now you can pair it with bluetooth!");
}


void loop() {
  if (Serial.available()) {
    SerialBT.write(Serial.read());
  }
  if (SerialBT.available()) {
    input = (SerialBT.readStringUntil(';'));
    Serial.println(input);
    parseInput(input);
    ESP.restart();
  }
}
#endif