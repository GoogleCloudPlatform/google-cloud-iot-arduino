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

#ifndef CloudIoTCore_h
#define CloudIoTCore_h

#include "CloudIoTCoreDevice.h"

#ifndef CLOUD_IOT_CORE_HTTP_HOST
#define CLOUD_IOT_CORE_HTTP_HOST "cloudiotdevice.googleapis.com"
#endif

#ifndef CLOUD_IOT_CORE_HTTP_PORT
#define CLOUD_IOT_CORE_HTTP_PORT 443
#endif

#ifndef CLOUD_IOT_CORE_MQTT_HOST
#define CLOUD_IOT_CORE_MQTT_HOST "mqtt.googleapis.com"
#endif

#ifndef CLOUD_IOT_CORE_MQTT_HOST_LTS
#define CLOUD_IOT_CORE_MQTT_HOST_LTS "mqtt.2030.ltsapis.goog"
#endif

#ifndef CLOUD_IOT_CORE_MQTT_PORT
#define CLOUD_IOT_CORE_MQTT_PORT 8883
#endif

#endif // CloudIoTCore_h
