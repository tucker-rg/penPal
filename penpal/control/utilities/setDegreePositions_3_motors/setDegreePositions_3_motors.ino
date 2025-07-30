/*******************************************************************************
* Copyright 2016 ROBOTIS CO., LTD.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*******************************************************************************/

#include <DynamixelShield.h>

#if defined(ARDUINO_AVR_UNO) || defined(ARDUINO_AVR_MEGA2560)
  #include <SoftwareSerial.h>
  SoftwareSerial soft_serial(7, 8); // DYNAMIXELShield UART RX/TX
  #define DEBUG_SERIAL soft_serial
#elif defined(ARDUINO_SAM_DUE) || defined(ARDUINO_SAM_ZERO)
  #define DEBUG_SERIAL SerialUSB    
#else
  #define DEBUG_SERIAL Serial
#endif

const uint8_t DXL1 = 1;
const uint8_t DXL2 = 4;
const uint8_t DXL3 = 7;
const float DXL_PROTOCOL_VERSION = 2.0;
float target1;
float target2;
float target3;
float tolerance = 0.5;

int tick = 1;
int default_p_gain = 1000;
int temp_p_gain = 1000;
int default_i_gain = 120;
int temp_i_gain = default_i_gain;
int default_d_gain = 400;
int counter = 0;
bool startFlag = false;

DynamixelShield dxl;

//This namespace is required to use Control table item names
using namespace ControlTableItem;

void setup() {
  // put your setup code here, to run once:
  
  // For Uno, Nano, Mini, and Mega, use UART port of DYNAMIXEL Shield to debug.
  DEBUG_SERIAL.begin(115200);

  // Set Port baudrate to 57600bps. This has to match with DYNAMIXEL baudrate.
  dxl.begin(1000000);
  // Set Port Protocol Version. This has to match with DYNAMIXEL protocol version.
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);
  // Get DYNAMIXEL information
  dxl.ping(DXL1);
  dxl.ping(DXL2);
  dxl.ping(DXL3);

  // Turn off torque when configuring items in EEPROM area
  dxl.torqueOff(DXL1);
  dxl.torqueOff(DXL2);
  dxl.torqueOff(DXL3);
  dxl.setOperatingMode(DXL1, OP_POSITION);
  dxl.setOperatingMode(DXL2, OP_POSITION);
  dxl.setOperatingMode(DXL3, OP_POSITION);
  dxl.torqueOn(DXL1);
  dxl.torqueOn(DXL2);
  dxl.torqueOn(DXL3);
  target1 = 50.0;
  target2 = 50.0;
  target3 = 50.0;
  dxl.setGoalPosition(DXL1, target1, UNIT_DEGREE);
  dxl.setGoalPosition(DXL2, target2, UNIT_DEGREE);
  dxl.setGoalPosition(DXL3, target3, UNIT_DEGREE);
}

void loop() {
  if (targetReached()){
    Serial.println("stable");
  }
}

bool targetReached(){
  float error0 = abs(dxl.getPresentPosition(DXL1, UNIT_DEGREE) - target1);
  float error1 = abs(dxl.getPresentPosition(DXL2, UNIT_DEGREE) - target2);
  float error2 = abs(dxl.getPresentPosition(DXL3, UNIT_DEGREE) - target3);

  DEBUG_SERIAL.print(error0); DEBUG_SERIAL.print("\t");
  DEBUG_SERIAL.print(error1); DEBUG_SERIAL.print("\t");
  DEBUG_SERIAL.print(error2); DEBUG_SERIAL.print("\n");
  if(abs(error0) < tolerance && abs(error1) < tolerance && abs(error2) < tolerance){
    resetDefaults();
    return true;
  }
  else{
    // DEBUG_SERIAL.print("p_gain: "); DEBUG_SERIAL.print(temp_p_gain);
    // DEBUG_SERIAL.print("\ti_gain: "); DEBUG_SERIAL.println(temp_i_gain);
    temp_p_gain += 100;
    temp_i_gain += 20;
    if (temp_p_gain > 2200){temp_p_gain = default_p_gain;}
    if (temp_i_gain > 800){temp_i_gain = default_i_gain;}
    tick++;
    if (tick > 30){
      resetDefaults();
      return true;
    }
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL1, temp_p_gain);
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL2, temp_p_gain);
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL3, temp_p_gain);
    dxl.writeControlTableItem(POSITION_I_GAIN, DXL1, temp_i_gain);
    dxl.writeControlTableItem(POSITION_I_GAIN, DXL2, temp_i_gain);
    dxl.writeControlTableItem(POSITION_I_GAIN, DXL3, temp_i_gain);
    return false;
  }
}

void resetDefaults(){
  temp_p_gain = default_p_gain;
  temp_i_gain = default_i_gain;
  tick = 1;
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL1, default_p_gain);
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL2, default_p_gain);
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL3, default_p_gain);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL1, temp_i_gain);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL2, temp_i_gain);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL3, temp_i_gain);
}
