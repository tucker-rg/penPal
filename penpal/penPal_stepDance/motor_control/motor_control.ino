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

const uint8_t DXL0 = 4;
const uint8_t DXL1 = 7;
const uint8_t DXL2 = 6;
const float DXL_PROTOCOL_VERSION = 2.0;
DynamixelShield dxl;

using namespace ControlTableItem;

unsigned long lastReceivedTimer;
unsigned long INTERVAL = 10;

float input_0 = 0.0;
float input_1 = 0.0;
float input_2 = 0.0;

void setup() {
  Serial.begin(115200);
  dxl.begin(1000000);
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);

  while (!Serial) delay(10);
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
}

void loop() {
  unsigned long now = millis();

  if (now - lastReceivedTimer >= INTERVAL) {
    lastReceivedTimer = now;
    dxl.setGoalPosition(DXL0, input_0, UNIT_DEGREE);
    dxl.setGoalPosition(DXL1, input_1, UNIT_DEGREE);
    dxl.setGoalPosition(DXL2, input_2, UNIT_DEGREE);
  }

  receiveDataFromProcessing();
}

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
    input_0 = data.substring(index0 + 2, index1 - 1).toFloat();
    input_1 = data.substring(index1 + 2, index2 - 1).toFloat();
    input_2 = data.substring(index2 + 2).toFloat();
  }
}
