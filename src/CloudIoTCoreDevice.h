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

#ifndef CloudIoTCoreDevice_h
#define CloudIoTCoreDevice_h

#include <string>

class CloudIoTCoreDevice
{
private:
  const char *project_id;
  const char *location;
  const char *registry_id;
  const char *device_id;
  const char *private_key;

  unsigned int priv_key[8];
  std::string jwt;

  void fillPrivateKey();
  std::string getBasePath();

public:
  CloudIoTCoreDevice();
  CloudIoTCoreDevice(const char *project_id, const char *location, const char *registry_id, const char *device_id);
  CloudIoTCoreDevice(const char *project_id, const char *location, const char *registry_id, const char *device_id, const char *private_key);

  CloudIoTCoreDevice &setProjectId(const char *project_id);
  CloudIoTCoreDevice &setLocation(const char *location);
  CloudIoTCoreDevice &setRegistryId(const char *registry_id);
  CloudIoTCoreDevice &setDeviceId(const char *device_id);
  CloudIoTCoreDevice &setPrivateKey(const char *private_key);

  std::string createJWT(long long int time);
  std::string getJWT();

  /* HTTP methods path */
  std::string getConfigPath(int version);
  std::string getLastConfigPath();
  std::string getSendTelemetryPath();
};
#endif // CloudIoTCoreDevice_h