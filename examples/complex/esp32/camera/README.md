# ESP32 (m5-stack) Camera demo

This demo uses the inexpensive and readily available M5-stack camera to send
images to Google Cloud IoT core and publish to PubSub. You can then process the
images from PubSub. For example, you can store images in Google Cloud Storage,
detect labels with the vision API, or render the images to a client.

**Disclaimer** This demo is still in a rough state, can crash the ESP32 and is
offered with limited support. There are a lot of different models for the ESP32
camera, so ymmv with the provided configurations.

Some of the camera code is based on the [Randomnerdtutorials](https://randomnerdtutorials.com/esp32-cam-video-streaming-web-server-camera-home-assistant/) example
that shows you how to configure the camera for use with the ESP-IDF driver.

## Configuration
You need to configure the camera pins in `camera.ino` to match the
configuration for your particular model.  The example configurations reflect
models encountered during testing but you may need to add your own based on
the data sheet for your device.

Update the values in [ciotc_config.h](ciotc_config.h) so that they match the
configuration for your device.  More information on this can be found in the
library readme.

## Running the demo
After your device is connected, either send a command to your device or open
the serial monitor and send a message to the device.  The device will send
an image to the configured PubSub topic and you can from there process the
image using a subscriber.

For testing, it's easier to base64 encode the image by replacing the following
line:

```cpp
    publishTelemetry((char*)_jpg_buf, frame_size);
```

With the following code to encode and transmit the file:

```cpp
    // Encode the temp data to file system
    my_base64_encode(_jpg_buf, frame_size);
    publishTelemetryFromFile();
```

You must also setup SPIFFS on the device and create an empty SPIFFS image using
the [ESP32 FS plugin](https://github.com/me-no-dev/arduino-esp32fs-plugin).

After you pull the message from the PubSub topic, you can Base64 decode the
image to produce the file. For example, on BSD/Unix/Linux systems, you can
use the built-in utility base64:

```bash
echo "base64-encoded-bytes" | base64 -d > image.jpg
```

## Troubleshooting
If the MQTT connection is resetting when you transmit the image, you may want
to try tweaking the buffer for the MQTT client which is set when
the client is initialized in `esp32-mqtt.h`. The buffer size for the image is
printed to the serial line so that you can have an idea of an appropriate value
to use. You can also try using a different image size, by replacing the value
set on `config.framesize`. For example, you can try the smaller
`FRAMESIZE_QVGA` format.
