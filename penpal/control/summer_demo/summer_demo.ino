#include <DynamixelShield.h>
#include <Bounce2.h>

#if defined(ARDUINO_AVR_UNO) || defined(ARDUINO_AVR_MEGA2560)
  #include <SoftwareSerial.h>
  SoftwareSerial soft_serial(7, 8); // DYNAMIXELShield UART RX/TX
  #define DEBUG_SERIAL soft_serial
#elif defined(ARDUINO_SAM_DUE) || defined(ARDUINO_SAM_ZERO)
  #define DEBUG_SERIAL SerialUSB    
#else
  #define DEBUG_SERIAL Serial
#endif

Bounce bounce = Bounce();

// int cat[100][3] = {{140, 69, 90}, {133, 66, 87}, {123, 63, 82}, {121, 62, 82}, {118, 60, 82}, {115, 57, 84}, {116, 57, 87}, {109, 55, 83}, {106, 55, 78}, {102, 55, 75}, {97, 56, 70}, {95, 56, 68}, {92, 56, 65}, {90, 55, 65}, {84, 54, 65}, {80, 52, 66}, {76, 52, 67}, {73, 52, 66}, {71, 52, 68}, {68, 52, 69}, {65, 53, 68}, {62, 54, 69}, {60, 55, 70}, {57, 57, 69}, {55, 59, 70}, {53, 62, 70}, {52, 63, 70}, {51, 67, 71}, {50, 72, 72}, {49, 76, 74}, {49, 78, 75}, {49, 83, 79}, {49, 85, 81}, {49, 89, 85}, {49, 93, 90}, {50, 97, 95}, {51, 101, 100}, {52, 105, 103}, {54, 111, 107}, {55, 114, 108}, {56, 117, 106}, {56, 118, 103}, {56, 116, 99}, {54, 112, 100}, {54, 111, 101}, {52, 104, 97}, {51, 100, 92}, {50, 96, 87}, {50, 95, 84}, {50, 91, 79}, {50, 88, 75}, {51, 87, 72}, {53, 89, 70}, {54, 89, 68}, {55, 89, 65}, {57, 89, 63}, {59, 89, 62}, {61, 90, 60}, {64, 90, 59}, {68, 92, 57}, {71, 93, 57}, {71, 91, 56}, {69, 88, 56}, {64, 84, 56}, {64, 82, 56}, {67, 79, 54}, {68, 76, 54}, {70, 75, 53}, {73, 77, 53}, {75, 79, 53}, {77, 86, 53}, {79, 91, 54}, {81, 94, 55}, {86, 101, 57}, {89, 105, 58}, {93, 105, 58}, {92, 100, 56}, {89, 97, 55}, {85, 90, 54}, {84, 88, 54}, {82, 83, 53}, {83, 78, 53}, {86, 76, 53}, {87, 73, 54}, {90, 73, 54}, {93, 72, 55}, {97, 72, 56}, {103, 73, 59}, {108, 73, 61}, {110, 72, 63}, {112, 71, 64}, {114, 69, 67}, {117, 68, 70}, {122, 69, 72}, {128, 71, 76}, {132, 71, 79}, {134, 70, 83}, {139, 71, 87}, {144, 72, 91}, {140, 69, 90}};
int cat_seg[156][3] = {{95, 60, 113}, {95, 60, 113}, {92, 59, 109}, {92, 59, 109}, {89, 59, 106}, {87, 59, 105}, {87, 59, 105}, {85, 59, 104},{81, 59, 103}, {81, 59, 103}, {80, 59, 104}, {78, 60, 104}, {78, 60, 104}, {78, 60, 104}, {78, 60, 104}, {78, 60, 104},{76, 60, 101}, {75, 59, 99}, {75, 59, 99}, {77, 59, 97}, {76, 58, 93}, {76, 58, 93}, {78, 58, 89}, {78, 58, 87},{78, 58, 87}, {78, 58, 85}, {76, 59, 85}, {76, 59, 85}, {77, 59, 83}, {73, 60, 82}, {73, 60, 82}, {68, 62, 80},{66, 64, 78}, {66, 64, 78}, {62, 71, 74}, {64, 79, 70}, {64, 79, 70}, {66, 82, 69}, {68, 85, 68}, {68, 85, 68},{71, 90, 67}, {72, 93, 67}, {72, 93, 67}, {75, 101, 69}, {78, 111, 72}, {78, 111, 72}, {80, 117, 75}, {81, 119, 76},{81, 119, 76}, {83, 123, 77}, {85, 125, 77}, {85, 125, 77}, {89, 129, 78}, {92, 128, 77}, {92, 128, 77}, {92, 126, 76},{92, 126, 76}, {92, 126, 76}, {92, 124, 74}, {92, 122, 73}, {92, 122, 73}, {90, 122, 74}, {90, 122, 74}, {90, 122, 74},{88, 122, 74}, {86, 120, 74}, {86, 120, 74}, {83, 116, 73}, {81, 112, 71}, {81, 112, 71}, {80, 106, 69}, {78, 99, 67},{78, 99, 67}, {79, 96, 66}, {80, 93, 65}, {80, 93, 65}, {80, 93, 65}, {82, 95, 65}, {82, 95, 65}, {84, 91, 64},{88, 87, 63}, {88, 87, 63}, {93, 84, 64}, {98, 83, 65}, {98, 83, 65}, {96, 81, 64}, {96, 81, 64}, {96, 81, 64},{94, 79, 64}, {90, 79, 64}, {90, 79, 64}, {88, 79, 64}, {88, 79, 64}, {88, 79, 64}, {88, 79, 64}, {87, 78, 64},{87, 78, 64}, {87, 74, 65}, {87, 72, 66}, {87, 72, 66}, {86, 71, 66}, {88, 70, 67}, {88, 70, 67}, {91, 71, 67},{91, 71, 67}, {91, 71, 67}, {92, 71, 67}, {94, 73, 67}, {94, 73, 67}, {95, 74, 67}, {97, 76, 66}, {97, 76, 66},{105, 80, 67}, {114, 82, 70}, {114, 82, 70}, {114, 82, 70}, {114, 81, 71}, {114, 81, 71}, {114, 81, 71}, {112, 79, 71},{112, 79, 71}, {112, 79, 71}, {109, 77, 70}, {109, 77, 70}, {101, 74, 69}, {97, 70, 70}, {97, 70, 70}, {93, 65, 73},{95, 64, 76}, {95, 64, 76}, {95, 63, 77}, {96, 62, 79}, {96, 62, 79}, {100, 62, 84}, {99, 61, 87}, {99, 61, 87},{98, 60, 88}, {98, 60, 90}, {98, 60, 90}, {95, 59, 94}, {97, 59, 97}, {97, 59, 97}, {100, 59, 100}, {100, 59, 104},{100, 59, 104}, {100, 60, 106}, {99, 60, 110}, {99, 60, 110}, {99, 60, 112}, {97, 60, 114}, {97, 60, 114}, {97, 60, 114},{95, 60, 113}, {95, 60, 113}, {95, 60, 113}, {95, 60, 113}};
int dog[100][3] = {{80, 104, 59}, {79, 99, 57}, {76, 96, 56}, {74, 90, 55}, {72, 87, 55}, {70, 82, 54}, {68, 80, 54}, {67, 75, 54},{65, 73, 54}, {64, 73, 55}, {62, 70, 56}, {61, 68, 56}, {59, 67, 58}, {58, 67, 59}, {57, 66, 60}, {56, 64, 62},{55, 64, 63}, {55, 63, 65}, {54, 62, 67}, {54, 61, 69}, {55, 60, 71}, {56, 58, 72}, {57, 57, 76}, {57, 57, 78},{58, 57, 81}, {59, 57, 85}, {61, 57, 88}, {61, 58, 90}, {62, 59, 95}, {64, 59, 98}, {66, 59, 99}, {65, 57, 95},{67, 56, 95}, {67, 55, 93}, {67, 54, 89}, {65, 54, 86}, {64, 54, 83}, {63, 53, 79}, {62, 53, 76}, {60, 55, 73},{62, 54, 73}, {65, 52, 75}, {66, 52, 76}, {69, 51, 79}, {72, 51, 82}, {76, 50, 84}, {81, 50, 86}, {83, 50, 88},{86, 50, 88}, {89, 50, 88}, {88, 50, 85}, {86, 50, 83}, {83, 50, 82}, {80, 50, 82}, {75, 50, 80}, {74, 50, 77},{73, 50, 75}, {73, 51, 72}, {70, 51, 69}, {68, 53, 66}, {67, 53, 65}, {70, 53, 64}, {72, 54, 63}, {74, 54, 62},{75, 55, 61}, {78, 55, 62}, {81, 54, 64}, {84, 53, 67}, {88, 52, 70}, {92, 52, 73}, {97, 53, 76}, {101, 54, 77},{102, 54, 77}, {102, 55, 75}, {98, 54, 73}, {94, 53, 72}, {91, 54, 69}, {87, 54, 66}, {85, 55, 63}, {82, 57, 61},{80, 58, 59}, {81, 61, 57}, {80, 62, 56}, {82, 65, 55}, {81, 67, 54}, {79, 69, 53}, {80, 73, 53}, {79, 76, 52},{79, 79, 53}, {80, 82, 53}, {85, 84, 53}, {87, 87, 54}, {89, 91, 54}, {87, 93, 55}, {85, 92, 54}, {83, 95, 55},{82, 96, 56}, {80, 98, 56}, {82, 105, 59}, {80, 104, 59}};
//try collecting a few rounds of adjustment, then using the average gain as the basis?

const uint8_t DXL0 = 1;
const uint8_t DXL1 = 4;
const uint8_t DXL2 = 7;
const float DXL_PROTOCOL_VERSION = 2.0;
DynamixelShield dxl;

int tick = 1;
int default_p_gain = 650;
int temp_p_gain = default_p_gain;
int default_i_gain = 80;
int temp_i_gain = default_i_gain;
int counter = 0;
int count = 0;
int spread;
bool startFlag = false;
unsigned long controlTimer;
unsigned long lastTimer;
unsigned long INTERVAL = 10; 
int state = 0;
const int STATES = 5;

int count0 = 0;
int count1 = 12;
int count2 = 24;
float error0;
float error1;
float error2;

const int16_t sine[36] = {
    60,    63,    67,    70,    73,    75,    77,
    79,    80,    80,    80,    79,    77,    75,
    73,    70,    67,    63,    60,    57,    53,
    50,    47,    45,    43,    41,    40,    40,
    40,    41,    43,    45,    47,    50,    53,
    57 };

using namespace ControlTableItem;
void setup() {
  bounce.attach(2, INPUT_PULLUP);
  bounce.interval(5);
  dxl.begin(1000000);
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
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL0, default_i_gain);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL1, default_i_gain);
  dxl.writeControlTableItem(POSITION_I_GAIN, DXL2, default_i_gain);
  dxl.setGoalPosition(1, dog[counter][0], UNIT_DEGREE);
  dxl.setGoalPosition(4, dog[counter][1], UNIT_DEGREE);
  dxl.setGoalPosition(7, dog[counter][2], UNIT_DEGREE);
}

void loop() {
  // DEBUG_SERIAL.println(state);
  bounce.update();
  if ( bounce.changed() ) {
    int deboucedInput = bounce.read();
    if ( deboucedInput == LOW ) {
      state++;
      count = 0;
      counter = 0;
      count0 = 0;
      count1 = 12;
      count2 = 24;
      if (state == STATES){
        state = 0;
      }
      if (state == 3){INTERVAL = 70;}
      else{INTERVAL = 10;}
    }
  }
  switch (state){
    case 0:
      controlTimer = millis();
      if (controlTimer - lastTimer > INTERVAL){
        lastTimer = controlTimer;
        dxl.setGoalPosition(DXL0, sine[count0], UNIT_DEGREE);
        dxl.setGoalPosition(DXL1, sine[count1], UNIT_DEGREE);
        dxl.setGoalPosition(DXL2, sine[count2], UNIT_DEGREE);
        count0++; count1++; count2++;
        if (count0>35){count0=0;}
        if (count1>35){count1=0;}
        if (count2>35){count2=0;}
      }
      break;

    case 1:
      if (targetReached()){
        counter++;
        if(counter>=155){counter = 0;}
        // DEBUG_SERIAL.println(counter);
      }
      dxl.setGoalPosition(DXL0, cat_seg[counter][0], UNIT_DEGREE);
      dxl.setGoalPosition(DXL1, cat_seg[counter][1], UNIT_DEGREE);
      dxl.setGoalPosition(DXL2, cat_seg[counter][2], UNIT_DEGREE);
      break;

    case 2:
      if (targetReached()){
        counter++;
        if(counter>=100){counter = 0;}
        // DEBUG_SERIAL.println(counter);
      }
      dxl.setGoalPosition(DXL0, dog[counter][0], UNIT_DEGREE);
      dxl.setGoalPosition(DXL1, dog[counter][1], UNIT_DEGREE);
      dxl.setGoalPosition(DXL2, dog[counter][2], UNIT_DEGREE);
      break;

    case 3:
      controlTimer = millis();
      if (controlTimer - lastTimer > INTERVAL){
        lastTimer = controlTimer;
        spread = analogRead(A0);
        if (spread >= 600){spread = 600;}
        else if (spread < 200){spread = 200;}
        spread = map(spread, 200, 600, 80.0, 20.0);
        if (count%2 == 0){
          dxl.setGoalPosition(DXL2, spread, UNIT_DEGREE);
          dxl.setGoalPosition(DXL0, 80.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 80.0, UNIT_DEGREE);
        }
        else{
          dxl.setGoalPosition(DXL2, 80.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL0, spread, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 80.0, UNIT_DEGREE);
        }
        count++;
        // DEBUG_SERIAL.print(spread); DEBUG_SERIAL.print("\t"); DEBUG_SERIAL.println(count);
      }
      break;
      
    case 4:
      spread = analogRead(A0);
      if (spread >= 800){spread = 800;}
      else if (spread < 200){spread = 200;}
      // DEBUG_SERIAL.print(spread); DEBUG_SERIAL.print("\t");
      float ratio = (spread - 200.0)/600.0;
      // DEBUG_SERIAL.print(ratio); DEBUG_SERIAL.print("\t");
      ratio = (40.0*ratio);
      controlTimer = millis();
      if (controlTimer - lastTimer > INTERVAL){
        lastTimer = controlTimer;
        if (spread != 200){
          dxl.setGoalPosition(DXL0, map(sine[count0], 60, 80, 60, 80 - ratio), UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, map(sine[count1], 60, 80, 60, 80 - ratio), UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, map(sine[count2], 60, 80, 60, 80 - ratio), UNIT_DEGREE);
          count0++; count1++; count2++;
          if (count0>35){count0=0;}
          if (count1>35){count1=0;}
          if (count2>35){count2=0;}
        }
        else{
        }
      }
      // DEBUG_SERIAL.println(ratio);
      break;
    }
}

bool targetReached(){
  if (state == 1){
    error0 = dxl.getPresentPosition(DXL0, UNIT_DEGREE) - cat_seg[counter][0];
    error1 = dxl.getPresentPosition(DXL1, UNIT_DEGREE) - cat_seg[counter][1];
    error2 = dxl.getPresentPosition(DXL2, UNIT_DEGREE) - cat_seg[counter][2];
  }
  else{
    error0 = dxl.getPresentPosition(DXL0, UNIT_DEGREE) - dog[counter][0];
    error1 = dxl.getPresentPosition(DXL1, UNIT_DEGREE) - dog[counter][1];
    error2 = dxl.getPresentPosition(DXL2, UNIT_DEGREE) - dog[counter][2];
  }
  // DEBUG_SERIAL.println(((error0 + error1 + error2)/3));
  if(abs(((error0 + error1 + error2)/3)) < 0.8){
    temp_p_gain = default_p_gain;
    tick = 1;
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL0, default_p_gain);
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL1, default_p_gain);
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL2, default_p_gain);
    return true;
  }
  else{
    temp_p_gain += 50;
    tick++;
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL0, temp_p_gain);
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL1, temp_p_gain);
    dxl.writeControlTableItem(POSITION_P_GAIN, DXL2, temp_p_gain);
    return false;
  }
}
