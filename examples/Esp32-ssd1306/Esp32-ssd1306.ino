/*****************************************************************************
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
#include "esp32_wifi.h"

#include "SSD1306.h"

// SSD1306 display configuration
// #define DISPLAY // ENABLE ssd1306
#ifdef DISPLAY
SSD1306* display;  // Wemos is (0x3c, 4, 5), feather is on SDA/SCL
#endif

#ifndef LED_BUILTIN
#define LED_BUILTIN 16
#endif

// Button / Potentiometer configuration
int sensorPin = 12;  // select the input pin for the potentiometer
int buttonPin = 16;

void show_text(String top, String mid, String bot) {
  #ifdef DISPLAY
  display->clear();
  display->setTextAlignment(TEXT_ALIGN_LEFT);
  display->setFont(ArialMT_Plain_24);
  display->drawString(0, 0, top);
  display->setFont(ArialMT_Plain_16);
  display->drawString(0, 26, mid);
  display->setFont(ArialMT_Plain_10);
  display->drawString(0, 44, bot);
  display->display();
  #endif
}
void show_text(String val) { show_text(val, val, val); }

// Arduino functions
void setup() {
  Serial.begin(115200);

  #ifdef DISPLAY
  display = new SSD1306(0x3c, 5, 4);
  display->init();
  display->flipScreenVertically();
  display->setFont(ArialMT_Plain_10);
  #endif

  pinMode(LED_BUILTIN, OUTPUT);

  delay(150);

  show_text("Time");
  setupWifi();

  show_text("Initialized");
  Serial.println("Getting Config / Setting State: ");
  getConfig();
  setState(String("Device:") + String(device_id) +
      String(">connected"));
}

void loop() {
  delay(10000);

  if (backoff()) {
    getConfig();
    sendTelemetry();
  }
}
