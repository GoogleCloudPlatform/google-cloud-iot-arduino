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
// This file contains your configuration used to connect to Cloud IoT Core

// Wifi newtork details.
const char* ssid = "SSID";
const char* password = "PASSWORD";

// Cloud iot details.
const char* project_id = "PROJECT-ID";
const char* location = "us-central1";
const char* registry_id = "REGISTRY-ID";
const char* device_id = "DEVICE-ID";

// To get the private key run (where private-key.pem is the ec private key
// used to create the certificate uploaded to google cloud iot):
// openssl ec -in <private-key.pem> -noout -text
// and copy priv: part.
const char* private_key_str =
    "5a:2e:06:b5:c1:f2:9c:b3:77:b2:89:f5:29:29:93:"
    "07:fd:ed:22:0d:03:2b:a6:b1:b6:04:0b:d5:9b:49:"
    "7d:ca";
