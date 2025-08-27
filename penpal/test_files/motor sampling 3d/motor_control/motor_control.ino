#include <DynamixelShield.h>

#if defined(ARDUINO_AVR_UNO) || defined(ARDUINO_AVR_MEGA2560)
  #include <SoftwareSerial.h>
  SoftwareSerial soft_serial(7, 8);
  #define DEBUG_SERIAL soft_serial
#elif defined(ARDUINO_SAM_DUE) || defined(ARDUINO_SAM_ZERO)
  #define DEBUG_SERIAL SerialUSB
#else
  #define DEBUG_SERIAL Serial
#endif

using namespace ControlTableItem;

DynamixelShield dxl;

const uint8_t DXL_IDS[] = {1, 4, 7};
const int NUM = sizeof(DXL_IDS)/sizeof(DXL_IDS[0]);
const float PROTOCOL = 2.0;

// ===== Assist parameters (tune to taste) =====
const unsigned long DT_MS     = 10;   // loop period
const float DEAD_BAND_DPS     = 2.0;  // ignore tiny hand motion (deg/s)
const float VEL_GAIN          = 1.5;  // multiply sensed hand speed
const float MAX_RPM           = 60.0; // cap commanded speed
const float FRICTION_KICK_RPM = 5.0;  // small offset to break static friction
const float SOFT_STOP_MIN_DEG = 10; // set real limits if you have them
const float SOFT_STOP_MAX_DEG =  300;
// ============================================

// State
float lastPosDeg[NUM] = {0,0,0};
unsigned long lastT = 0;

void setup() {
  Serial.begin(57600);
  dxl.begin(1000000);
  dxl.setPortProtocolVersion(PROTOCOL);

  for (int i=0;i<NUM;i++) {
    dxl.ping(DXL_IDS[i]);
    // Velocity mode so we can drive in the direction you push
    dxl.setOperatingMode(DXL_IDS[i], OP_VELOCITY);
    dxl.torqueOn(DXL_IDS[i]);
    lastPosDeg[i] = dxl.getPresentPosition(DXL_IDS[i], UNIT_DEGREE);
  }

  Serial.println("Power-assist teach mode: push lightly, motors follow. 'X' to stop.");
  lastT = millis();

  dxl.setGoalPosition(DXL0, 50, UNIT_DEGREE);
  dxl.setGoalPosition(DXL1, 50, UNIT_DEGREE);
  dxl.setGoalPosition(DXL2, 50, UNIT_DEGREE);
}

void loop() {
  // Emergency stop from host
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 'X' || c == 'x') {
      for (int i=0;i<NUM;i++) dxl.setGoalVelocity(DXL_IDS[i], 0.0, UNIT_RPM);
      Serial.println("E-STOP: velocity = 0");
    }
  }

  unsigned long now = millis();
  if (now - lastT < DT_MS) return;
  float dt = (now - lastT) / 1000.0f;
  lastT = now;

  for (int k=0;k<NUM;k++) {
    uint8_t id = DXL_IDS[k];

    // Read present position (deg) and estimate hand-induced speed
    float posDeg = dxl.getPresentPosition(id, UNIT_DEGREE);
    float dpos   = posDeg - lastPosDeg[k];
    float vel_dps = dpos / dt; // deg/s from your push
    lastPosDeg[k] = posDeg;

    // Soft limits (optional)
    if (posDeg <= SOFT_STOP_MIN_DEG + 1) vel_dps = max(0.0f, vel_dps);
    if (posDeg >= SOFT_STOP_MAX_DEG - 1) vel_dps = min(0.0f, vel_dps);

    // Deadband: ignore tiny motion
    float cmd_rpm = 0.0;
    if (fabs(vel_dps) > DEAD_BAND_DPS) {
      // Convert deg/s -> RPM: deg/s * (1 rev / 360 deg) * 60 s/min
      float sensed_rpm = vel_dps * (60.0f / 360.0f);
      cmd_rpm = VEL_GAIN * sensed_rpm;

      // Add a small "kick" to overcome gearbox friction in direction of motion
      cmd_rpm += (cmd_rpm > 0) ? FRICTION_KICK_RPM : -FRICTION_KICK_RPM;
    }

    // Saturate and command
    if (cmd_rpm >  MAX_RPM) cmd_rpm =  MAX_RPM;
    if (cmd_rpm < -MAX_RPM) cmd_rpm = -MAX_RPM;
    dxl.setGoalVelocity(id, cmd_rpm, UNIT_RPM);
  }

  // Stream positions to host: pos0,pos1,pos2
  Serial.print(lastPosDeg[0]); Serial.print(",");
  Serial.print(lastPosDeg[1]); Serial.print(",");
  Serial.println(lastPosDeg[2]);
}
