# ESP32 Gateway demo

This demo uses two inexpensive and readily available ESP32's to send
telemetry data, one ESP32 acting as a gateway to Google Cloud IoT core and another ESP32
acting as the delegate device that sends data to the gateway.The gateway will send the
data to Google Cloud IoT core and publish to PubSub. For example, you can send temperature
data from multiple delegate devices to Google Cloud and store that information to see
any drastic temperature changes in a room.

**Disclaimer** This demo is still in a rough state, it can crash the ESP32 and is
offered with limited support.

Some of the SerialBT code is based on [Espressif](https://github.com/espressif/arduino-esp32/tree/master/libraries/BluetoothSerial/examples/) examples
that shows you how to connect two devices over serial bluetooth.

## Configuration
You need to configure the devices to connect over bluetooth in `ESP32_delegate.ino`.
Make sure that the device_id you enter matches the device_id on the Google Cloud IoT core.
The example configurations reflect models encountered during testing but you
may need to add your own based on the data sheet for your device.

Update the values in [ciotc_config.h](ciotc_config.h) so that they match the
configuration for your gateway device and delegate devices.

## Running the demo
After your gateway device is connected, you can now send an attach command
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
make sure to check that you delegate devices are bounded to the gateway and that they are set up correctly.
