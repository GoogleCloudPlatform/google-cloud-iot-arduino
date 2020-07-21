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

#include <stdio.h>

#include "crypto/ecdsa.h"
#include "crypto/nn.h"
#include "crypto/sha256.h"
#include "jwt.h"

// base64_encode copied from https://github.com/ReneNyffenegger/cpp-base64
static const String base64_chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "abcdefghijklmnopqrstuvwxyz"
    "0123456789-_";

String base64_encode(const unsigned char *bytes_to_encode,
                     unsigned int in_len) {
  String ret;
  int i = 0;
  int j = 0;
  unsigned char char_array_3[3];
  unsigned char char_array_4[4];

  while (in_len--) {
    char_array_3[i++] = *(bytes_to_encode++);
    if (i == 3) {
      char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
      char_array_4[1] =
          ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
      char_array_4[2] =
          ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
      char_array_4[3] = char_array_3[2] & 0x3f;

      for (i = 0; (i < 4); i++) {
        ret += base64_chars[char_array_4[i]];
      }
      i = 0;
    }
  }

  if (i) {
    for (j = i; j < 3; j++) {
      char_array_3[j] = '\0';
    }

    char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
    char_array_4[1] =
        ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
    char_array_4[2] =
        ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
    char_array_4[3] = char_array_3[2] & 0x3f;

    for (j = 0; (j < i + 1); j++) {
      ret += base64_chars[char_array_4[j]];
    }
  }

  return ret;
}

String base64_encode(String str) {
  return base64_encode((const unsigned char *)str.c_str(), str.length());
}

// Get base64 signature string from the signature_r and signature_s ecdsa
// signature.
String MakeBase64Signature(NN_DIGIT *signature_r, NN_DIGIT *signature_s) {
  unsigned char signature[64];
  NN_Encode(signature, (NUMWORDS - 1) * NN_DIGIT_LEN, signature_r,
            (NN_UINT)(NUMWORDS - 1));
  NN_Encode(signature + (NUMWORDS - 1) * NN_DIGIT_LEN,
            (NUMWORDS - 1) * NN_DIGIT_LEN, signature_s,
            (NN_UINT)(NUMWORDS - 1));

  return base64_encode(signature, 64);
}

// Convert an integer to a string.
String int_to_string(long long int x) {
  char buf[20];
  snprintf(buf, 20, "%d", (int)x);
  return String(buf);
}

String CreateJwt(String project_id, long long int time, NN_DIGIT *priv_key, int lib_jwt_exp_secs) {
  ecc_init();
  // Making jwt token json
  String header = "{\"alg\":\"ES256\",\"typ\":\"JWT\"}";
  String payload = "{\"iat\":" + int_to_string(time) +
                   ",\"exp\":" + int_to_string(time + lib_jwt_exp_secs) + ",\"aud\":\"" +
                   project_id + "\"}";
  String header_payload_base64 =
      base64_encode(header) + "." + base64_encode(payload);

  Sha256 sha256Instance;
  sha256Instance.update((const unsigned char *)header_payload_base64.c_str(), header_payload_base64.length());
  unsigned char sha256[SHA256_DIGEST_LENGTH];
  sha256Instance.final(sha256);

  // Signing sha with ec key. Bellow is the ec private key.
  point_t pub_key;
  ecc_gen_pub_key(priv_key, &pub_key);

  ecdsa_init(&pub_key);

  NN_DIGIT signature_r[NUMWORDS], signature_s[NUMWORDS];
  ecdsa_sign((uint8_t *)sha256, signature_r, signature_s, priv_key);

  return header_payload_base64 + "." +
         MakeBase64Signature(signature_r, signature_s);
}

String CreateJwt(String project_id, long long int time, NN_DIGIT *priv_key) {
  return CreateJwt(project_id, time, priv_key, 3600); // one hour default
}
