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

#ifndef JWT_H_
#define JWT_H_

#include <Arduino.h>
#include "crypto/nn.h"

String CreateJwt(String project_id, long long int time, NN_DIGIT* priv_key);
String CreateJwt(String project_id, long long int time, NN_DIGIT* priv_key, int JWT_EXP_SECS);

#endif  // JWT_H_
