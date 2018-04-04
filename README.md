# Google Cloud IOT Example on ESP8266

This is an example of how to connect to Google Cloud IOT from an ESP8266 chip.

This can then be used to interface with an Arduino.

This contains two parts: a library to make a JWT (json web token) which is used
to authenticate with Google Cloud IOT, and a working Arduino sketch on
demonstrating how to connect to Google Cloud IOT.

This assumes you are using an Arduino IDE with an ESP8266 chip.

This is not an officially supported Google product.

This example does not have SLA/SLO and should not be used in production.

## The JWT library

The JWT library is contained in the `/jwt` folder. To generate it run the
following commands from this directory:

```bash
cd jwt
source compile.sh
```

The above command will create a new directory `jwt/jwt` which is a working
Arduino library. To install it copy it to the libraries folder of your Arduino
installation (`~/Arduino/libraries` on linux). When we publish the library,
the output of that folder is placed into the `/src`.

To clean the output run `source compile.sh clean`.

## The example

To run the example copy espgciot.ino into the Arduino editor and run the code on
the ESP8266.

## License

Apache 2.0; see [LICENSE](LICENSE) for details.

## Disclaimer

This project is not an official Google project. It is not supported by Google
and Google specifically disclaims all warranties as to its quality,
merchantability, or fitness for a particular purpose.
