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

#include "prng.h"

#if defined(ESP8266)
#include "esp8266_peri.h"  // Can use RANDOM_REG32
#endif

int prng(unsigned char *buf, size_t len) {
  while (len--) {
    #if defined(ESP8266)
    *buf++ = RANDOM_REG32 % 255;
    break;
    #endif
    *buf++ = random(0, 255);
  }
  return 1;
}
