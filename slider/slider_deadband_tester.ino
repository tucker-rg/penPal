#define PWM_PIN0 2
#define PWM_PIN1 3
int prevRead;
int tolerance = 10;
void setup() {
  Serial.begin(115200);
  analogWriteFrequency(PWM_PIN0, 10000);
  analogWriteFrequency(PWM_PIN1, 10000);
  prevRead = analogRead(A0);
}

void loop() {
  for (int i = 120; i<256; i++){
    // Serial.println(i);
    analogWrite(PWM_PIN0, i);
    analogWrite(PWM_PIN1, 0);
    int newRead = analogRead(A0);
    if (abs(newRead - prevRead)>tolerance){
      Serial.println(i);
    }
    prevRead = newRead;
    delay(100);
  }
  for (int i = 156; i<256; i++){
    // Serial.println(i);
    analogWrite(PWM_PIN0, 0);
    analogWrite(PWM_PIN1, i);
    int newRead = analogRead(A0);
    if (abs(newRead - prevRead)>tolerance){
      Serial.println(i);
    }
    prevRead = newRead;
    delay(100);
  }


}
