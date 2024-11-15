#include "Slider.h"
#define PWM_PIN0 2
#define PWM_PIN1 3

const float INTEGRAL_MAX = 25.0; //Tucker: just a guess
const int TOLERANCE = 10;
float kP= 5.0;
float kI = 0.0;
float kD = 0.0;

unsigned long controlTimer;
unsigned long prevTimer = 0;

Slider slider0(PWM_PIN0, PWM_PIN1, A0, kP, kI, kD, INTEGRAL_MAX, TOLERANCE);

int targIndex = 0;
const int16_t targets[6] = {0, 1023, 127, 800, 500, 100};

void setup() {
  Serial.begin(115200);
  slider0.setFreq(20000);
}

void loop() {
  controlTimer = millis();
  if (controlTimer - prevTimer >= INTERVAL){
    if(slider0.update()){
      targIndex++; if (targIndex > sizeof(targets)/sizeof(targets[0])-1){targIndex = 0;}
      slider0.setTarget(targets[targIndex]);
      Serial.println("target hit");
      delay(100);
    }
  }
}

