/******************************************************************************
 * Copyright 2018 Google
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
#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#define NO8266
#include "jwt.h"
#include <time.h>

#define MQTT_MAX_PACKET_SIZE 512
#include <PubSubClient.h>

// Wifi newtork details.
const char *ssid = "SSID";
const char *password = "PASSWORD";

// Cloud iot details.
const char *project_id = "project-id";
const char *location = "us-central1";
const char *registry_id = "my-registry";
const char *device_id = "my-esp32-device";

// To get the private key run (where private-key.pem is the ec private key
// used to create the certificate uploaded to google cloud iot):
// openssl ec -in <private-key.pem> -noout -text
// and copy priv: part.
const char *private_key_str =
    "6e:b8:17:35:c7:fc:6b:d7:a9:cb:cb:49:7f:a0:67:"
    "63:38:b0:90:57:57:e0:c0:9a:e8:6f:06:0c:d9:ee:"
    "31:41";

// To get the certificate for your region run:
// openssl s_client -showcerts -connect mqtt.googleapis.com:8883
// Copy the certificate (all lines between and including ---BEGIN CERTIFICATE---
// and --END CERTIFICATE--) to root.cert and put here on the root_cert variable.

const char *root_cert =
    "-----BEGIN CERTIFICATE-----\n"
    "MIIEXDCCA0SgAwIBAgINAeOpMBz8cgY4P5pTHTANBgkqhkiG9w0BAQsFADBMMSAw\n"
    "HgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMjETMBEGA1UEChMKR2xvYmFs\n"
    "U2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0xNzA2MTUwMDAwNDJaFw0yMTEy\n"
    "MTUwMDAwNDJaMFQxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVHb29nbGUgVHJ1c3Qg\n"
    "U2VydmljZXMxJTAjBgNVBAMTHEdvb2dsZSBJbnRlcm5ldCBBdXRob3JpdHkgRzMw\n"
    "ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDKUkvqHv/OJGuo2nIYaNVW\n"
    "XQ5IWi01CXZaz6TIHLGp/lOJ+600/4hbn7vn6AAB3DVzdQOts7G5pH0rJnnOFUAK\n"
    "71G4nzKMfHCGUksW/mona+Y2emJQ2N+aicwJKetPKRSIgAuPOB6Aahh8Hb2XO3h9\n"
    "RUk2T0HNouB2VzxoMXlkyW7XUR5mw6JkLHnA52XDVoRTWkNty5oCINLvGmnRsJ1z\n"
    "ouAqYGVQMc/7sy+/EYhALrVJEA8KbtyX+r8snwU5C1hUrwaW6MWOARa8qBpNQcWT\n"
    "kaIeoYvy/sGIJEmjR0vFEwHdp1cSaWIr6/4g72n7OqXwfinu7ZYW97EfoOSQJeAz\n"
    "AgMBAAGjggEzMIIBLzAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0lBBYwFAYIKwYBBQUH\n"
    "AwEGCCsGAQUFBwMCMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFHfCuFCa\n"
    "Z3Z2sS3ChtCDoH6mfrpLMB8GA1UdIwQYMBaAFJviB1dnHB7AagbeWbSaLd/cGYYu\n"
    "MDUGCCsGAQUFBwEBBCkwJzAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AucGtpLmdv\n"
    "b2cvZ3NyMjAyBgNVHR8EKzApMCegJaAjhiFodHRwOi8vY3JsLnBraS5nb29nL2dz\n"
    "cjIvZ3NyMi5jcmwwPwYDVR0gBDgwNjA0BgZngQwBAgIwKjAoBggrBgEFBQcCARYc\n"
    "aHR0cHM6Ly9wa2kuZ29vZy9yZXBvc2l0b3J5LzANBgkqhkiG9w0BAQsFAAOCAQEA\n"
    "HLeJluRT7bvs26gyAZ8so81trUISd7O45skDUmAge1cnxhG1P2cNmSxbWsoiCt2e\n"
    "ux9LSD+PAj2LIYRFHW31/6xoic1k4tbWXkDCjir37xTTNqRAMPUyFRWSdvt+nlPq\n"
    "wnb8Oa2I/maSJukcxDjNSfpDh/Bd1lZNgdd/8cLdsE3+wypufJ9uXO1iQpnh9zbu\n"
    "FIwsIONGl1p3A8CgxkqI/UAih3JaGOqcpcdaCIzkBaR9uYQ1X4k2Vg5APRLouzVy\n"
    "7a8IVk6wuy6pm+T7HT4LY8ibS5FEZlfAFLSW8NwsVz9SBK2Vqn1N0PIMn5xA6NZV\n"
    "c7o835DLAFshEWfC7TIe3g==\n"
    "-----END CERTIFICATE-----\n";

unsigned int priv_key[8];
const char *host = "mqtt.googleapis.com";
const int httpsPort = 8883;
//const int httpsPort = 443;

WiFiClientSecure client;
PubSubClient mqttClient(client);
std::string pwd;
std::string jwt;

long lastMsg = 0;
char msg[20];
int counter = 0;

const int LED_PIN = 5;

std::string getJwt()
{
    jwt = CreateJwt(project_id, time(nullptr), priv_key);
    return jwt;
}

// Fills the priv_key global variable with private key str which is of the form
// aa:bb:cc:dd:ee:...
void fill_priv_key(const char *priv_key_str)
{
    priv_key[8] = 0;
    for (int i = 7; i >= 0; i--)
    {
        priv_key[i] = 0;
        for (int byte_num = 0; byte_num < 4; byte_num++)
        {
            priv_key[i] = (priv_key[i] << 8) + strtoul(priv_key_str, NULL, 16);
            priv_key_str += 3;
        }
    }
}

// Gets the google cloud iot http endpoint path.
std::string get_path(const char *project_id, const char *location,
                     const char *registry_id, const char *device_id)
{
    return std::string("projects/") + project_id + "/locations/" + location +
           "/registries/" + registry_id + "/devices/" + device_id;
}

std::string get_config_topic(const char *device_id)
{
    return std::string("/devices/") + device_id + "/config";
}

std::string get_events_topic(const char *device_id)
{
    return std::string("/devices/") + device_id + "/events";
}

std::string get_state_topic(const char *device_id)
{
    return std::string("/devices/") + device_id + "/state";
}

std::string get_client_id()
{
    return get_path(project_id, location, registry_id, device_id);
}

void callback(char *topic, uint8_t *payload, unsigned int length)
{
    Serial.print("Message received: ");
    Serial.println(topic);

    Serial.print("payload: ");
    char val[length];
    for (int i = 0; i < length; i++)
    {
        Serial.print((char)payload[i]);
        val[i] = (char)payload[i];
    }
    Serial.println();

    //int ret = rbase64.decode(val);
    int ret = 0;
    if (ret == 0)
    {
        // we got '1' -> on
        if (val[0] == '1')
        {
            Serial.println("High");
            digitalWrite(LED_PIN, HIGH);
        }
        else
        {
            // we got '0' -> on
            Serial.println("Low");
            digitalWrite(LED_PIN, LOW);
        }
    }
    else
    {
        Serial.println("Error decoding");
    }
}

void mqtt_connect()
{
    /* Loop until reconnected */
    while (!client.connected())
    {
        Serial.println("MQTT connecting ...");
        std::string pass = getJwt();
        Serial.println(pass.c_str());
        const char *user = "unused";
        std::string clientId = get_client_id();
        Serial.println(clientId.c_str());
        if (mqttClient.connect(clientId.c_str(), user, pass.c_str()))
        {
            Serial.println("connected");
            std::string configTopic = get_config_topic(device_id);
            Serial.println(configTopic.c_str());
            mqttClient.setCallback(callback);
            mqttClient.subscribe(configTopic.c_str(), 0);
        }
        else
        {
            Serial.print("failed, status code =");
            Serial.print(mqttClient.state());
            Serial.println(" try again in 5 seconds");
            /* Wait 5 seconds before retrying */
            delay(5000);
        }
    }
}

void setup()
{
    pinMode(LED_PIN, OUTPUT);

    fill_priv_key(private_key_str);

    // put your setup code here, to run once:
    Serial.begin(115200);

    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);
    Serial.println("Connecting to WiFi");
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(100);
    }

    configTime(0, 0, "pool.ntp.org", "time.nist.gov");
    Serial.println("Waiting on time sync...");
    while (time(nullptr) < 1510644967)
    {
        delay(10);
    }

    Serial.println("Connecting to mqtt.googleapis.com");
    client.setCACert(root_cert);
    mqttClient.setServer(host, httpsPort);
    mqttClient.setCallback(callback);
}

void loop()
{
    if (!mqttClient.connected())
    {
        mqtt_connect();
    }

    mqttClient.loop();

    long now = millis();
    if (now - lastMsg > 3000)
    {
        lastMsg = now;
        if (counter < 1000)
        {
            counter++;
            snprintf(msg, 20, "%d", counter);
            /* publish the message */
            std::string eventsTopic = get_events_topic(device_id);
            mqttClient.publish(eventsTopic.c_str(), msg);
        }
        else
        {
            counter = 0;
        }
    }

    // I had some issues on the PubSubClient without some delay
    delay(10);
}
