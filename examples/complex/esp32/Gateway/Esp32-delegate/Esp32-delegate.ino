//This example code is in the Public Domain (or CC0 licensed, at your option.)
//By Evandro Copercini - 2018
//
//This example creates a bridge between Serial and Classical Bluetooth (SPP)
//and also demonstrate that SerialBT have the same functionalities of a normal Serial

#include "BluetoothSerial.h"

BluetoothSerial SerialBT;

const String DeviceID = "delegate-esp32-device";

#ifdef __cplusplus
  extern "C" {
#endif
 
  uint8_t temprature_sens_read();
 
#ifdef __cplusplus
}
#endif

typedef struct __attribute__((packed)) esp_now_msg_t {
  String deviceid;
  String command;
  String payload;
  String type;
} esp_now_msg_t;

esp_now_msg_t incoming_msg;

String input;
bool done = false;

void handleGatewayCommand() {
  if(incoming_msg.deviceid != DeviceID) {
      Serial.println("Connected to wrong Device;");
      return;  
  }

  if (incoming_msg.command == "configuration") {
      // Write your code to handle configurations
        Serial.println(incoming_msg.payload);
  }
  else if (incoming_msg.command == "event") {
      if(incoming_msg.payload == "get temperature") {
            SerialBT.println("type:Command");
            SerialBT.println("data:" + String((temprature_sens_read() - 32)/1.8) + " C;");
            Serial.println("Sent Data");
      }
      else {
          Serial.print("Couldn't Find payload");  
      }
  }
  else if (incoming_msg.command == "state") {
      if(incoming_msg.payload == "get state") {
            SerialBT.println("type:Command");
            SerialBT.println("data: Device on;");
            Serial.println("Sent Data");
      }
  }
}

void parseInput(String in) {
  int x = 0;
  char str_array[in.length()+1];
  in.toCharArray(str_array,in.length()+1);
  char * pars = strtok (str_array,",");
  char * msgArray[3];
  while(pars != NULL)
  {
    msgArray[x] = pars;
    x++;
    pars = strtok (NULL,",");
  }

  incoming_msg.deviceid = String(msgArray[0]);
  incoming_msg.command = String(msgArray[1]);
  incoming_msg.payload = String(msgArray[2]);

  Serial.println(incoming_msg.payload);

  handleGatewayCommand();

  delay(1000);

}

void setup() {
  Serial.begin(115200);
  SerialBT.begin(DeviceID); //Bluetooth device name
  Serial.println("The device started, now you can pair it with bluetooth!");
}

void loop() {
  if(done == false) {
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
}
