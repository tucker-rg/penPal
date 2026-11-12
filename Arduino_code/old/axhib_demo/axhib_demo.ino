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

const uint8_t DXL0 = 1;
const uint8_t DXL1 = 4;
const uint8_t DXL2 = 7;
const float DXL_PROTOCOL_VERSION = 2.0;
DynamixelShield dxl;

//This namespace is required to use Control table item names
using namespace ControlTableItem;

unsigned long controlTimer;
unsigned long lastTimer;
unsigned long INTERVAL = 15;

int counter = 0;
int goalIndex = 0;
const int NUM_GOALS = 5;
float goal[5] = {0.0, 100.0, 50.0, 200.0, 50.0};
float tolerance = 1.0;
int count = 0;
float slow_count = 0.0;
int count0;
int count1;
int count2;
int spread;
bool pedro = false;
int pdr;
int state = 7;
const int STATES = 8;
bool tree_not_cat = true;

/** Generated using Dr LUT - Free Lookup Table Generator
  * https://github.com/ppelikan/drlut
  **/
// Formula: sin(2*pi*t/T) 
const int16_t sine[36] = {
   120,   123,   127,   130,   133,   135,   137,
   139,   140,   140,   140,   139,   137,   135,
   133,   130,   127,   123,   120,   117,   113,
   110,   107,   105,   103,   101,   100,   100,
   100,   101,   103,   105,   107,   110,   113,
   117 };

const int16_t sine2[36] = {
   110,   112,   113,   115,   116,   118,   119,
   119,   120,   120,   120,   119,   119,   118,
   116,   115,   113,   112,   110,   108,   107,
   105,   104,   102,   101,   101,   100,   100,
   100,   101,   101,   102,   104,   105,   107,
   108 };

const int16_t sine3[18] = {
    50,    53,    56,    59,    60,    60,    59,
    56,    53,    50,    47,    44,    41,    40,
    40,    41,    44,    47 };

int cat[100][3] = {{140, 69, 90}, {133, 66, 87}, {123, 63, 82}, {121, 62, 82}, {118, 60, 82}, {115, 57, 84}, {116, 57, 87}, {109, 55, 83},
  {106, 55, 78}, {102, 55, 75}, {97, 56, 70}, {95, 56, 68}, {92, 56, 65}, {90, 55, 65}, {84, 54, 65}, {80, 52, 66}, {76, 52, 67}, {73, 52, 66}, 
  {71, 52, 68}, {68, 52, 69}, {65, 53, 68}, {62, 54, 69}, {60, 55, 70}, {57, 57, 69}, {55, 59, 70}, {53, 62, 70}, {52, 63, 70}, {51, 67, 71}, 
  {50, 72, 72}, {49, 76, 74}, {49, 78, 75}, {49, 83, 79}, {49, 85, 81}, {49, 89, 85}, {49, 93, 90}, {50, 97, 95}, {51, 101, 100}, {52, 105, 103}, 
  {54, 111, 107}, {55, 114, 108}, {56, 117, 106}, {56, 118, 103}, {56, 116, 99}, {54, 112, 100}, {54, 111, 101}, {52, 104, 97}, {51, 100, 92}, 
  {50, 96, 87}, {50, 95, 84}, {50, 91, 79}, {50, 88, 75}, {51, 87, 72}, {53, 89, 70}, {54, 89, 68}, {55, 89, 65}, {57, 89, 63}, {59, 89, 62}, 
  {61, 90, 60}, {64, 90, 59}, {68, 92, 57}, {71, 93, 57}, {71, 91, 56}, {69, 88, 56}, {64, 84, 56}, {64, 82, 56}, {67, 79, 54}, {68, 76, 54}, 
  {70, 75, 53}, {73, 77, 53}, {75, 79, 53}, {77, 86, 53}, {79, 91, 54}, {81, 94, 55}, {86, 101, 57}, {89, 105, 58}, {93, 105, 58}, {92, 100, 56}, 
  {89, 97, 55}, {85, 90, 54}, {84, 88, 54}, {82, 83, 53}, {83, 78, 53}, {86, 76, 53}, {87, 73, 54}, {90, 73, 54}, {93, 72, 55}, {97, 72, 56}, 
  {103, 73, 59}, {108, 73, 61}, {110, 72, 63}, {112, 71, 64}, {114, 69, 67}, {117, 68, 70}, {122, 69, 72}, {128, 71, 76}, {132, 71, 79}, 
  {134, 70, 83}, {139, 71, 87}, {144, 72, 91}, {140, 69, 90}};

int tree[100][3] = {{72, 60, 56}, {76, 61, 56}, {79, 63, 55}, {83, 64, 56}, {82, 63, 56}, {82, 60, 58}, {80, 58, 59}, {81, 56, 61},
                    {79, 54, 63}, {81, 53, 66}, {82, 52, 68}, {84, 51, 71}, {85, 51, 73}, {85, 50, 76}, {86, 50, 78}, {88, 50, 80},
                    {90, 50, 83}, {92, 50, 85}, {92, 50, 85}, {92, 50, 85}, {92, 50, 85}, {89, 50, 84}, {89, 50, 84}, {87, 50, 82},
                    {84, 50, 81}, {81, 50, 81}, {78, 50, 80}, {74, 50, 78}, {71, 50, 78}, {67, 51, 77}, {65, 52, 77}, {62, 54, 78},
                    {60, 55, 78}, {57, 57, 80}, {56, 60, 83}, {55, 60, 80}, {55, 59, 77}, {56, 58, 72}, {57, 57, 71}, {57, 57, 71},
                    {55, 59, 72}, {55, 59, 72}, {55, 60, 71}, {53, 61, 72}, {52, 63, 73}, {51, 65, 74}, {50, 68, 76}, {50, 70, 77},
                    {49, 75, 81}, {49, 80, 85}, {49, 83, 90}, {49, 86, 88}, {49, 84, 82}, {49, 83, 79}, {49, 81, 74}, {50, 79, 70},
                    {51, 78, 67}, {52, 78, 66}, {52, 76, 65}, {52, 76, 65}, {52, 78, 65}, {53, 80, 65}, {53, 84, 66}, {53, 86, 67},
                    {54, 89, 68}, {55, 93, 69}, {56, 96, 70}, {57, 96, 68}, {59, 96, 66}, {61, 96, 64}, {63, 97, 63}, {64, 95, 61},
                    {63, 92, 60}, {63, 90, 60}, {62, 88, 59}, {62, 83, 58}, {61, 81, 57}, {61, 79, 57}, {61, 77, 56}, {62, 78, 56},
                    {64, 80, 56}, {65, 81, 55}, {68, 82, 54}, {73, 86, 54}, {77, 88, 54}, {83, 91, 54}, {89, 92, 54}, {84, 88, 54},
                    {80, 82, 53}, {79, 78, 52}, {76, 74, 53}, {75, 70, 53}, {73, 68, 53}, {72, 66, 54}, {72, 63, 55}, {71, 62, 55},
                    {72, 61, 56}, {72, 60, 56}, {72, 60, 56}, {72, 60, 56}};

int star[100][3] = {{92, 50, 85}, {86, 50, 83}, {79, 50, 79}, {74, 50, 77}, {69, 51, 74}, {65, 52, 73}, {62, 53, 76}, {61, 55, 81}, {59, 56, 83}, {59, 59, 89}, {59, 62, 94}, {56, 63, 93}, {54, 64, 87}, {52, 64, 82}, {52, 64, 78}, {51, 66, 74}, {50, 70, 72}, {49, 74, 74}, {49, 80, 75}, {50, 86, 76}, {51, 93, 80}, {52, 98, 80}, {52, 95, 76}, {53, 89, 70}, {53, 86, 67}, {55, 84, 63}, {57, 82, 61}, {59, 85, 60}, {64, 88, 58}, {67, 91, 58}, {72, 98, 58}, {76, 102, 59}, {77, 98, 57}, {76, 91, 55}, {73, 84, 54}, {73, 80, 53}, {72, 74, 53}, {75, 70, 53}, {79, 71, 53}, {84, 70, 54}, {89, 70, 55}, {95, 70, 57}, {97, 68, 58}, {92, 64, 58}, {87, 61, 58}, {84, 59, 59}, {80, 56, 60}, {78, 55, 62}, {78, 53, 65}, {82, 51, 70}, {85, 51, 73}, {90, 50, 79}, {92, 50, 85}, {82, 50, 75}, {81, 51, 70}, {77, 52, 66}, {75, 54, 63}, {75, 56, 60}, {79, 59, 58}, {82, 60, 58}, {87, 63, 57}, {92, 67, 57}, {89, 67, 56}, {83, 67, 55}, {78, 67, 54}, {73, 68, 53}, {71, 70, 53}, {70, 75, 53}, {70, 81, 54}, {72, 85, 54}, {72, 92, 56}, {73, 97, 57}, {68, 90, 57}, {64, 86, 57}, {60, 83, 58}, {58, 80, 59}, {55, 80, 62}, {54, 82, 65}, {52, 84, 68}, {51, 89, 73}, {51, 93, 77}, {50, 88, 75}, {49, 81, 74}, {50, 75, 71}, {50, 70, 71}, {51, 67, 71}, {51, 65, 74}, {52, 63, 79}, {54, 62, 83}, {56, 62, 88}, {57, 60, 87}, {58, 58, 84}, {59, 56, 79}, {61, 54, 75}, {62, 53, 71}, {66, 52, 72}, {71, 51, 74}, {76, 50, 75}, {82, 50, 78}, {88, 50, 81}};
float cur0;
float cur1;
float cur2;

void setup() {
  // DEBUG_SERIAL.begin(115200);
  bounce.attach(2, INPUT_PULLUP);
  bounce.interval(5);

  // Set Port baudrate to 57600bps. This has to match with DYNAMIXEL baudrate.
  dxl.begin(57600);
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
}

void loop() {
  bounce.update();
  if ( bounce.changed() ) {
    int deboucedInput = bounce.read();
    if ( deboucedInput == LOW ) {
      state++;
      count0 = 0;
      count1 = 12;
      count2 = 24;
      if (state > STATES){
        state = 0;
      }
      if (state == 0){
        INTERVAL = 10;
        count = 0;
        slow_count = 0.0;
        cur0 = dxl.getPresentPosition(DXL0, UNIT_DEGREE);
        cur1 = dxl.getPresentPosition(DXL1, UNIT_DEGREE);
        cur2 = dxl.getPresentPosition(DXL2, UNIT_DEGREE);
      }
      else if (state == 1){count = 0;}
      else if (state == 2){count = 0; INTERVAL = 60;}
      else if (state == 3){INTERVAL = 4;}
      else if (state == 4){INTERVAL = 1;}
      else if (state == 5){
        count0 = 0;
        count1 = 6;
        count2 = 12;
      }
      else if (state == 6){
        INTERVAL = 80;
        count = 0;
      }
      else if (state == 7){
        INTERVAL = 90;
        count = 0;
      }
    }
  }
  // DEBUG_SERIAL.println(INTERVAL);
  controlTimer = millis();
  if (controlTimer - lastTimer > INTERVAL){
    lastTimer = controlTimer;
    switch (state){
      case 0: // Do nothing
        cur0 = cur0 - slow_count;
        if (cur0 < 15.0){cur0 = 15.0;}
        cur1 = cur1 - slow_count;
        if (cur1 < 15.0){cur1 = 15.0;}
        cur2 = cur2 - slow_count;
        if (cur2 < 15.0){cur2 = 15.0;}
        dxl.setGoalPosition(DXL0, cur0, UNIT_DEGREE);
        dxl.setGoalPosition(DXL1, cur1, UNIT_DEGREE);
        dxl.setGoalPosition(DXL2, cur2, UNIT_DEGREE);
        slow_count += 0.01;
        // Serial.print(cur0);Serial.print("\t");Serial.print(cur1);Serial.print("\t");Serial.println(cur2);

        //DEBUG_SERIAL.println(0);
  
        break;
      case 1: // Triangle
        DEBUG_SERIAL.println(1);
        dxl.setGoalPosition(DXL0, 5.0+count, UNIT_DEGREE);
        dxl.setGoalPosition(DXL1, 5.0+count, UNIT_DEGREE);
        dxl.setGoalPosition(DXL2, 5.0+count, UNIT_DEGREE);
        count+=15;
        if (count > 60){count = 60; state = 2;count = 0; INTERVAL = 60;}

        //DEBUG_SERIAL.println(1);

        break;
      case 2: 
        if (count > 5){
          count = 0;
        }
        if (count == 0){
          // DEBUG_SERIAL.println(0);
          dxl.setGoalPosition(DXL0, 60.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 60.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, 40.0, UNIT_DEGREE);
        }
        else if (count == 1){
          // DEBUG_SERIAL.println(1);
          dxl.setGoalPosition(DXL0, 60.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 60.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, 20.0, UNIT_DEGREE);
        }
        else if (count == 2){
          // DEBUG_SERIAL.println(2);
          dxl.setGoalPosition(DXL0, 60.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 40.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, 60.0, UNIT_DEGREE);
        }
        else if (count == 3){
          // DEBUG_SERIAL.println(3);
          dxl.setGoalPosition(DXL0, 60.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 20.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, 60.0, UNIT_DEGREE);
        }
        else if (count == 4){
          // DEBUG_SERIAL.println(4);
          dxl.setGoalPosition(DXL0, 40.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 60.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, 60.0, UNIT_DEGREE);
        }
        else if (count == 5){
          // DEBUG_SERIAL.println(5);
          dxl.setGoalPosition(DXL0, 20.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 60.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, 60.0, UNIT_DEGREE);
        }
        count++;
        break;
      case 3: // Big cirlce
        dxl.setGoalPosition(DXL0, sine[count0]-60, UNIT_DEGREE);
        dxl.setGoalPosition(DXL1, sine[count1]-60, UNIT_DEGREE);
        dxl.setGoalPosition(DXL2, sine[count2]-60, UNIT_DEGREE);
        count0++; count1++; count2++;
        if (count0>35){count0=0;}
        if (count1>35){count1=0;}
        if (count2>35){count2=0;}

        // DEBUG_SERIAL.println(3);

        break;
      case 4: // Small circle
        dxl.setGoalPosition(DXL0, sine2[count0]-40, UNIT_DEGREE);
        dxl.setGoalPosition(DXL1, sine2[count1]-40, UNIT_DEGREE);
        dxl.setGoalPosition(DXL2, sine2[count2]-40, UNIT_DEGREE);
        count0++; count1++; count2++;
        if (count0>35){count0=0;}
        if (count1>35){count1=0;}
        if (count2>35){count2=0;}

        // DEBUG_SERIAL.println(4);

        break;
      case 5: // Random
        dxl.setGoalPosition(DXL0, sine3[count0]+random(-15,15), UNIT_DEGREE);
        dxl.setGoalPosition(DXL1, sine3[count1]+random(-15,15), UNIT_DEGREE);
        dxl.setGoalPosition(DXL2, sine3[count2]+random(-15,15), UNIT_DEGREE);
        count0++; count1++; count2++;
        if (count0>17){count0=0;}
        if (count1>17){count1=0;}
        if (count2>17){count2=0;}

        // DEBUG_SERIAL.println(5);

        break;
      case 6: // Pressure sensitive
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

        // DEBUG_SERIAL.println(6);

        break;
      case 7: // Cat 
        if (!tree) {
          dxl.setGoalPosition(DXL0, cat[count][0], UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, cat[count][1], UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, cat[count][2], UNIT_DEGREE);
        } else {
          dxl.setGoalPosition(DXL0, tree[count][0], UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, tree[count][1], UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, tree[count][2], UNIT_DEGREE);
        }
          
        count++;
        if (count > 99){count = 0;}

        // DEBUG_SERIAL.println(7);

        break;
      case 8: // Random (Pedro)
        pdr = random(0,11);
        if (pdr > 8){
          pedro = true;
        }  
        if (pedro == false){
          dxl.setGoalPosition(DXL0, 80.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, 80.0, UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, 80.0, UNIT_DEGREE);
        }
        else{
          dxl.setGoalPosition(DXL0, random(30, 80), UNIT_DEGREE);
          dxl.setGoalPosition(DXL1, random(30, 80), UNIT_DEGREE);
          dxl.setGoalPosition(DXL2, random(30, 80), UNIT_DEGREE);
          pedro = false;
        }
        count++;

        // DEBUG_SERIAL.println(8);

        break;
    }
    
  }
  // DEBUG_SERIAL.print("one: "); DEBUG_SERIAL.print(dxl.getPresentPosition(1, UNIT_DEGREE));
  // DEBUG_SERIAL.print("\ttwo: "); DEBUG_SERIAL.print(dxl.getPresentPosition(4, UNIT_DEGREE));
  // DEBUG_SERIAL.print("\tthr: "); DEBUG_SERIAL.print(dxl.getPresentPosition(5, UNIT_DEGREE)); DEBUG_SERIAL.println();
}
