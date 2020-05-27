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
#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

static String staticBTDeviceID = "";
bool connected;

void setupSerialBT() {
  //SerialBT.setPin(pin);
  delay(5000);
  SerialBT.begin("my-esp32-gateway",true);
  //SerialBT.setPin(pin);
  Serial.println("The device started in master mode, make sure remote BT device is on!");

  // Note: connect(address) is fast (up to 10 secs max), connect(name) is slow (upto 30 secs max) as it needs
  // to resolve name to address first, but it allows to connect to different devices with the same name.
  // Set CoreDebugLevel to Info to view devices bluetooth address and device names.
  // connected = SerialBT.connect(address); // for cases where you want to use connect(name)
  connected = SerialBT.connect(staticBTDeviceID);

  if(connected) {
    Serial.println("Connected Succesfully!");
  } else {
    while(!SerialBT.connected(10000)) {
      Serial.println("Failed to connect. Make sure remote device is available and in range, then restart app.");
    }
  }
}

void disconnectSerialBT() {
  if(SerialBT.disconnect()) {
      Serial.println("Disconnected!");
  }
}

void forwardComand(String payload) {
    SerialBT.println(payload);
}
