#include <DynamixelShield.h>
#include <Bounce2.h>

#if defined(ARDUINO_AVR_UNO) || defined(ARDUINO_AVR_MEGA2560)
  #include <SoftwareSerial.h>
  SoftwareSerial soft_serial(7, 8);
  #define DEBUG_SERIAL soft_serial
#elif defined(ARDUINO_SAM_DUE) || defined(ARDUINO_SAM_ZERO)
  #define DEBUG_SERIAL SerialUSB    
#else
  #define DEBUG_SERIAL Serial
#endif

Bounce bounce = Bounce();

const uint8_t DXL0 = 1;
const uint8_t DXL1 = 4;
const uint8_t DXL2 = 7;
const float DXL_PROTOCOL_VERSION = 2.0;
DynamixelShield dxl;

using namespace ControlTableItem;

// timing
unsigned long controlTimer;
unsigned long lastReceivedTimer;
unsigned long INTERVAL = 10;

// targets from Processing
float target0 = 0.0;
float target1 = 0.0;
float target2 = 0.0;
float tolerance = 0.5;

// PID auto-adjust variables
int default_p_gain = 1000;
int temp_p_gain = default_p_gain;
int default_i_gain = 120;
int temp_i_gain = default_i_gain;
int tick = 1;

void setup() {
  Serial.begin(57600);  // For communication with Processing
  dxl.begin(1000000);
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);

  Serial.println("You're connected to the pen");

  dxl.ping(DXL0);
  dxl.ping(DXL1);
  dxl.ping(DXL2);

  dxl.torqueOff(DXL0);
  dxl.torqueOff(DXL1);
  dxl.torqueOff(DXL2);
  dxl.setOperatingMode(DXL0, OP_POSITION);
  dxl.setOperatingMode(DXL1, OP_POSITION);
  dxl.setOperatingMode(DXL2, OP_POSITION);
  dxl.torqueOn(DXL0);
  dxl.torqueOn(DXL1);
  dxl.torqueOn(DXL2);

  // set default gains initially
  resetDefaults();
}

void loop() {
  controlTimer = millis();
  
  // update motor goals periodically
  if (controlTimer - lastReceivedTimer > INTERVAL) {
    lastReceivedTimer = controlTimer;
    dxl.setGoalPosition(DXL0, target0, UNIT_DEGREE);
    dxl.setGoalPosition(DXL1, target1, UNIT_DEGREE);
    dxl.setGoalPosition(DXL2, target2, UNIT_DEGREE);
  }

  // check if reached
  if (targetReached()) {
    Serial.println("stable");
  }

  // check for new serial commands
  receiveDataFromProcessing();
}

// ================== TARGET CHECK ==================
bool targetReached() {
  float error0 = abs(dxl.getPresentPosition(DXL0, UNIT_DEGREE) - target0);
  float error1 = abs(dxl.getPresentPosition(DXL1, UNIT_DEGREE) - target1);
  float error2 = abs(dxl.getPresentPosition(DXL2, UNIT_DEGREE) - target2);

  DEBUG_SERIAL.print(error0); DEBUG_SERIAL.print("\t");
  DEBUG_SERIAL.print(error1); DEBUG_SERIAL.print("\t");
  DEBUG_SERIAL.print(error2); DEBUG_SERIAL.print("\n");

  if (error0 < tolerance && error1 < tolerance && error2 < tolerance) {
    resetDefaults();
    return true;
  } else {
    // adaptive gain bump
    temp_p_gain += 100;
    temp_i_gain += 20;
    if (temp_p_gain > 2200) temp_p_gain = default_p_gain;
    if (temp_i_gain > 800) temp_i_gain = default_i_gain;
    tick++;
    if (tick > 30) {  // timeout safeguard
      resetDefaults();
      return true;
    }
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL0, temp_p_gain);
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL1, temp_p_gain);
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL2, temp_p_gain);
    dxl.writeControlTableItem(POSITION_I_GAIN, DXL0, temp_i_gain);
    dxl.writeControlTableItem(POSITION_I_GAIN, DXL1, temp_i_gain);
    dxl.writeControlTableItem(POSITION_I_GAIN, DXL2, temp_i_gain);
    return false;
  }
}

void resetDefaults() {
  temp_p_gain = default_p_gain;
  temp_i_gain = default_i_gain;
  tick = 1;
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL0, default_p_gain);
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL1, default_p_gain);
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL2, default_p_gain);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL0, default_i_gain);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL1, default_i_gain);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL2, default_i_gain);
}

// ================== SERIAL PARSING ==================
void receiveDataFromProcessing() {
  if (Serial.available() > 0) {
    String receivedData = Serial.readStringUntil('\n');
    parseReceivedData(receivedData);
  }
}

void parseReceivedData(String data) {
  int index0 = data.indexOf("0:");
  int index1 = data.indexOf("1:");
  int index2 = data.indexOf("2:");

  if (index0 != -1 && index1 != -1 && index2 != -1) {
    target0 = data.substring(index0 + 2, index1 - 1).toFloat();
    target1 = data.substring(index1 + 2, index2 - 1).toFloat();
    target2 = data.substring(index2 + 2).toFloat();
  }
}
