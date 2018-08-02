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
#include "backoff.h"
#include "esp8266_wifi.h"
#include "cli.h"

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  setupWifi();
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  if (backoff()) {
    // Log signal strength
    sendTelemetry();
    delay(1000);
    getConfig();
  }

  delay(10); // too fast
  cliLoop();
}
