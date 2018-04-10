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

#include "CloudIoTCoreDevice.h"
#include "jwt.h"

CloudIoTCoreDevice::CloudIoTCoreDevice() {}

CloudIoTCoreDevice::CloudIoTCoreDevice(const char *project_id,
                                       const char *location,
                                       const char *registry_id,
                                       const char *device_id) {
  setProjectId(project_id);
  setLocation(location);
  setRegistryId(registry_id);
  setDeviceId(device_id);
}

CloudIoTCoreDevice::CloudIoTCoreDevice(const char *project_id,
                                       const char *location,
                                       const char *registry_id,
                                       const char *device_id,
                                       const char *private_key) {
  setProjectId(project_id);
  setLocation(location);
  setRegistryId(registry_id);
  setDeviceId(device_id);
  setPrivateKey(private_key);
}

String CloudIoTCoreDevice::createJWT(long long int current_time) {
  jwt = CreateJwt(project_id, current_time, priv_key);
  return jwt;
}

String CloudIoTCoreDevice::getJWT() { return jwt; }

String CloudIoTCoreDevice::getBasePath() {
  return String("/v1/projects/") + project_id + "/locations/" + location +
         "/registries/" + registry_id + "/devices/" + device_id;
}

String CloudIoTCoreDevice::getConfigPath(int version) {
  char buf[8] = {0};
  itoa(version, buf, 10);
  return this->getBasePath() + "/config?local_version=" + buf;
}

String CloudIoTCoreDevice::getLastConfigPath() {
  return this->getConfigPath(0);
}

String CloudIoTCoreDevice::getSendTelemetryPath() {
  return this->getBasePath() + ":publishEvent";
}

void CloudIoTCoreDevice::fillPrivateKey() {
  priv_key[8] = 0;
  for (int i = 7; i >= 0; i--) {
    priv_key[i] = 0;
    for (int byte_num = 0; byte_num < 4; byte_num++) {
      priv_key[i] = (priv_key[i] << 8) + strtoul(private_key, NULL, 16);
      private_key += 3;
    }
  }
}

CloudIoTCoreDevice &CloudIoTCoreDevice::setProjectId(const char *project_id) {
  this->project_id = project_id;
  return *this;
}

CloudIoTCoreDevice &CloudIoTCoreDevice::setLocation(const char *location) {
  this->location = location;
  return *this;
}

CloudIoTCoreDevice &CloudIoTCoreDevice::setRegistryId(const char *registry_id) {
  this->registry_id = registry_id;
  return *this;
}

CloudIoTCoreDevice &CloudIoTCoreDevice::setDeviceId(const char *device_id) {
  this->device_id = device_id;
  return *this;
}

CloudIoTCoreDevice &CloudIoTCoreDevice::setPrivateKey(const char *private_key) {
  this->private_key = private_key;
  fillPrivateKey();
  return *this;
}
