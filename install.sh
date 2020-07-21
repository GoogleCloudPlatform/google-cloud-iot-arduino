#!/usr/bin/env bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# we need bash 4 for associative arrays
if [ "${BASH_VERSION%%[^0-9]*}" -lt "4" ]; then
  echo "BASH VERSION < 4: ${BASH_VERSION}" >&2
  exit 1
fi

# associative array for the platforms that will be verified in build_main_platforms()
# this will be eval'd in the functions below because arrays can't be exported
# Uno is ATmega328, Zero is SAMD21G18, ESP8266, Leonardo is ATmega32u4, M4 is SAMD51, Mega is ATmega2560, ESP32
export MAIN_PLATFORMS='declare -A main_platforms=( [esp8266]="esp8266:esp8266:generic:xtal=80,vt=flash,exception=disabled,ResetMethod=ck,CrystalFreq=26,FlashFreq=40,FlashMode=dout,eesz=512K,led=2,ip=lm2f,dbg=Disabled,lvl=None____,wipe=none,baud=115200" [esp32]="esp32:esp32:featheresp32:FlashFreq=80,PartitionScheme=no_ota" [mkr1000]="arduino:samd:mkr1000" )'

# associative array for other platforms that can be called explicitly in .travis.yml configs
# this will be eval'd in the functions below because arrays can't be exported
export AUX_PLATFORMS=''

export CPLAY_PLATFORMS=''

export SAMD_PLATFORMS='declare -A samd_platforms=( [zero]="arduino:samd:arduino_zero_native", [mkr1000]="arduino:samd:mkr1000", [cplayExpress]="arduino:samd:adafruit_circuitplayground_m0", [m4]="adafruit:samd:adafruit_metro_m4:speed=120" )'

export M4_PLATFORMS=''

export ARCADA_PLATFORMS=''

export IO_PLATFORMS='declare -A io_platforms=( [zero]="arduino:samd:arduino_zero_native",  [m4wifi]="adafruit:samd:adafruit_metro_m4_airliftlite:speed=120", [esp8266]="esp8266:esp8266:huzzah:eesz=4M3M,xtal=80" [esp32]="esp32:esp32:featheresp32:FlashFreq=80" )'

export NRF5X_PLATFORMS=''

# make display available for arduino CLI
/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_1.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :1 -ac -screen 0 1280x1024x16
sleep 3
export DISPLAY=:1.0

#This condition is to avoid reruning install when build argument is passed
if [[ $# -eq 0 ]] ; then
# define colors
GRAY='\033[1;30m'; RED='\033[0;31m'; LRED='\033[1;31m'; GREEN='\033[0;32m'; LGREEN='\033[1;32m'; ORANGE='\033[0;33m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; LBLUE='\033[1;34m'; PURPLE='\033[0;35m'; LPURPLE='\033[1;35m'; CYAN='\033[0;36m'; LCYAN='\033[1;36m'; LGRAY='\033[0;37m'; WHITE='\033[1;37m';

echo -e "\n########################################################################";
echo -e "${YELLOW}INSTALLING ARDUINO IDE"
echo "########################################################################";

# if .travis.yml does not set version
if [ -z $ARDUINO_IDE_VERSION ]; then
export ARDUINO_IDE_VERSION="1.8.11"
echo "NOTE: YOUR .TRAVIS.YML DOES NOT SPECIFY ARDUINO IDE VERSION, USING $ARDUINO_IDE_VERSION"
fi

# if newer version is requested
if [ ! -f $HOME/arduino_ide/$ARDUINO_IDE_VERSION ] && [ -f $HOME/arduino_ide/arduino ]; then
echo -n "DIFFERENT VERSION OF ARDUINO IDE REQUESTED: "
shopt -s extglob
cd $HOME/arduino_ide/
rm -rf *
if [ $? -ne 0 ]; then echo -e """$RED""\xe2\x9c\x96"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
cd $OLDPWD
fi

# if not already cached, download and install arduino IDE
echo -n "ARDUINO IDE STATUS: "
if [ ! -f $HOME/arduino_ide/arduino ]; then
echo -n "DOWNLOADING: "
wget --quiet https://downloads.arduino.cc/arduino-$ARDUINO_IDE_VERSION-linux64.tar.xz
if [ $? -ne 0 ]; then echo -e """$RED""\xe2\x9c\x96"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
echo -n "UNPACKING ARDUINO IDE: "
[ ! -d $HOME/arduino_ide/ ] && mkdir $HOME/arduino_ide
tar xf arduino-$ARDUINO_IDE_VERSION-linux64.tar.xz -C $HOME/arduino_ide/ --strip-components=1
if [ $? -ne 0 ]; then echo -e """$RED""\xe2\x9c\x96"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
touch $HOME/arduino_ide/$ARDUINO_IDE_VERSION
else
echo -n "CACHED: "
echo -e """$GREEN""\xe2\x9c\x93"
fi

# define output directory for .hex files
export ARDUINO_HEX_DIR=arduino_build_$TRAVIS_BUILD_NUMBER

# link test library folder to the arduino libraries folder
ln -s $TRAVIS_BUILD_DIR $HOME/arduino_ide/libraries/Adafruit_Test_Library

# add the arduino CLI to our PATH
export PATH="$HOME/arduino_ide:$PATH"

echo -e "\n########################################################################";
echo -e "${YELLOW}INSTALLING DEPENDENCIES"
echo "########################################################################";

# install dependancy libraries in library.properties
grep "depends=" $HOME/arduino_ide/libraries/Adafruit_Test_Library/library.properties | sed 's/depends=//' | sed -n 1'p' |  tr ',' '\n' | while read word; do arduino --install-library "$word"; done

# install the zero, esp8266, and adafruit board packages
echo -n "ADD PACKAGE INDEX: "
DEPENDENCY_OUTPUT=$(arduino --pref "boardsmanager.additional.urls=https://adafruit.github.io/arduino-board-index/package_adafruit_index.json,http://arduino.esp8266.com/stable/package_esp8266com_index.json,https://dl.espressif.com/dl/package_esp32_index.json" --save-prefs 2>&1)
if [ $? -ne 0 ]; then echo -e """$RED""\xe2\x9c\x96"; else echo -e """$GREEN""\xe2\x9c\x93"; fi

# This is a hack, we have to install by hand so lets delete it
echo "Removing ESP32 cache"
rm -rf ~/.arduino15/packages/esp32
echo -n "Current packages list:"
[ -d ~/.arduino15/packages/ ] && ls ~/.arduino15/packages/

INSTALL_ESP32=$([[ $INSTALL_PLATFORMS == *"esp32"* || -z "$INSTALL_PLATFORMS" ]] && echo 1 || echo 0)
INSTALL_ZERO=$([[ $INSTALL_PLATFORMS == *"zero"* || -z "$INSTALL_PLATFORMS" ]] && echo 1 || echo 0)
INSTALL_ESP8266=$([[ $INSTALL_PLATFORMS == *"esp8266"* || -z "$INSTALL_PLATFORMS" ]] && echo 1 || echo 0)
INSTALL_AVR=$([[ $INSTALL_PLATFORMS == *"avr"* || -z "$INSTALL_PLATFORMS" ]] && echo 1 || echo 0)
INSTALL_SAMD=$([[ $INSTALL_PLATFORMS == *"samd"* || -z "$INSTALL_PLATFORMS" ]] && echo 1 || echo 0)
INSTALL_NRF52=$([[ $INSTALL_PLATFORMS == *"nrf52"* || -z "$INSTALL_PLATFORMS" ]] && echo 1 || echo 0)

if [[ $INSTALL_ESP32 == 1 ]]; then
  echo -n "ESP32: "
  DEPENDENCY_OUTPUT=$(arduino --install-boards esp32:esp32 2>&1)
  if [ $? -ne 0 ]; then echo -e "\xe2\x9c\x96 OR CACHED"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
fi

if [[ $INSTALL_ZERO == 1 ]]; then
  echo -n "ZERO: "
  DEPENDENCY_OUTPUT=$(arduino --install-boards arduino:samd 2>&1)
  if [ $? -ne 0 ]; then echo -e "\xe2\x9c\x96 OR CACHED"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
fi

if [[ $INSTALL_ESP8266 == 1 ]]; then
  echo -n "ESP8266: "
  DEPENDENCY_OUTPUT=$(arduino --install-boards esp8266:esp8266 2>&1)
  if [ $? -ne 0 ]; then echo -e "\xe2\x9c\x96 OR CACHED"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
fi

if [[ $INSTALL_AVR == 1 ]]; then
  echo -n "ADAFRUIT AVR: "
  DEPENDENCY_OUTPUT=$(arduino --install-boards adafruit:avr 2>&1)
  if [ $? -ne 0 ]; then echo -e "\xe2\x9c\x96 OR CACHED"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
fi

if [[ $INSTALL_SAMD == 1 ]]; then
  echo -n "ADAFRUIT SAMD: "
  DEPENDENCY_OUTPUT=$(arduino --install-boards adafruit:samd 2>&1)
  if [ $? -ne 0 ]; then echo -e "\xe2\x9c\x96 OR CACHED"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
fi

if [[ $INSTALL_NRF52 == 1 ]]; then
  echo -n "ADAFRUIT NRF5X: "
  pip3 install --user setuptools
  pip3 install --user adafruit-nrfutil
  pip3 install --user pyserial
  sudo pip3 install setuptools
  sudo pip3 install adafruit-nrfutil
  sudo pip3 install pyserial
  DEPENDENCY_OUTPUT=$(arduino --install-boards adafruit:nrf52 2>&1)
  if [ $? -ne 0 ]; then echo -e "\xe2\x9c\x96 OR CACHED"; else echo -e """$GREEN""\xe2\x9c\x93"; fi
fi

# install random lib so the arduino IDE grabs a new library index
# see: https://github.com/arduino/Arduino/issues/3535
echo -n "UPDATE LIBRARY INDEX: "
DEPENDENCY_OUTPUT=$(arduino --install-library USBHost > /dev/null 2>&1)
if [ $? -ne 0 ]; then echo -e """$RED""\xe2\x9c\x96"; else echo -e """$GREEN""\xe2\x9c\x93"; fi

# set the maximal compiler warning level
echo -n "SET BUILD PREFERENCES: "
DEPENDENCY_OUTPUT=$(arduino --pref "compiler.warning_level=all" --save-prefs 2>&1)
if [ $? -ne 0 ]; then echo -e """$RED""\xe2\x9c\x96"; else echo -e """$GREEN""\xe2\x9c\x93"; fi

# init the json temp var for the current platform
export PLATFORM_JSON=""

# init test stats counters
export PASS_COUNT=0
export SKIP_COUNT=0
export FAIL_COUNT=0
export PDE_COUNT=0
# close if [[ $# -eq 0 ]] ; then
fi 
# build all of the examples for the passed platform
#Sourcing and defining functions
function build_platform()
{

  # arrays can't be exported, so we have to eval
  eval $MAIN_PLATFORMS
  eval $AUX_PLATFORMS
  eval $CPLAY_PLATFORMS
  eval $M4_PLATFORMS
  eval $ARCADA_PLATFORMS
  eval $IO_PLATFORMS
  eval $NRF5X_PLATFORMS

  # reset platform json var
  PLATFORM_JSON=""

  # expects argument 1 to be the platform key
  local platform_key=$1

  # placeholder for platform
  local platform=""

  # track the exit code for this platform
  local exit_code=0

  # grab all pde and ino example sketches
  declare -a examples

  if [ "$PLATFORM_CHECK_ONLY_ON_FILE" = true ]; then
    # loop through results and add them to the array
    examples=($(
      for f in $(find . -type f -iname '*.ino' -o -iname '*.pde'); do
        # TODO: distinguish platforms
        if [ -e "$(dirname $f)/.$platform_key.test" ]; then
            echo "$f"
        fi
      done
    ))
  else
    # loop through results and add them to the array
    examples=($(find $PWD -name "*.pde" -o -name "*.ino"))
  fi

  # get the last example in the array
  local last="${examples[@]:(-1)}"

  # grab the platform info from array or bail if invalid
  if [[ ${main_platforms[$platform_key]} ]]; then
    platform=${main_platforms[$platform_key]}
  elif [[ ${aux_platforms[$platform_key]} ]]; then
    platform=${aux_platforms[$platform_key]}
  elif [[ ${cplay_platforms[$platform_key]} ]]; then
    platform=${cplay_platforms[$platform_key]}
  elif [[ ${m4_platforms[$platform_key]} ]]; then
    platform=${m4_platforms[$platform_key]}
  elif [[ ${arcada_platforms[$platform_key]} ]]; then
    platform=${arcada_platforms[$platform_key]}
  elif [[ ${io_platforms[$platform_key]} ]]; then
    platform=${io_platforms[$platform_key]}
  elif [[ ${nrf5x_platforms[$platform_key]} ]]; then
    platform=${nrf5x_platforms[$platform_key]}
  else
    echo "NON-STANDARD PLATFORM KEY: $platform_key"
    platform=$platform_key
  fi

  echo -e "\n########################################################################";

  echo -e -n "${YELLOW}SWITCHING TO ${platform_key}: "

  # switch to the requested board.
  # we have to avoid reading the exit code of local:
  # "when declaring a local variable in a function, the local acts as a command in its own right"
  local platform_stdout
  platform_stdout=$(arduino --board $platform --save-prefs 2>&1)

  # grab the exit status of the arduino board change
  local platform_switch=$?

  # notify if the platform switch failed
  if [ $platform_switch -ne 0 ]; then
    # heavy X
    echo -e """$RED""\xe2\x9c\x96"
    echo -e "arduino --board ${platform} --save-prefs 2>&1"
    echo $platform_stdout
    exit_code=1
  else
    # heavy checkmark
    echo -e """$GREEN""\xe2\x9c\x93"
  fi

  echo "########################################################################";

  # loop through example sketches
  for example in "${examples[@]}"; do

    # store the full path to the example's sketch directory
    local example_dir=$(dirname $example)

    # store the filename for the example without the path
    local example_file=$(basename $example)

    # is this the last example in the loop
    local last_example=0
    if [ "$last" == "$example" ]; then
      last_example=1
    fi

    echo -n "$example_file: "

    # continue to next example if platform switch failed
    if [ $platform_switch -ne 0 ]; then
      # heavy X
      echo -e """$RED""\xe2\x9c\x96"

      # add json
      PLATFORM_JSON="${PLATFORM_JSON}$(json_sketch 0 $example_file $last_example)"

      # increment fails
      FAIL_COUNT=$((FAIL_COUNT + 1))

      # mark fail
      exit_code=1

      continue

    fi

    # ignore this example if there is an all platform skip
    if [[ -f "${example_dir}/.test.skip" ]]; then

      # right arrow
      echo -e "\xe2\x9e\x9e"

      # add json
      PLATFORM_JSON="${PLATFORM_JSON}$(json_sketch -1 $example_file $last_example)"

      # increment skips
      SKIP_COUNT=$((SKIP_COUNT + 1))

      continue

    fi

    # ignore this example if there is a skip file preset for this specific platform
    if [[ -f "${example_dir}/.${platform_key}.test.skip" ]]; then

      # right arrow
      echo -e "\xe2\x9e\x9e"

      # add json
      PLATFORM_JSON="${PLATFORM_JSON}$(json_sketch -1 $example_file $last_example)"

      # increment skips
      SKIP_COUNT=$((SKIP_COUNT + 1))

      continue
    fi

    # make sure that all examples are .ino files
    if [[ $example =~ \.pde$ ]]; then

      # heavy X
      echo -e """$RED""\xe2\x9c\x96"

      echo -e "-------------------------- DEBUG OUTPUT --------------------------\n"
      echo "${LRED}PDE EXTENSION. PLEASE UPDATE TO INO"
      echo -e "\n------------------------------------------------------------------\n"

      # add json
      PLATFORM_JSON="${PLATFORM_JSON}$(json_sketch 0 $example_file $last_example)"

      # increment fails
      FAIL_COUNT=$((FAIL_COUNT + 1))

      # mark as fail
      exit_code=1

      continue

    fi

    # get the sketch name so we can place the generated files in the respective folder
    local sketch_filename_with_ending=$(basename -- "$example")
    local sketch_filename="${sketch_filename_with_ending%.*}"
    local build_path=$ARDUINO_HEX_DIR/$platform_key/$sketch_filename
    # verify the example, and save stdout & stderr to a variable
    # we have to avoid reading the exit code of local:
    # "when declaring a local variable in a function, the local acts as a command in its own right"
    local build_stdout
    build_stdout=$(arduino --verify --pref build.path=$build_path --preserve-temp-files $example 2>&1)

    # echo output if the build failed
    if [ $? -ne 0 ]; then

      # heavy X
      echo -e """$RED""\xe2\x9c\x96"

      echo -e "----------------------------- DEBUG OUTPUT -----------------------------\n"
      echo "$build_stdout"
      echo -e "\n------------------------------------------------------------------------\n"

      # add json
      PLATFORM_JSON="${PLATFORM_JSON}$(json_sketch 0 $example_file $last_example)"

      # increment fails
      FAIL_COUNT=$((FAIL_COUNT + 1))

      # mark as fail
      exit_code=1

    else

      # heavy checkmark
      echo -e """$GREEN""\xe2\x9c\x93"

      # add json
      PLATFORM_JSON="${PLATFORM_JSON}$(json_sketch 1 "$example_file" $last_example)"

      # increment passes
      PASS_COUNT=$((PASS_COUNT + 1))

    fi

  done

  return $exit_code

}

# build all examples for every platform in $MAIN_PLATFORMS
function build_main_platforms()
{

  # arrays can't be exported, so we have to eval
  eval $MAIN_PLATFORMS

  # track the build status all platforms
  local exit_code=0

  # var to hold platforms
  local platforms_json=""

  # get the last element in the array
  local last="${main_platforms[@]:(-1)}"

  # loop through platforms in main platforms assoc array
  for p_key in "${!main_platforms[@]}"; do

    # is this the last platform in the loop
    local last_platform=0
    if [ "$last" == "${main_platforms[$p_key]}" ]; then
      last_platform=1
    fi

    # build all examples for this platform
    build_platform $p_key

    # check if build failed
    if [ $? -ne 0 ]; then
      platforms_json="${platforms_json}$(json_platform $p_key 0 "$PLATFORM_JSON" $last_platform)"
      exit_code=1
    else
      platforms_json="${platforms_json}$(json_platform $p_key 1 "$PLATFORM_JSON" $last_platform)"
    fi

  done

  # exit code is opposite of json build status
  if [ $exit_code -eq 0 ]; then
    json_main_platforms 1 "$platforms_json"
  else
    json_main_platforms 0 "$platforms_json"
  fi

  return $exit_code

}

# build all examples for every platform in $AUX_PLATFORMS
function build_aux_platforms()
{

  # arrays can't be exported, so we have to eval
  eval $AUX_PLATFORMS

  # track the build status all platforms
  local exit_code=0

  # var to hold platforms
  local platforms_json=""

  # get the last element in the array
  local last="${aux_platforms[@]:(-1)}"

  # loop through platforms in main platforms assoc array
  for p_key in "${!aux_platforms[@]}"; do

    # is this the last platform in the loop
    local last_platform=0
    if [ "$last" == "${aux_platforms[$p_key]}" ]; then
      last_platform=1
    fi

    # build all examples for this platform
    build_platform $p_key

    # check if build failed
    if [ $? -ne 0 ]; then
      platforms_json="${platforms_json}$(json_platform $p_key 0 "$PLATFORM_JSON" $last_platform)"
      exit_code=1
    else
      platforms_json="${platforms_json}$(json_platform $p_key 1 "$PLATFORM_JSON" $last_platform)"
    fi

  done

  # exit code is opposite of json build status
  if [ $exit_code -eq 0 ]; then
    json_main_platforms 1 "$platforms_json"
  else
    json_main_platforms 0 "$platforms_json"
  fi

  return $exit_code

}
function build_cplay_platforms()
{

  # arrays can't be exported, so we have to eval
  eval $CPLAY_PLATFORMS

  # track the build status all platforms
  local exit_code=0

  # var to hold platforms
  local platforms_json=""

  # get the last element in the array
  local last="${cplay_platforms[@]:(-1)}"

  # loop through platforms in main platforms assoc array
  for p_key in "${!cplay_platforms[@]}"; do

    # is this the last platform in the loop
    local last_platform=0
    if [ "$last" == "${cplay_platforms[$p_key]}" ]; then
      last_platform=1
    fi

    # build all examples for this platform
    build_platform $p_key

    # check if build failed
    if [ $? -ne 0 ]; then
      platforms_json="${platforms_json}$(json_platform $p_key 0 "$PLATFORM_JSON" $last_platform)"
      exit_code=1
    else
      platforms_json="${platforms_json}$(json_platform $p_key 1 "$PLATFORM_JSON" $last_platform)"
    fi

  done

  # exit code is opposite of json build status
  if [ $exit_code -eq 0 ]; then
    json_main_platforms 1 "$platforms_json"
  else
    json_main_platforms 0 "$platforms_json"
  fi

  return $exit_code

}

function build_samd_platforms()
{

  # arrays can't be exported, so we have to eval
  eval $SAMD_PLATFORMS

  # track the build status all platforms
  local exit_code=0

  # var to hold platforms
  local platforms_json=""

  # get the last element in the array
  local last="${samd_platforms[@]:(-1)}"

  # loop through platforms in main platforms assoc array
  for p_key in "${!samd_platforms[@]}"; do

    # is this the last platform in the loop
    local last_platform=0
    if [ "$last" == "${samd_platforms[$p_key]}" ]; then
      last_platform=1
    fi

    # build all examples for this platform
    build_platform $p_key

    # check if build failed
    if [ $? -ne 0 ]; then
      platforms_json="${platforms_json}$(json_platform $p_key 0 "$PLATFORM_JSON" $last_platform)"
      exit_code=1
    else
      platforms_json="${platforms_json}$(json_platform $p_key 1 "$PLATFORM_JSON" $last_platform)"
    fi

  done

  # exit code is opposite of json build status
  if [ $exit_code -eq 0 ]; then
    json_main_platforms 1 "$platforms_json"
  else
    json_main_platforms 0 "$platforms_json"
  fi

  return $exit_code

}

function build_m4_platforms()
{

  # arrays can't be exported, so we have to eval
  eval $M4_PLATFORMS

  # track the build status all platforms
  local exit_code=0

  # var to hold platforms
  local platforms_json=""

  # get the last element in the array
  local last="${m4_platforms[@]:(-1)}"

  # loop through platforms in main platforms assoc array
  for p_key in "${!m4_platforms[@]}"; do

    # is this the last platform in the loop
    local last_platform=0
    if [ "$last" == "${m4_platforms[$p_key]}" ]; then
      last_platform=1
    fi

    # build all examples for this platform
    build_platform $p_key

    # check if build failed
    if [ $? -ne 0 ]; then
      platforms_json="${platforms_json}$(json_platform $p_key 0 "$PLATFORM_JSON" $last_platform)"
      exit_code=1
    else
      platforms_json="${platforms_json}$(json_platform $p_key 1 "$PLATFORM_JSON" $last_platform)"
    fi

  done

  # exit code is opposite of json build status
  if [ $exit_code -eq 0 ]; then
    json_main_platforms 1 "$platforms_json"
  else
    json_main_platforms 0 "$platforms_json"
  fi

  return $exit_code

}

function build_io_platforms()
{

  # arrays can't be exported, so we have to eval
  eval $IO_PLATFORMS

  # track the build status all platforms
  local exit_code=0

  # var to hold platforms
  local platforms_json=""

  # get the last element in the array
  local last="${io_platforms[@]:(-1)}"

  # loop through platforms in main platforms assoc array
  for p_key in "${!io_platforms[@]}"; do

    # is this the last platform in the loop
    local last_platform=0
    if [ "$last" == "${io_platforms[$p_key]}" ]; then
      last_platform=1
    fi

    # build all examples for this platform
    build_platform $p_key

    # check if build failed
    if [ $? -ne 0 ]; then
      platforms_json="${platforms_json}$(json_platform $p_key 0 "$PLATFORM_JSON" $last_platform)"
      exit_code=1
    else
      platforms_json="${platforms_json}$(json_platform $p_key 1 "$PLATFORM_JSON" $last_platform)"
    fi

  done

  # exit code is opposite of json build status
  if [ $exit_code -eq 0 ]; then
    json_main_platforms 1 "$platforms_json"
  else
    json_main_platforms 0 "$platforms_json"
  fi

  return $exit_code

}



function build_arcada_platforms()
{

  # arrays can't be exported, so we have to eval
  eval $ARCADA_PLATFORMS

  # track the build status all platforms
  local exit_code=0

  # var to hold platforms
  local platforms_json=""

  # get the last element in the array
  local last="${arcada_platforms[@]:(-1)}"

  # loop through platforms in main platforms assoc array
  for p_key in "${!arcada_platforms[@]}"; do

    # is this the last platform in the loop
    local last_platform=0
    if [ "$last" == "${arcada_platforms[$p_key]}" ]; then
      last_platform=1
    fi

    # build all examples for this platform
    build_platform $p_key

    # check if build failed
    if [ $? -ne 0 ]; then
      platforms_json="${platforms_json}$(json_platform $p_key 0 "$PLATFORM_JSON" $last_platform)"
      exit_code=1
    else
      platforms_json="${platforms_json}$(json_platform $p_key 1 "$PLATFORM_JSON" $last_platform)"
    fi

  done

  # exit code is opposite of json build status
  if [ $exit_code -eq 0 ]; then
    json_main_platforms 1 "$platforms_json"
  else
    json_main_platforms 0 "$platforms_json"
  fi

  return $exit_code

}


function build_nrf5x_platforms()
{

  # arrays can't be exported, so we have to eval
  eval $NRF5X_PLATFORMS

  # track the build status all platforms
  local exit_code=0

  # var to hold platforms
  local platforms_json=""

  # get the last element in the array
  local last="${nrf5x_platforms[@]:(-1)}"

  # loop through platforms in main platforms assoc array
  for p_key in "${!nrf5x_platforms[@]}"; do

    # is this the last platform in the loop
    local last_platform=0
    if [ "$last" == "${nrf5x_platforms[$p_key]}" ]; then
      last_platform=1
    fi

    # build all examples for this platform
    build_platform $p_key

    # check if build failed
    if [ $? -ne 0 ]; then
      platforms_json="${platforms_json}$(json_platform $p_key 0 "$PLATFORM_JSON" $last_platform)"
      exit_code=1
    else
      platforms_json="${platforms_json}$(json_platform $p_key 1 "$PLATFORM_JSON" $last_platform)"
    fi

  done

  # exit code is opposite of json build status
  if [ $exit_code -eq 0 ]; then
    json_main_platforms 1 "$platforms_json"
  else
    json_main_platforms 0 "$platforms_json"
  fi

  return $exit_code

}


# generate json string for a sketch
function json_sketch()
{

  # -1: skipped, 0: failed, 1: passed
  local status_number=$1

  # the filename of the sketch
  local sketch=$2

  # is this the last sketch for this platform? 0: no, 1: yes
  local last_sketch=$3

  # echo out the json
  echo -n "\"$sketch\": $status_number"

  # echo a comma unless this is the last sketch for the platform
  if [ $last_sketch -ne 1 ]; then
    echo -n ", "
  fi

}

# generate json string for a platform
function json_platform()
{

  # the platform key from main platforms or aux platforms
  local platform_key=$1

  # 0: failed, 1: passed
  local status_number=$2

  # the json string for the verified sketches
  local sketch_json=$3

  # is this the last platform we are building? 0: no, 1: yes
  local last_platform=$4

  echo -n "\"$platform_key\": { \"status\": $status_number, \"builds\": { $sketch_json } }"

  # echo a comma unless this is the last sketch for the platform
  if [ $last_platform -ne 1 ]; then
    echo -n ", "
  fi

}

# generate final json string
function json_main_platforms()
{

  # 0: failed, 1: passed
  local status_number=$1

  # the json string for the main platforms
  local platforms_json=$2

  local repo=$(git config --get remote.origin.url)

  echo -e "\n||||||||||||||||||||||||||||| JSON STATUS ||||||||||||||||||||||||||||||"

  echo -n "{ \"repo\": \"$repo\", "
  echo -n "\"status\": $status_number, "
  echo -n "\"passed\": $PASS_COUNT, "
  echo -n "\"skipped\": $SKIP_COUNT, "
  echo -n "\"failed\": $FAIL_COUNT, "
  echo "\"platforms\": { $platforms_json } }"

  echo -e "||||||||||||||||||||||||||||| JSON STATUS ||||||||||||||||||||||||||||||\n"

}
#If there is an argument
if [[ ! $# -eq 0 ]] ; then
# define output directory for .hex files
export ARDUINO_HEX_DIR=arduino_build_$TRAVIS_BUILD_NUMBER

# link test library folder to the arduino libraries folder
ln -s $TRAVIS_BUILD_DIR $HOME/arduino_ide/libraries/Adafruit_Test_Library

# add the arduino CLI to our PATH
export PATH="$HOME/arduino_ide:$PATH"

"$@"
fi