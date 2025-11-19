import processing.serial.*;

Serial myPort;  // Create object from Serial class
static String val;    // Data received from the serial port
float sensorVal = 0;
PrintWriter output;

void setup()
{
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 115200);
  output = createWriter(Integer.toString(millis())+".txt");
}

void draw()
{
  if ( myPort.available() > 0) {  // If data is available,
  val = myPort.readStringUntil('\n'); 
  //try {
  // sensorVal = Float.valueOf(val.trim());
  //}
  //catch(Exception e) {
  //;
  //}
  output.println(val);
  output.flush();
  }  
  noStroke(); 
}

void keyPressed() {
  output.flush();  // Writes the remaining data to the file
  output.close();  // Finishes the file
  exit();  // Stops the program
}
