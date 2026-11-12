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

const uint8_t DXL0 = 6;
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

// EWMA filtering
const float EWMA_ALPHA = 0.1;  // smoothing factor
float ewma_state[3] = {0.0, 0.0, 0.0};  // one per motor

// constants for mapping filtered error -> gains
const float KP_FROM_ERROR = 50.0;  // how strongly P increases per degree of filtered error
const float KI_FROM_ERROR = 10.0;  // how strongly I increases per degree of filtered error
const int P_MIN = 100;
const int P_MAX = 2200;
const int I_MIN = 0;
const int I_MAX = 800;

// nominal (unchanging) base gains
const int NOMINAL_P[3] = {1000, 1000, 1000};
const int NOMINAL_I[3] = {70, 70, 70};

// per-motor temp gains and ticks
int temp_p_gain[3] = {NOMINAL_P[0], NOMINAL_P[1], NOMINAL_P[2]};
int temp_i_gain[3] = {NOMINAL_I[0], NOMINAL_I[1], NOMINAL_I[2]};
int tick[3] = {1, 1, 1};
int tick_default_limit = 30;  // timeout ticks

void setup() {
  Serial.begin(115200);  // For communication with Processing
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
  
  // set nominal gains initially
  writeGains();
  
  dxl.torqueOn(DXL0);
  dxl.torqueOn(DXL1);
  dxl.torqueOn(DXL2);
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

  // check if reached and adaptively adjust gains
  if (targetReached()) {
    Serial.println("stable");
  }

  // check for new serial commands
  receiveDataFromProcessing();
}

// ================== TARGET CHECK WITH ADAPTIVE GAINS ==================
bool targetReached() {
  // read current positions
  float cur0 = dxl.getPresentPosition(DXL0, UNIT_DEGREE);
  float cur1 = dxl.getPresentPosition(DXL1, UNIT_DEGREE);
  float cur2 = dxl.getPresentPosition(DXL2, UNIT_DEGREE);
  
  // compute absolute errors
  float error0 = abs(cur0 - target0);
  float error1 = abs(cur1 - target1);
  float error2 = abs(cur2 - target2);

  // Update EWMA state for each motor
  ewma_state[0] = EWMA_ALPHA * error0 + (1.0 - EWMA_ALPHA) * ewma_state[0];
  ewma_state[1] = EWMA_ALPHA * error1 + (1.0 - EWMA_ALPHA) * ewma_state[1];
  ewma_state[2] = EWMA_ALPHA * error2 + (1.0 - EWMA_ALPHA) * ewma_state[2];

  DEBUG_SERIAL.print(error0); DEBUG_SERIAL.print("\t");
  DEBUG_SERIAL.print(error1); DEBUG_SERIAL.print("\t");
  DEBUG_SERIAL.print(error2); DEBUG_SERIAL.print("\n");

  // check if all motors within tolerance
  if (error0 < tolerance && error1 < tolerance && error2 < tolerance) {
    // compute baseline gains from filtered errors
    temp_p_gain[0] = computePfromError(ewma_state[0], NOMINAL_P[0]);
    temp_i_gain[0] = computeIfromError(ewma_state[0], NOMINAL_I[0]);
    temp_p_gain[1] = computePfromError(ewma_state[1], NOMINAL_P[1]);
    temp_i_gain[1] = computeIfromError(ewma_state[1], NOMINAL_I[1]);
    temp_p_gain[2] = computePfromError(ewma_state[2], NOMINAL_P[2]);
    temp_i_gain[2] = computeIfromError(ewma_state[2], NOMINAL_I[2]);
    
    // reset ticks
    for (int m = 0; m < 3; m++) {
      tick[m] = 1;
    }
    
    writeGains();
    return true;
  } 
  else {
    // Not all motors reached - update gains per motor based on that motor's error
    if (error0 >= tolerance) {
      temp_p_gain[0] += 20;
      temp_i_gain[0] += 10;
      tick[0]++;
      if (temp_p_gain[0] > P_MAX) temp_p_gain[0] = NOMINAL_P[0];
      if (temp_i_gain[0] > I_MAX) temp_i_gain[0] = NOMINAL_I[0];
    } else {
      temp_p_gain[0] = max(temp_p_gain[0], NOMINAL_P[0]);
    }
    
    if (error1 >= tolerance) {
      temp_p_gain[1] += 20;
      temp_i_gain[1] += 10;
      tick[1]++;
      if (temp_p_gain[1] > P_MAX) temp_p_gain[1] = NOMINAL_P[1];
      if (temp_i_gain[1] > I_MAX) temp_i_gain[1] = NOMINAL_I[1];
    } else {
      temp_p_gain[1] = max(temp_p_gain[1], NOMINAL_P[1]);
    }
    
    if (error2 >= tolerance) {
      temp_p_gain[2] += 20;
      temp_i_gain[2] += 10;
      tick[2]++;
      if (temp_p_gain[2] > P_MAX) temp_p_gain[2] = NOMINAL_P[2];
      if (temp_i_gain[2] > I_MAX) temp_i_gain[2] = NOMINAL_I[2];
    } else {
      temp_p_gain[2] = max(temp_p_gain[2], NOMINAL_P[2]);
    }
    
    // check for timeout on any motor
    bool anyTimeout = false;
    for (int m = 0; m < 3; m++) {
      if (tick[m] > tick_default_limit) {
        tick[m] = 1;
        temp_p_gain[m] = NOMINAL_P[m];
        temp_i_gain[m] = NOMINAL_I[m];
        anyTimeout = true;
      }
    }
    
    writeGains();
    
    if (anyTimeout) {
      return true;  // treat timeout as "reached" to avoid getting stuck
    }
    return false;
  }
}

// compute P from filtered error (linear map from a fixed nominal base)
int computePfromError(float filteredError, int nominalP) {
  float candidate = nominalP + KP_FROM_ERROR * filteredError;
  if (candidate < P_MIN) candidate = P_MIN;
  if (candidate > P_MAX) candidate = P_MAX;
  return (int)candidate;
}

// compute I from filtered error (linear map from a fixed nominal base)
int computeIfromError(float filteredError, int nominalI) {
  float candidate = nominalI + KI_FROM_ERROR * filteredError;
  if (candidate < I_MIN) candidate = I_MIN;
  if (candidate > I_MAX) candidate = I_MAX;
  return (int)candidate;
}

void writeGains() {
  // write per-motor gains
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL0, temp_p_gain[0]);
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL1, temp_p_gain[1]);
  dxl.writeControlTableItem(POSITION_P_GAIN, DXL2, temp_p_gain[2]);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL0, temp_i_gain[0]);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL1, temp_i_gain[1]);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL2, temp_i_gain[2]);
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