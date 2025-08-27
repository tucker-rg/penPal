// === MOTOR COMMAND ===

class MotorCommand {
  String lastCommand = "";
  int lastUpdatedTime = 0;
  final int INTERVAL = 10;
  
  MotorCommand() {}
  
  // sends grid coordinates to the pen
  void sendMotorCommand(PVector cmd) {
    PVector flippedCmd = new PVector(cmd.x, -cmd.y); // to account for how the pen is usually held "upside down"
    
    TableRow row = getExactRow(flippedCmd);
    
    if (row != null) {
      String data = String.format("0:%d,1:%d,2:%d\n", 
        row.getInt("servo_0"), 
        row.getInt("servo_1"), 
        row.getInt("servo_2"));
      
      if (!data.equals(lastCommand) && !offlineMode) {
        myPort.write(data);
        lastCommand = data;
      }
    }
  }
  
  void getSetAngle() {
    int currentTime = millis();
    if (currentTime - lastUpdatedTime > INTERVAL) { // Make sure we only check at the same frequency as we update
      lastUpdatedTime = currentTime;
      String inData = myPort.readStringUntil('\n');
      if (inData != null) {
        inData = trim(inData);
    
        if (inData.startsWith("A0:")) {
          currentDoodle.setAngle(int(inData.substring(3)));
          updateUI();
          println("Sensor value from Arduino (and the current angle):", currentDoodle.getAngle(), " from a raw value of: ", inData.substring(3));
        } else {
          println("Other data:", inData);
        }
      }
    }
  }
  
  TableRow getExactRow(PVector pos) {
    float rx = (round(pos.x * 2) / 2.0);
    float ry = (round(pos.y * 2) / 2.0) * -1;
  
    for (TableRow row : lookup.rows()) {
      if (row.getFloat("X") == rx && row.getFloat("Y") == ry) {
        return row;
      }
    }
    return null;
  }
}
