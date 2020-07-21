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
 *
 *****************************************************************************/

/*********
  This demo does the following:
    1. Loads small image from OV2640 camera
    2. Optionally base64-encodes payload data
    3. Transmits encoded bytes to Google Cloud

  Portions of the code used here are based on the following tutorial:
  https://randomnerdtutorials.com/esp32-cam-video-streaming-web-server-camera-home-assistant/

  ...and bearing the following notice to be distributed code:
  """
  IMPORTANT!!!
   - Select Board "ESP32 Wrover Module"
   - Select the Partion Scheme "Huge APP (3MB No OTA)
   - GPIO 0 must be connected to GND to upload a sketch
   - After connecting GPIO 0 to GND, press the ESP32-CAM on-board RESET button to put your board in flashing mode

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files.

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  """
*********/
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

#include "esp_camera.h"
#include <esp_wifi.h>
#include "esp_timer.h"
#include "fb_gfx.h"
#include "img_converters.h"
#include "soc/soc.h" //disable brownout problems
#include "soc/rtc_cntl_reg.h"  //disable brownout problems
#include "Arduino.h"
#include "SPIFFS.h"
#include <WiFi.h>

#include "base64.h"
#include "esp32-mqtt.h"


#define CAMERA_LED_GPIO 13
//#define CAMERA_MODEL_M5STACK_WITHOUT_PSRAM
//#define CAMERA_MODEL_M5STACK_PSRAM
#define CAMEAR_MODEL_M5STACK_PSRAM_ALT

#if defined(CAMERA_MODEL_M5STACK_WITHOUT_PSRAM)
  #define PWDN_GPIO_NUM     -1
  #define RESET_GPIO_NUM    15
  #define XCLK_GPIO_NUM     27
  #define SIOD_GPIO_NUM     25
  #define SIOC_GPIO_NUM     23

  #define Y9_GPIO_NUM       19
  #define Y8_GPIO_NUM       36
  #define Y7_GPIO_NUM       18
  #define Y6_GPIO_NUM       39
  #define Y5_GPIO_NUM        5
  #define Y4_GPIO_NUM       34
  #define Y3_GPIO_NUM       35
  #define Y2_GPIO_NUM       17
  #define VSYNC_GPIO_NUM    22
  #define HREF_GPIO_NUM     26
  #define PCLK_GPIO_NUM     21

#elif defined(CAMERA_MODEL_M5STACK_PSRAM)
  #define PWDN_GPIO_NUM     -1
  #define RESET_GPIO_NUM    15
  #define XCLK_GPIO_NUM     27
  #define SIOD_GPIO_NUM     25
  #define SIOC_GPIO_NUM     23

  #define Y9_GPIO_NUM       19
  #define Y8_GPIO_NUM       36
  #define Y7_GPIO_NUM       18
  #define Y6_GPIO_NUM       39
  #define Y5_GPIO_NUM        5
  #define Y4_GPIO_NUM       34
  #define Y3_GPIO_NUM       35
  #define Y2_GPIO_NUM       32
  #define VSYNC_GPIO_NUM    22
  #define HREF_GPIO_NUM     26
  #define PCLK_GPIO_NUM     21

#elif defined(CAMEAR_MODEL_M5STACK_PSRAM_ALT)
  #define PWDN_GPIO_NUM     -1
  #define RESET_GPIO_NUM    15
  #define XCLK_GPIO_NUM     27
  #define SIOD_GPIO_NUM     22
  #define SIOC_GPIO_NUM     23

  #define Y9_GPIO_NUM       19
  #define Y8_GPIO_NUM       36
  #define Y7_GPIO_NUM       18
  #define Y6_GPIO_NUM       39
  #define Y5_GPIO_NUM        5
  #define Y4_GPIO_NUM       34
  #define Y3_GPIO_NUM       35
  #define Y2_GPIO_NUM       32
  #define VSYNC_GPIO_NUM    25
  #define HREF_GPIO_NUM     26
  #define PCLK_GPIO_NUM     21

#else
  #error "Camera model not selected"
#endif

void setup() {
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0); //disable brownout detector

  Serial.begin(115200);
  Serial.setDebugOutput(false);

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;

  if(psramFound()){
    config.frame_size = FRAMESIZE_SVGA;//FRAMESIZE_UXGA;
    config.jpeg_quality = 10;
    config.fb_count = 1;
  } else {
    config.frame_size = FRAMESIZE_VGA;
    config.jpeg_quality = 12;
    config.fb_count = 1;
  }

  // Camera init
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed with error 0x%x", err);
    //return;
  }else{
    Serial.println("Camera settings seem to be correct!");
  }

  //pinMode(CAMERA_LED_GPIO, OUTPUT);
  //digitalWrite(CAMERA_LED_GPIO, HIGH);

  WiFi.disconnect(true);


  Serial.println("Starting network");
  //digitalWrite(CAMERA_LED_GPIO, LOW);
  delay(500);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  bool on = false;
  //digitalWrite(CAMERA_LED_GPIO, HIGH);
  while (WiFi.status() != WL_CONNECTED) {
    WiFi.waitForConnectResult();
  }
  Serial.println("\nConnected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  setupCloudIoT();

  digitalWrite(CAMERA_LED_GPIO, LOW);

  if (!SPIFFS.begin(true)) {
    Serial.println("An Error has occurred while mounting SPIFFS");
    return;
  }
}


/**
 * This function uses SPIFFS as swap space for temporarily storing the
 * temporary base64-encoded image.
 */
void publishTelemetryFromFile() {
  File file = SPIFFS.open("/b64image.txt", FILE_READ);
  if (!file) {
    Serial.println("There was an error opening the file for read");
    return;
  } else {
    Serial.println("Publishing data using temp file");
  }
  char* data = (char*)heap_caps_malloc(file.size(), MALLOC_CAP_8BIT);

  int i=0;
  while(file.available()){
    data[i++] = file.read();
  }
  Serial.println(String(i) + " bytes read");

  delay(10);
  mqtt->loop();
  mqtt->publishTelemetry(data, file.size());
  mqtt->loop();
  delay(10);
  file.close();
  Serial.println("Done publish.");
}


/**
 * Captures an image using the camera library and transmits it to Google
 * Cloud IoT Core.
 */
void transmitImage() {
  digitalWrite(CAMERA_LED_GPIO, HIGH);

  // Retrieve camera framebuffer
  camera_fb_t * fb = NULL;
  uint8_t* _jpg_buf = NULL;
  esp_err_t res = ESP_OK;
  size_t frame_size = 0;

  fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Camera capture failed");
    res = ESP_FAIL;
  } else {
    if(fb->width > 400){
      Serial.println(fb->format);
      Serial.println(fb->len);
      if(fb->format != PIXFORMAT_JPEG){
        Serial.println("Compressing");
        bool jpeg_converted = frame2jpg(fb, 80, &_jpg_buf, &frame_size);
        esp_camera_fb_return(fb);
        fb = NULL;
        if(!jpeg_converted){
          Serial.println("JPEG compression failed");
          res = ESP_FAIL;
        }
      } else {
        frame_size = fb->len;
        _jpg_buf = fb->buf;
      }
    }
  }
  if (res != ESP_OK) {
    ESP_LOGW(TAG, "Camera capture failed with error = %d", err);
    return;
  }

  publishTelemetry((char*)_jpg_buf, frame_size);
  digitalWrite(CAMERA_LED_GPIO, LOW);
}

// The MQTT callback function for commands and configuration updates
// Place your message handler code here.
void messageReceived(String &topic, String &payload) {
  Serial.println("incoming: " + topic + " - " + payload);
  // Uncomment to transmit image when receiving commands
  // Note: If your device is named command, this will send images on all
  //       messages such as configuration change which is sent on connect.
  if (topic.lastIndexOf("/command") > 0) {
    Serial.println("Transmit image on receieve command");
    transmitImage();
  }
}
///////////////////////////////



int imageWaitMillis = 30000;
unsigned long lastTransmit = millis();
void loop() {
  /*
  // Transmit every 30 seconds?
  if (millis() > lastTransmit + imageWaitMillis) {
    transmitImage();
    lastTransmit = millis();
  }
  */

  // Transmit anytime there's serial input
  if (Serial.available() > 0) {
    // Clear any outstanding input, just one image per head banger
    while(Serial.available() > 0) {
      Serial.read();
    }
    transmitImage();
  }
  delay(10);  // <- fixes some issues with WiFi stability

  if (!mqttClient->connected()) {
    connect();
  } else {
    mqtt->loop();
  }
}
#endif
