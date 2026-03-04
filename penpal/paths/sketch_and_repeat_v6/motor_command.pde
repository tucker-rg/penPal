// === MOTOR COMMAND ===

// handles communication with the pen: sends the pen to certain positions using the mapping class
static class MotorCommand {
  // manages communication between the pen and the arduino/motors
  
  String lastCommand = "";
  int lastUpdatedTime = 0;
  final int INTERVAL = 10;
  float spoolDiameter = 17.0; // in mm
  boolean useIMU = false;
  boolean offlineMode = true;
  Serial myPort;
  
  Mapping map; // this maps between 3d coordinates and tendon lengths
  
  void initializeComms(PApplet p) {
    if (!offlineMode) {
      println("building the MotorCommand class, setting up serial");
      // Serial setup
      printArray(Serial.list());
      String portName = Serial.list()[0];  // Adjust index as needed
      myPort = new Serial(p, portName, 115200); //57600
      myPort.bufferUntil('\n');  // trigger serialEvent on newline
    }
  }
  
  // interum solution, until we can calculate these as we go according to imu data
  float penHeight = 30.0; // must be greater than 23.7m (to account for the pen tip length)
  float roll = 0.0; // about the x axis
  float pitch = 00.0; // about the y axis
  float yaw = 0.0; // about the z axis

  // sends grid coordinates to the pen
  void sendMotorCommand(PVector cmd) {
    if (penHeight <= 23.7) {
      println("pen height too low");
      return;
    }
    
    cmd.rotate(radians(0)); // to account for weirdness
    cmd.z = penHeight + cmd.z;
    
    PVector transformedCmd = rotateYawPitchRoll(cmd, -yaw  + 30, -pitch, -roll);
    
    //// to linear transform the matrix, accounting for weird inconsistency
    //PVector transformedCmd = transform(cmd);
    //transformedCmd.z = penHeight;
    
    float[] tendonLengths = map.getTendonLengths(transformedCmd);
    float[] motorPositions;
    motorPositions = new float[3];
    
    if (tendonLengths != null) {
      motorPositions = getMotorPositions(tendonLengths);
    }
    
    if (motorPositions != null) {
      String data = String.format("0:%f,1:%f,2:%f\n", 
        motorPositions[0], 
        motorPositions[1], 
        motorPositions[2]);
      
      if (!data.equals(lastCommand) && !offlineMode) {
        myPort.write(data);
        lastCommand = data;
      }
    }
  }
  
  // for some 3-dimensional tendonLengths PVector, finds the motor positions (or returns null if they are invalid)
  float[] getMotorPositions(float[] tendonLengths) {
    float[] motorPositions;
    motorPositions = new float[3];
    for (int i = 0; i < 3; i++) {
      motorPositions[i] = arcLengthToMotorPosition(tendonLengths[i]);
    }
    // println("found motor positions: (", motorPositions[0], ", ", motorPositions[1], ", ", motorPositions[2], ")");
    
    
    if (motorPositions[0] < 10 || motorPositions[0] > 310 || motorPositions[1] < 10 || motorPositions[1] > 310 || motorPositions[2] < 10 || motorPositions[2] > 310) {
      println("invalid motor motorPositions, returning null");
      return null;
    }
    return motorPositions;
  }
    
  float arcLengthToMotorPosition(float arcLength) {
    return arcLength * 360 / (PI * spoolDiameter) - 10;
  }
  
  PVector rotateYawPitchRoll(PVector v, float yawDeg, float pitchDeg, float rollDeg) {
    // Convert to radians
    float ψ = radians(yawDeg);   // yaw (Z axis)
    float θ = radians(pitchDeg); // pitch (Y axis)
    float ϕ = radians(rollDeg);  // roll (X axis)
  
    float cψ = cos(ψ), sψ = sin(ψ);
    float cθ = cos(θ), sθ = sin(θ);
    float cϕ = cos(ϕ), sϕ = sin(ϕ);
  
    float x = v.x;
    float y = v.y;
    float z = v.z;
  
    float x2 =  (cψ*cθ)*x + (cψ*sθ*sϕ - sψ*cϕ)*y + (cψ*sθ*cϕ + sψ*sϕ)*z;
    float y2 =  (sψ*cθ)*x + (sψ*sθ*sϕ + cψ*cϕ)*y + (sψ*sθ*cϕ - cψ*sϕ)*z;
    float z2 =  (-sθ)*x   + (cθ*sϕ)*y             + (cθ*cϕ)*z;
  
    return new PVector(x2, y2, z2);
  }

  
  //PVector transform(PVector v) {
  //  float newX = 1 * v.x + - 0.5 * v.y;
  //  float newY = - 0.5 * v.x + 1 * v.y;
  //  return new PVector(newX, newY);
  //}
  
  void serialEvent(Serial myPort) { // to read yaw pitch roll
    // println("i am trying to read from the serial");
    if (useIMU) {
      String inData = myPort.readStringUntil('\n');
      if (inData == null) return;
    
      inData = trim(inData);
    
      if (inData.startsWith("Yaw:")) {
        String[] parts = splitTokens(inData, " :");
        if (parts.length >= 6) {
          yaw = float(parts[1]) - 120;
          pitch = -float(parts[3]);
          roll = -float(parts[5]);
          
          // We want to make sure that it remains between -75 and 75
          if (pitch < -75.0) {
            pitch = -75.0;
          }
          if (pitch > 75.0) {
            pitch = 75.0;
          }
          if (roll > 75.0) {
            roll = 75.0;
          }
          if (roll < -75.0) {
            roll = -75.0;
          }
        }
      }
      println("Yaw:", yaw, "Pitch:", pitch, "Roll:", roll);
    }
  }
}
