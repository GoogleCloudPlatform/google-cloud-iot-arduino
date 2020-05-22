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
#include "esp32-mqtt.h"

unsigned long lastMillis = millis();

void setup() {
  Serial.begin(115200);
  setupCloudIoT();
}

void loop() {
    mqtt->loop();
    delay(10);  // <- fixes some issues with WiFi stability

    // This is where the problem is when mqtt calls mqttConnect
    if (!mqttClient->connected()) {
      connect();
    }

    if (millis() - lastMillis > 60000) {
      lastMillis = millis();
      //publishTelemetry(mqttClient, "/sensors", getDefaultSensor());
      pollDelegate();
    }
}
