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

const uint8_t DXL_ID = 5;
const float DXL_PROTOCOL_VERSION = 2.0;

DynamixelShield dxl;

//This namespace is required to use Control table item names
using namespace ControlTableItem;

void setup() {
  // put your setup code here, to run once:
  
  // For Uno, Nano, Mini, and Mega, use UART port of DYNAMIXEL Shield to debug.
  DEBUG_SERIAL.begin(115200);

  // Set Port baudrate to 57600bps. This has to match with DYNAMIXEL baudrate.
  dxl.begin(57600);
  // Set Port Protocol Version. This has to match with DYNAMIXEL protocol version.
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);
  // Get DYNAMIXEL information
  dxl.ping(DXL_ID);

  // Turn off torque when configuring items in EEPROM area
  dxl.torqueOff(DXL_ID);
  dxl.setOperatingMode(DXL_ID, OP_POSITION);
  // dxl.torqueOn(DXL_ID);

  // POSITION_P_GAIN,
  // POSITION_I_GAIN,
  // POSITION_D_GAIN,
  // FEEDFORWARD_1ST_GAIN,
  // FEEDFORWARD_2ND_GAIN,
  // P_GAIN,
  // I_GAIN,
  // D_GAIN,

  
}

void loop() {
  DEBUG_SERIAL.println("motor 1:");
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_P_GAIN, 1));
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_I_GAIN, 1));
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_D_GAIN, 1));
  DEBUG_SERIAL.println(dxl.readControlTableItem(FEEDFORWARD_1ST_GAIN, 1));
  DEBUG_SERIAL.println(dxl.readControlTableItem(FEEDFORWARD_2ND_GAIN, 1));
  DEBUG_SERIAL.println(dxl.readControlTableItem(P_GAIN, 1));
  DEBUG_SERIAL.println(dxl.readControlTableItem(I_GAIN, 1));
  DEBUG_SERIAL.println(dxl.readControlTableItem(D_GAIN, 1));
  delay(2000);  // Give motor time to reach

  DEBUG_SERIAL.println("motor 4:");
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_P_GAIN, 4));
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_I_GAIN, 4));
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_D_GAIN, 4));
  DEBUG_SERIAL.println(dxl.readControlTableItem(FEEDFORWARD_1ST_GAIN, 4));
  DEBUG_SERIAL.println(dxl.readControlTableItem(FEEDFORWARD_2ND_GAIN, 4));
  DEBUG_SERIAL.println(dxl.readControlTableItem(P_GAIN, 4));
  DEBUG_SERIAL.println(dxl.readControlTableItem(I_GAIN, 4));
  DEBUG_SERIAL.println(dxl.readControlTableItem(D_GAIN, 4));
  delay(2000);  // Give motor time to reach

  DEBUG_SERIAL.println("motor 5:");
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_P_GAIN, 5));
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_I_GAIN, 5));
  DEBUG_SERIAL.println(dxl.readControlTableItem(POSITION_D_GAIN, 5));
  DEBUG_SERIAL.println(dxl.readControlTableItem(FEEDFORWARD_1ST_GAIN, 5));
  DEBUG_SERIAL.println(dxl.readControlTableItem(FEEDFORWARD_2ND_GAIN, 5));
  DEBUG_SERIAL.println(dxl.readControlTableItem(P_GAIN, 5));
  DEBUG_SERIAL.println(dxl.readControlTableItem(I_GAIN, 5));
  DEBUG_SERIAL.println(dxl.readControlTableItem(D_GAIN, 5));
  delay(10000);  // Give motor time to reach

  // Move to 10 degrees
  // dxl.setGoalPosition(DXL_ID, 30.0, UNIT_DEGREE);

  // DEBUG_SERIAL.print("Present Position (deg): ");
  // DEBUG_SERIAL.println(dxl.getPresentPosition(DXL_ID, UNIT_DEGREE));

  // Move to 310 degrees
  // dxl.setGoalPosition(DXL_ID, 10.0, UNIT_DEGREE);
  // delay(2000);

  // DEBUG_SERIAL.print("Present Position (deg): ");
  // DEBUG_SERIAL.println(dxl.getPresentPosition(DXL_ID, UNIT_DEGREE));
}
