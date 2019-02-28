# Google Cloud IoT JWT

This is an example of how to generate JSON Web Token (JWT) credentials for
connecting to Google Cloud IoT Core.

This contains two parts: a library to make a JWT (json web token) which is used
to authenticate with Google Cloud IOT, and Arduino sketches that demonstrate
how to connect to Google Cloud IOT using the available MQTT bridge.

**This example is not an officially supported Google product, does not have a
SLA/SLO, and should not be used in production.**

## Supported hardware targets

Currently, we support the following hardware targets:

* Genuino MKR1000 and WiFi101
* Espressif ESP32
* Espressif ESP8266

## Dependencies
Some examples use specific dependencies that need to be installed via the Arduino Library manager.

* [lwMQTT](https://github.com/256dpi/arduino-mqtt)

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
    gcloud pubsub subscriptions create atest-sub --topic=atest-pub

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

## Notes on the certificate

The [root certificate from Google](https://pki.goog/roots/pem) is used to verify communication to
Google. Although unlikely, it's possible for the certificate to expire or rotate, requiring you to
update it.

If you're using the ESP8266 project, you need to either install the Certificate to SPIFFS
using the [SPIFFS upload utility](https://github.com/esp8266/arduino-esp8266fs-plugin) or
will need to uncomment the certificate bytes in the sample. Note that the SPIFFS utility simply 
uploads the files stored in the **data** subfolder. The sample assumes the file is called `ca.crt`:

    ├── Esp8266...
    │   ├── data
    │   │   └── ca.crt

To convert the certificate to the DER format, the following command shuold be used:

    wget pki.goog/roots.pem
    openssl x509 -outform der -in roots.pem -out ca.crt

If you're using the ESP32, you can paste the certificate bytes (don't forget the \n characters) 
into the sample. You can use any of the root certificate bytes for the certificates with Google
Trust Services (GTS) as the certificate authority (CA). This is easy to get using curl, e.g.

    curl pki.goog/roots.pem

If you're using Genuino boards like the MKR1000, you will need to add SSL certificates to your
board as [described on Hackster.io](https://www.hackster.io/arichetta/add-ssl-certificates-to-mkr1000-93c89d).

## For more information

* [Access Google Cloud IoT Core from Arduino](https://medium.com/@gguuss/accessing-cloud-iot-core-from-arduino-838c2138cf2b)
* [Building Google Cloud-Connected Sensors](https://medium.com/@gguuss/building-google-cloud-connected-sensors-2d46a1c58012)
* [Arduino and Google Cloud IoT](https://medium.com/@gguuss/arduino-and-google-cloud-iot-e2082e0ac000)
* [Experimenting with Robots and Cloud IoT Core](https://medium.com/@gguuss/experimenting-with-robots-and-cloud-iot-core-790ee17345ef)
* [Arduino Hexspider Revisited](https://medium.com/@gguuss/hexspider-robot-revisited-d78ff7ce9b6c)

## Demos

You can see the Arduino client library in action in [the Cloud IoT Demo from Google I/O 2018](https://www.youtube.com/watch?v=7kpE44tXQak#T=28m)

## Error codes and Debugging

The error codes for the lwMQTT library are listed [in this header file](https://github.com/256dpi/arduino-mqtt/blob/master/src/lwmqtt/lwmqtt.h#L16-L29).

If you're having trouble determining what's wrong, it may be helpful to enable more verbose debugging in Arduino by setting the debug level in the IDE under **Tools > Core Debug Level > Verbose**.

## Known issues

Some private keys do not correctly encode to the Base64 format that required
for the device bridge. If you've tried everything else, try regenerating your
device credentials and registering your device again with

    gcloud iot devices create ...

Some users have encountered issues with certain versions of the Community SDK 
for Espressif, if you've tried everything else, try using the SDK 2.4.2.

## License

Apache 2.0; see [LICENSE](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by Google
and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
