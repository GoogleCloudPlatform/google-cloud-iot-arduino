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

  // connect(address) is fast (upto 10 secs max), connect(name) is slow (upto 30 secs max) as it needs
  // to resolve name to address first, but it allows to connect to different devices with the same name.
  // Set CoreDebugLevel to Info to view devices bluetooth address and device names
  //ESP32test
  connected = SerialBT.connect(staticBTDeviceID);
  //connected = SerialBT.connect(address);

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
