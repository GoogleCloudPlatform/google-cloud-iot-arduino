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
// This file contains CLI for controlling when connected via UART.
#ifndef __CLI_H__
#define __CLI_H__

// Basic loop for reading commands to stop the device, etc...
boolean stopped = false;
void cliLoop() {
  String msg = "";
  while (Serial.available() || stopped) {
    if (Serial.available()) {
      msg = Serial.readStringUntil('\n');
    }
    
    if (msg == "stop") {
      Serial.println("STOPPING!!!");
      stopped = true;
    }

    if (msg == "go") {
      Serial.println("Resume");
      stopped = false;
    }

    if (msg == "sensor") {
      String data = "Wifi: " + String(WiFi.RSSI()) + " db";
      Serial.println(data);
    }

    if (stopped) {
        delay(10000);
        Serial.print(".");
    }
  }
}

#endif
