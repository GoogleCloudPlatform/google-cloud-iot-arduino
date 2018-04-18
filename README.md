# Google Cloud IOT JWT

This is an example of how to generate JSON Web Token (JWT) credentials for
connecting to Google Cloud IoT Core.

This contains two parts: a library to make a JWT (json web token) which is used
to authenticate with Google Cloud IOT, and Arduino sketches that demonstrate
how to connect to Google Cloud IOT using the available HTTP and MQTT bridges.

This example is not an officially supported Google product, does not have a
SLA/SLO, and should not be used in production.

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

    gcloud iot devices create atest-dev —region=us-central1 \
        —registry=atest-registry \
        —public-key path=ec_public.pem,type=es256

At this point, your registry is created and your device has been added to the
registry so you're ready to connect it.

Select one of the available samples from the **File > Examples > Google Cloud IoT Core JWT**
menu and find the configuration section (ciotc_config.h in newer examples).

Find and replace the following values first:
* Project ID (get from console or `gcloud list config`)
* Location (default is `us-central1`)
* Registry ID (created in previous steps, e.g. `atest-reg`)
* Device ID (created in previous steps, e.g. `atest-device`)

You will also need to extract your private key using the following command:

    openssl ec -in ec_private.pem --noout -text

... and will need to copy the output for the private key bytes into the private
key string in your Arduino project.

When you run the sample, the device will connect and receive configuration
from Cloud IoT Core. When you change the configuration in the Cloud IoT Core
console, that configuration will be reflrected on the device.

## The JWT library

The JWT library is contained in the `/jwt` folder. To generate the library run
the following commands from the `jwt` directory:

```bash
cd jwt
source compile.sh
```

The above command will create a new directory `jwt/jwt` which is a working
Arduino library. To install it copy it to the libraries folder of your Arduino
installation (`~/Arduino/libraries` on linux). When we publish the library,
the output of that folder is placed into the `/src`.

To clean the output run `source compile.sh clean`.

## Known issues

### HTTP Examples
* We occasionally encounter 403 errors on these samples, not sure of the cause.
  In some cases, it seems this is occurring due to invalid / bad iss / exp fields
  in the JWT.

### ESP32-MQTT
* If you don't comment out line 266 of the MQTT PubSub client, PubSubClient.cpp,
the sample will crash when a non-empty payload is transmitted to the device.


## License

Apache 2.0; see [LICENSE](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by Google
and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
