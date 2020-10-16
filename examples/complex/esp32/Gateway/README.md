# ESP32 Gateway demo

This demo uses two inexpensive and readily available ESP32 devices to send and receive
data from Google Cloud. The device with a connection to Google Cloud (Gateway) will
communicate on behalf of other devices (delegate devices).
The gateway will send the data to Google Cloud IoT core and publish to PubSub.
For example, you can send temperature data from multiple delegate devices to Google Cloud and store that information to see
any drastic temperature changes in a room.

**Disclaimer** This demo is not a robust solution, can crash the ESP32, and is offered with limited support.

Some of the SerialBT code is based on [Espressif](https://github.com/espressif/arduino-esp32/tree/master/libraries/BluetoothSerial/examples/) examples
that shows you how to connect two devices over serial bluetooth.

## Configuration

Create a gateway and a delegate device, make sure that the both devices are setup on the cloud and that the delegate device is bound to the gateway.

Specify the devices that connect over bluetooth in `ESP32_delegate.ino`. These devices
must correspond to devices created in the [Cloud IoT Core section of the Cloud Console](https://console.cloud.google.com/iot).
The example IDs correspond to the device_id on the Google Cloud IoT core.

Update the values in [ciotc_config.h](ciotc_config.h) so that they match the
configuration for your gateway device and delegate devices.

## Running the demo
Flash the gateway device with the project sources in Esp32-Gateway and delegate device(s) with the project sources in Esp32-delegate,
then restart both devices.After your gateway device is connected, you can now send an attach command
which will attach the delegate devices found in [ciotc_config.h](ciotc_config.h).
Once you delegate devices are attached you can send a command to your devices from the cloud,
the command must follow the following order and structure:

        deviceid,command,data;

For the example the commands you can send are the following:

        deviceid,event,get temperature;
        deviceid,state,get state;

The gateway device will connect to the delegate over bluetooth and forward this command to the delegate device,
then the gateway will receive the response and publish to the PubSub subscription.

After you pull the message from the PubSub topic, you should then see the temperature read out or the state of the device depending on the command you sent.

## Troubleshooting
If the MQTT connection is resetting when you're attaching the delegate devices,
make sure that your delegate devices are bound to the gateway and that the gateway is configured to use association-only in the [Cloud Console](https://console.cloud.google.com/iot?pli=1).

Note that if you are attaching more than 10 delegate devices to the gateway, you should increase the timeout in `ciotc_config.h`.
