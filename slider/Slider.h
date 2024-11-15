#define INTERVAL 1

class Slider {
  private:
    int upPin;
    int downPin;
    int signalPin;
    float proportional;
    float integral;
    float derivative;
    float integralTotal;
    const float INTEGRAL_MAX;
    int output;
    const int TOLERANCE;
    float kP;
    float kI;
    float kD;
    int error;
    int prevError;
    int curPosition;
    int target;
    int frequency;
    int maxSpeed;

  public:
    Slider(int upPin, int downPin, int signalPin, float kP, float kI, float kD, const float INTEGRAL_MAX, const int TOLERANCE);
    bool update();
    int getPos();
    void setSpeed(int spd);
    void setTarget(int target);
    void setFreq(int frequency);
};

Slider::Slider(int upPin, int downPin, int signalPin, float kP, float kI, float kD, const float INTEGRAL_MAX, const int TOLERANCE)
  : upPin(upPin), downPin(downPin), signalPin(signalPin), kP(kP), kI(kI), kD(kD), INTEGRAL_MAX(INTEGRAL_MAX), TOLERANCE(TOLERANCE) {
    maxSpeed = 255;
    target = 0;
    error = 0;
    prevError = 0;
    integralTotal = 0;
    output = 0;
}

bool Slider::update() {
    curPosition = analogRead(signalPin);
    prevError = error;
    error = target - curPosition;
    // Serial.print("min:"); Serial.print(0); Serial.print(","); Serial.print("max:"); Serial.print(1050); Serial.print(",");
    // Serial.print("tar:"); Serial.print(target); Serial.print(",");
    // Serial.print("cur:"); Serial.println(curPosition);
    if (abs(error) <= TOLERANCE) {
      output = 0;
      analogWrite(upPin, output);
      analogWrite(downPin, 0);
      return true;
    } else {
      proportional = kP * error;
      integral = kI * error * INTERVAL;
      integralTotal += integral;
      integralTotal = constrain(integralTotal, -INTEGRAL_MAX, INTEGRAL_MAX);
      derivative = kD * (error - prevError) / INTERVAL;
      output = proportional + integralTotal + derivative;
      Serial.print("out0: "); Serial.print(output); Serial.print("\t");
      if (output >= 0) {
        output = map(abs(output), 0, round(kP*1023), 170, maxSpeed);
        Serial.print("out1: "); Serial.print(output); Serial.print("\n");
        analogWrite(upPin, output);
        analogWrite(downPin, 0);
      } else {
        output = map(abs(output), 0, round(kP*1023), 170, maxSpeed);
        Serial.print("out2: "); Serial.print(output); Serial.print("\n");
        analogWrite(upPin, 0);
        analogWrite(downPin, output);
      }
      return false;
    }
}

int Slider::getPos() {
  return curPosition;
}

void Slider::setSpeed(int spd) {
  //spd should be a number between 0 and 9
  spd = constrain(spd, 0, 9);
  this->maxSpeed = map(spd, 0, 9, 170, 255);
}

void Slider::setTarget(int target) {
  this->target = target;
}

void Slider::setFreq(int frequency){
  analogReadResolution(10);
  analogWriteFrequency(signalPin, frequency);
}
