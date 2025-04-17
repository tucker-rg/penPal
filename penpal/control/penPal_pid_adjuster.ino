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


const uint8_t DXL0 = 1;
const uint8_t DXL1 = 4;
const uint8_t DXL2 = 7;
const uint32_t DXL_BAUDRATE = 57600;
const float DXL_PROTOCOL_VERSION = 2.0;
int count = 0;

float goal_position[27] = {60,61,62,63,64,65,66,67,68,69,70,73,76,79,76,73,70,76,82,88,82,76,70,120,70,120,70};
float wave[16] = {60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75};
float wave1[16] = {60,62,64,66,68,70,72,74,76,78,80,82,84,86,88,90};
int8_t direction = 0;
unsigned long timer = 0;
// Position PID Gains
// Adjust these gains to tune the behavior of DYNAMIXEL

//default:
// uint16_t p_gains[3] = {400,400,400};
// uint16_t i_gains[3] = {0,0,0};
// uint16_t d_gains[3] = {0,0,0};
//for M077:
// uint16_t p_gains[3] = {670,400,400};
// uint16_t i_gains[3] = {50,0,0};
// uint16_t d_gains[3] = {400,0,0};
uint16_t p_gains[3] = {1500,400,400};
uint16_t i_gains[3] = {80,0,0};
uint16_t d_gains[3] = {500,0,0};
//for M288:
// uint16_t p_gains[3] = {650,650,650};
// uint16_t i_gains[3] = {80,80,80};
// uint16_t d_gains[3] = {600,600,600};
unsigned long controlTimer;
unsigned long lastTimer;
unsigned long INTERVAL = 1;
DynamixelShield dxl;

//This namespace is required to use Control table item names
using namespace ControlTableItem;

void setup() {
  // put your setup code here, to run once:
  // For Uno, Nano, Mini, and Mega, use the UART port of the DYNAMIXEL Shield to read debugging messages.
  DEBUG_SERIAL.begin(57600);
  while(!DEBUG_SERIAL);

  // Set Port baudrate to 57600bps. This has to match with DYNAMIXEL baudrate.
  dxl.begin(DXL_BAUDRATE);
  // Set Port Protocol Version. This has to match with DYNAMIXEL protocol version.
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);
  // Get DYNAMIXEL information
  dxl.ping(DXL0);
  dxl.ping(DXL1);
  dxl.ping(DXL2);

  // Turn off torque when configuring items in EEPROM area
  dxl.torqueOff(DXL0);
  dxl.torqueOff(DXL1);
  dxl.torqueOff(DXL2);
  dxl.setOperatingMode(DXL0, OP_POSITION);
  dxl.setOperatingMode(DXL1, OP_POSITION);
  dxl.setOperatingMode(DXL2, OP_POSITION);
  dxl.torqueOn(DXL0);
  dxl.torqueOn(DXL1);
  dxl.torqueOn(DXL2);
  
  // Set Position PID Gains
  writeGains();
}

void loop() {
  // put your main code here, to run repeatedly:
  // Read Present Position (Use the Serial Plotter)
  while(true) {
    controlTimer = millis();
    if (controlTimer - lastTimer >= INTERVAL){
      lastTimer = controlTimer;
      // DEBUG_SERIAL.print("error_0:");
      // DEBUG_SERIAL.print(dxl.readControlTableItem(GOAL_POSITION, DXL0)-dxl.getPresentPosition(DXL0));
      // DEBUG_SERIAL.print(",");
      // DEBUG_SERIAL.print("error_1:");
      // DEBUG_SERIAL.print(dxl.readControlTableItem(GOAL_POSITION, DXL1)-dxl.getPresentPosition(DXL1));
      // DEBUG_SERIAL.print(",");
      // DEBUG_SERIAL.print("error_2:");
      // DEBUG_SERIAL.print(dxl.readControlTableItem(GOAL_POSITION, DXL2)-dxl.getPresentPosition(DXL2));
      DEBUG_SERIAL.print("goal_0:");
      DEBUG_SERIAL.print(dxl.readControlTableItem(GOAL_POSITION, DXL0));
      DEBUG_SERIAL.print(",");
      DEBUG_SERIAL.print("pos_0:");
      DEBUG_SERIAL.print(dxl.getPresentPosition(DXL0));
      // DEBUG_SERIAL.print(",");
      // DEBUG_SERIAL.print("goal_1:");
      // DEBUG_SERIAL.print(dxl.readControlTableItem(GOAL_POSITION, DXL1));
      // DEBUG_SERIAL.print(",");
      // DEBUG_SERIAL.print("pos_1:");
      // DEBUG_SERIAL.print(dxl.getPresentPosition(DXL1));
      // DEBUG_SERIAL.print(",");
      // DEBUG_SERIAL.print("goal_2:");
      // DEBUG_SERIAL.print(dxl.readControlTableItem(GOAL_POSITION, DXL2));
      // DEBUG_SERIAL.print(",");
      // DEBUG_SERIAL.print("pos_2:");
      // DEBUG_SERIAL.print(dxl.getPresentPosition(DXL2));
      DEBUG_SERIAL.print(",");
      DEBUG_SERIAL.print("min:");
      DEBUG_SERIAL.print(600);
      DEBUG_SERIAL.print(",");
      DEBUG_SERIAL.print("max:");
      DEBUG_SERIAL.print(1400);
      DEBUG_SERIAL.println();
    }
    // if (millis() - timer >= 50){
    //   dxl.setGoalPosition(DXL0, wave[count], UNIT_DEGREE);
    //   timer = millis();
    //   count++;
    //   if (count>15){count=0;}
    // }
    if (millis() - timer >= 50){
      tunePID();
      dxl.setGoalPosition(DXL0, goal_position[count], UNIT_DEGREE);
      timer = millis();
      count++;
      if (count>26){count=0;}
    }
  }
  
  //   if (millis() - timer >= 2000) {
  //     dxl.setGoalPosition(DXL0, goal_position[direction], UNIT_DEGREE);
  //     dxl.setGoalPosition(DXL1, goal_position[direction], UNIT_DEGREE);
  //     dxl.setGoalPosition(DXL2, goal_position[direction]+4.0, UNIT_DEGREE);
  //     timer = millis();
  //     break;
  //   }
  // }

  // if(direction >= 1) {
  //   direction = 0;
  // } else {
  //   direction = 1;
  // }
}

void tunePID(){
  if (abs(goal_position[count-1]-goal_position[count])>5.0){
    p_gains[0] = 670;
    p_gains[1] = 400;
    p_gains[2] = 400;
    i_gains[0] = 50;
    i_gains[1] = 0;
    i_gains[1] = 0;
    d_gains[0] = 400;
    d_gains[1] = 0;
    d_gains[2] = 0;
  } else{
    p_gains[0] = 1800;
    p_gains[1] = 400;
    p_gains[2] = 400;
    i_gains[0] = 80;
    i_gains[1] = 0;
    i_gains[1] = 0;
    d_gains[0] = 500;
    d_gains[1] = 0;
    d_gains[2] = 0;
  }
  writeGains();
}

void writeGains(){
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL0, p_gains[0]);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL0, i_gains[0]);
  dxl.writeControlTableItem(POSITION_D_GAIN, DXL0, d_gains[0]);
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL1, p_gains[1]);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL1, i_gains[1]);
  dxl.writeControlTableItem(POSITION_D_GAIN, DXL1, d_gains[1]);
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL2, p_gains[2]);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL2, i_gains[2]);
  dxl.writeControlTableItem(POSITION_D_GAIN, DXL2, d_gains[2]);
}