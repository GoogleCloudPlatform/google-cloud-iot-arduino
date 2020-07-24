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

#if defined(ARDUINO_SAMD_MKR1000) or defined(ESP8266)
#define __SKIP_ESP32__
#endif

#if defined(ESP32)
#define __ESP32_MQTT_H__
#endif

#if defined(ESP32)
#define __ESP32_MQTT_H__
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

#ifdef __ESP32_MQTT_H__
#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h> 

#include <string.h>
#include <DHT.h>

#define DHTPIN 4 // Digital pin connected to the DHT sensor

#define DHTTYPE DHT22 // DHT 22  (AM2302), AM2321

DHT dht(DHTPIN, DHTTYPE);

BLEServer *pServer = NULL;
BLECharacteristic * pNotifyCharacteristic;
BLECharacteristic * pReadCharacteristic;

bool deviceConnected = false;
bool oldDeviceConnected = false;

#define uS_TO_S_FACTOR 1000000  /* Conversion factor for micro seconds to seconds */
#define TIME_TO_SLEEP  5        /* Time ESP32 will go to sleep (in seconds) */

#define SERVICE_UUID                "fdc59e94-27d1-4576-94c6-404b459c11ff" // UART service UUID
#define CHARACTERISTIC_UUID_READ    "fdc59e94-27d2-4576-94c6-404b459c11ff"
#define CHARACTERISTIC_UUID_NOTIFY  "fdc59e94-27d3-4576-94c6-404b459c11ff"

#define dataTemplate "{\n\"Temperature\":%f,\n\"Humidity\":%f\n}"

bool dataDump = false;
uint16_t dataSize = 0;

int pIndex = 0;
int address = 0;

#ifdef __cplusplus
extern "C"
{
#endif
  uint8_t temprature_sens_read();
#ifdef __cplusplus
}
#endif
uint8_t temprature_sens_read();

class MainServerCallbacks : public BLEServerCallbacks
{
  void onConnect(BLEServer *pServer)
  {
    deviceConnected = true;
  };

  void onDisconnect(BLEServer *pServer)
  {
    deviceConnected = false;
  }
};

class ReadCallback : public BLECharacteristicCallbacks
{
  void onRead(BLECharacteristic *pCharacteristic)
  {
    Serial.println("Got read ");
  }
};

class NotifyCallback : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    std::string rxValue = pCharacteristic->getValue();

    std::string dumpStr("d");

    if (rxValue.length() > 0)
    {
      Serial.print("Received Value: ");
      Serial.println(rxValue.c_str());

      if (rxValue.compare(dumpStr) == 0)
      {
        dataDump = true;
      }
    }
  }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting up");
  dht.begin();

  Wire.begin(); //creates a Wire object

  // Create the BLE Device
  BLEDevice::init("BLEDU");

  dataSize = 26; // Full size of external eeprom

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MainServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pReadCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_READ, BLECharacteristic::PROPERTY_READ);
  pReadCharacteristic->setCallbacks(new ReadCallback());
  pReadCharacteristic->setValue(dataSize); // This should changed when new data is saved.

  pNotifyCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_NOTIFY, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY);
  pNotifyCharacteristic->setCallbacks(new NotifyCallback());

  // Start the service
  pService->start();

  // Start advertising the service too.
  pServer->getAdvertising()->addServiceUUID(SERVICE_UUID); 
  pServer->getAdvertising()->start();

  Serial.println("Waiting a client connection to notify...");
}


void sendTemp(){
  char *sensorData = NULL;

  // Reading temperature or humidity takes about 250 milliseconds!
  // Sensor readings may also be up to 2 seconds 'old' (its a very slow sensor)
  float h = dht.readHumidity();
  // Read temperature as Celsius (the default)
  float t = dht.readTemperature();

  asprintf(&sensorData, dataTemplate, t, h);

  Serial.println(sensorData);
  if (deviceConnected)
  {
    pNotifyCharacteristic->setValue(sensorData);
    pNotifyCharacteristic->notify();
  }
  delay(5000);
}

void loop() {
  if (deviceConnected)
  {
    sendTemp();
    Serial.println("Temp Sent");
  }
    // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
      delay(500); // give the bluetooth stack the chance to get things ready
      pServer->startAdvertising(); // restart advertising
      Serial.println("Start advertising");
      oldDeviceConnected = deviceConnected;
  }

  // connecting
  if (deviceConnected && !oldDeviceConnected) {
      oldDeviceConnected = deviceConnected;
  }
 }
 #endif
