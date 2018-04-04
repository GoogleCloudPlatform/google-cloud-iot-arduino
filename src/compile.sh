#!/bin/bash
#******************************************************************************
# Copyright 2018 Google
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#****************************************************************************


# This script makes a folder with an Arduino jwt library. If you run it from the
# directory it is in you will see a jwt folder created. To clean the outputs run
# source compile.sh clean.

# Clean output folder.
rm -rf jwt

if [[ "$1" = clean ]]
then
  rm -rf tmp
else
  # Make temp directory, cd into it.
  if ! [[ -a tmp ]]
  then
    mkdir tmp
  fi
  cd tmp

  # Download ecc library.
  if ! [[ -a ecc-light-certificate ]]
  then
    git clone https://github.com/cirvladimir/ecc-light-certificate.git
  else
    # Library already cloned, update it.
    cd ecc-light-certificate
    git pull origin master
    cd ..
  fi

  if ! [[ -a ESP8266-Arduino-cryptolibs ]]
  then
    git clone https://github.com/CSSHL/ESP8266-Arduino-cryptolibs.git
  else
    cd ESP8266-Arduino-cryptolibs
    git pull origin master
    cd ..
  fi

  # cd out of tmp.
  cd ..

  # Copy sources into jwt folder.
  mkdir jwt
  cp jwt.h jwt
  cp jwt.cpp jwt
  cp prng.c jwt
  cp prng.h jwt
  cp tmp/ESP8266-Arduino-cryptolibs/sha256/sha256.cpp jwt
  cp tmp/ESP8266-Arduino-cryptolibs/sha256/sha256.h jwt
  cp tmp/ecc-light-certificate/ecc/curve-params/secp256r1.c jwt
  cp tmp/ecc-light-certificate/ecc/ecc.c jwt
  cp tmp/ecc-light-certificate/ecc/ecc.h jwt
  cp tmp/ecc-light-certificate/ecc/ecdsa.c jwt
  cp tmp/ecc-light-certificate/ecc/ecdsa.h jwt
  cp tmp/ecc-light-certificate/ecc/nn.c jwt
  cp tmp/ecc-light-certificate/ecc/nn.h jwt

  # Remove unnecessary sha library.
  sed -i '/#include "sha2.h"/d' jwt/ecdsa.h
  # Add some defines since we're not using make.
  sed -i '1i#define SHA256_DIGEST_LENGTH 32' jwt/ecdsa.h
  sed -i '1i#define THIRTYTWO_BIT_PROCESSOR' jwt/nn.h
  sed -i '1i#define SECP256R1' jwt/nn.h
fi
