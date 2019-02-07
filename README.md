# Google Cloud IoT JWT

This is an example of how to generate JSON Web Token (JWT) credentials for
connecting to Google Cloud IoT Core.

This contains two parts: a library to make a JWT (json web token) which is used
to authenticate with Google Cloud IOT, and Arduino sketches that demonstrate
how to connect to Google Cloud IOT using the available HTTP and MQTT bridges.

**This example is not an officially supported Google product, does not have a
SLA/SLO, and should not be used in production.**

There's been a lot of confusion recently regarding which example to use,
it's recommended that you start with the lwmqtt (light-weight MQTT) examples
as they seem to be the most stable.

## Supported hardware targets

Currently, we support the following hardware targets:

* Genuino MKR1000 and WiFi101
* Espressif ESP32
* Espressif ESP8266

## Dependencies
Some examples use specific dependencies that need to be installed via the Arduino Library manager.

* [rBase64](https://github.com/boseji/rBASE64) - Used when encoding `binary_data` payloads
* [lwMQTT](https://github.com/256dpi/arduino-mqtt) - Used in MQTT Esp8266 example

## Quickstart

First, install the library using the Arduino Library Manager.
* Open Arduino and select the **Sketch > Include Library > Library Manager**
menu item.
* In the filter box, search for "Google Cloud IoT JWT".
* Install the library

Next, enable the Cloud IoT Core API by opening the [Google Cloud IoT Core console](https://console.cloud.google.com/iot/).

Next, create your device registry as described in [the Quickstart](https://cloud.google.com/iot/docs/quickstart)
or by using the [Google Cloud SDK](https://cloud.google.com/sdk).

If you're using the SDK, the following commands will setup PubSub and Cloud IoT
Core for testing on your Arduino device:

Create the PubSub topic and subscription:

    gcloud pubsub topics create atest-pub --project=YOUR_PROJECT_ID
    gcloud pubsub subscriptions create atest-sub --topic=atest--pub

Create the Cloud IoT Core registry:

    gcloud iot registries create atest-registry \
      --region=us-central1 --event-notification-config=topic=atest-pub

Generate an Eliptic Curve (EC) private / public key pair:

    openssl ecparam -genkey -name prime256v1 -noout -out ec_private.pem
    openssl ec -in ec_private.pem -pubout -out ec_public.pem

Register the device using the keys you generated:

    gcloud iot devices create atest-dev --region=us-central1 \
        --registry=atest-registry \
        --public-key path=ec_public.pem,type=es256

At this point, your registry is created and your device has been added to the
registry so you're ready to connect it.

Select one of the available samples from the **File > Examples > Google Cloud IoT Core JWT**
menu and find the configuration section (ciotc_config.h in newer examples).

Find and replace the following values first:
* Project ID (get from console or `gcloud config list`)
* Location (default is `us-central1`)
* Registry ID (created in previous steps, e.g. `atest-reg`)
* Device ID (created in previous steps, e.g. `atest-device`)

You will also need to extract your private key using the following command:

    openssl ec -in ec_private.pem -noout -text

... and will need to copy the output for the private key bytes into the private
key string in your Arduino project.

When you run the sample, the device will connect and receive configuration
from Cloud IoT Core. When you change the configuration in the Cloud IoT Core
console, that configuration will be reflrected on the device.

Before the examples will work, you will also need to configure the root
certificate as described in the configuration headers.

## For more information
* [Access Google Cloud IoT Core from Arduino](https://medium.com/@gguuss/accessing-cloud-iot-core-from-arduino-838c2138cf2b)
* [Building Google Cloud-Connected Sensors](https://medium.com/@gguuss/building-google-cloud-connected-sensors-2d46a1c58012)
* [Arduino and Google Cloud IoT](https://medium.com/@gguuss/arduino-and-google-cloud-iot-e2082e0ac000)
* [Experimenting with Robots and Cloud IoT Core](https://medium.com/@gguuss/experimenting-with-robots-and-cloud-iot-core-790ee17345ef)
* [Arduino Hexspider Revisited](https://medium.com/@gguuss/hexspider-robot-revisited-d78ff7ce9b6c)

## Demos

You can see the Arduino client library in action in [the Cloud IoT Demo from Google I/O 2018](https://www.youtube.com/watch?v=7kpE44tXQak#T=28m)

## Error codes
If you're using a sample that uses PubSub MQTT, the error codes are listed
[in this header file](https://github.com/knolleary/pubsubclient/blob/master/src/PubSubClient.h#L44-L54).

The error codes for the lwMQTT library are listed [in this header file](https://github.com/256dpi/arduino-mqtt/blob/master/src/lwmqtt/lwmqtt.h#L16-L29).

## Known issues

If you're using PlatformIO with the PubSub client, add the following line to your platformio.ini to increase the packet size in the build step.

```
build_flags = -DMQTT_MAX_PACKET_SIZE=384
```

Some private keys do not correctly encode to the Base64 format that required
for the device bridge. If you've tried everything else, try regenerating your
device credentials and registering your device again with

    gcloud iot devices create ...

### HTTP Examples
* We occasionally encounter 403 errors on these samples, not sure of the cause.
  In some cases, it seems this is occurring due to invalid / bad iss / exp fields
  in the JWT.
* Transmitting telemetry seems less reliable than setting state and getting
  device configuration.

## License

Apache 2.0; see [LICENSE](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by Google
and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
