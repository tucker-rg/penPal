// === MOTOR COMMAND ===

// handles communication with the pen: sends the pen to certain positions using the mapping class
class MotorCommand {
  String lastCommand = "";
  int lastUpdatedTime = 0;
  final int INTERVAL = 10; //Tucker: what room do we have to change this?

  float spoolDiameter = 17.5; // in mm
  private Mapping map = new Mapping();
  
  MotorCommand() {}

  void sendMotorCommand(PVector cmd, float h) {
    if (cmd == null) return;
    
    if (h <= 20) {
      //println("pen height too low");
      return;
    }

    // float theta = TWO_PI/3.0 - PI/6.0;  // 120° - 30° = 90°    // float theta = 0;
    float theta = TWO_PI/3.0;
    float c = cos(theta); //changed 5/1/26
    float s = sin(theta);
    float x = cmd.x; //why reassign here?
    float y = cmd.y;

    float xr = x * c - y * s; //changed 5/1/26
    float yr = x * s + y * c;

    PVector transformedCmd = new PVector(xr, yr, cmd.z + 30);

    // float theta = HALF_PI;
    // PVector transformedCmd = cmd.copy();
    // transformedCmd.rotate(theta);
    // transformedCmd.z += 30;

    // PVector transformedCmd = new PVector(cmd.x, cmd.y, cmd.z + 30);
    // print(transformedCmd);
    
    float[] tendonLengths = map.getTendonLengths(transformedCmd);
    if (tendonLengths == null) return;
    
    float[] motorPositions = getMotorPositions(tendonLengths);
    if (motorPositions == null) return;

    String data = String.format("0:%f,1:%f,2:%f\n",
      motorPositions[0],
      motorPositions[1],
      motorPositions[2]);
      
    if (!data.equals(lastCommand)) {
      penPort.write(data);
      lastCommand = data;
    }
  }

  // sends grid coordinates to the pen w/ yaw pitch roll
  void sendMotorCommand(PVector cmd, float h, float y, float p, float r) {
    if (h <= 23.7) {
      //println("pen height too low");
      return;
    }
    
    cmd.rotate(radians(0)); // to account for weirdness
    cmd.z = h + cmd.z;
    
    PVector transformedCmd = rotateYawPitchRoll(cmd, -y  + 30, -p, -r);
    
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
      
      if (!data.equals(lastCommand)) {
        penPort.write(data);
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
    
// Tucker: we might play with these bounds.    
    if (motorPositions[0] < 10 || motorPositions[0] > 310 || motorPositions[1] < 10 || motorPositions[1] > 310 || motorPositions[2] < 10 || motorPositions[2] > 310) {
      //println("invalid motor motorPositions, returning null");
      return null;
    }
    return motorPositions;
  }
    
  float arcLengthToMotorPosition(float arcLength) {
    return arcLength * 360 / (PI * spoolDiameter) - 10; //what is 10? seems like a functional offset
  }
  
// Tucker: is this our IMU integration?
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


}
