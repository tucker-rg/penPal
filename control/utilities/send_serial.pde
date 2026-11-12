import controlP5.*;
import processing.serial.*;

ControlP5 cp5;
Serial myPort;
float input_0 = 0.0;
float input_1 = 0.0;
float input_2 = 0.0;

void setup() {
  size(400, 300);
  
  // Initialize serial communication (adjust port name as needed)
  printArray(Serial.list());
  String portName = Serial.list()[3];  // Change index if needed
  myPort = new Serial(this, portName, 57600);
  
  cp5 = new ControlP5(this);

  // Create text fields for manual entry
  cp5.addTextfield("input_0")
     .setPosition(150, 50)
     .setSize(100, 30)
     .setText(str(input_0))
     .setAutoClear(false)
     .setBroadcast(false);  // Prevent automatic variable setting
  
  cp5.addTextfield("input_1")
     .setPosition(150, 100)
     .setSize(100, 30)
     .setText(str(input_1))
     .setAutoClear(false)
     .setBroadcast(false);
  
  cp5.addTextfield("input_2")
     .setPosition(150, 150)
     .setSize(100, 30)
     .setText(str(input_2))
     .setAutoClear(false)
     .setBroadcast(false);

  cp5.get(Textfield.class, "input_0").onChange(e -> {
    input_0 = parseFloat(e.getController().getStringValue());
    println("manual input_0: " + input_0);
    sendValuesToArduino();
  });
  
  cp5.get(Textfield.class, "input_1").onChange(e -> {
    input_1 = parseFloat(e.getController().getStringValue());
    println("manual input_1: " + input_1);
    sendValuesToArduino();
  });
  
  cp5.get(Textfield.class, "input_2").onChange(e -> {
    input_2 = parseFloat(e.getController().getStringValue());
    println("manual input_2: " + input_2);
    sendValuesToArduino();
  });


}

void draw() {
  background(50);
  fill(255);
  textSize(16);

  text("Input 0: " + input_0, 50, 70);
  text("Input 1: " + input_1, 50, 120);
  text("Input 2: " + input_2, 50, 170);
  
  text("W/S: Increase/Decrease Input 0", 50, 210);
  text("E/D: Increase/Decrease Input 1", 50, 230);
  text("R/F: Increase/Decrease Input 2", 50, 250);
}

// Handle keyboard input
void keyPressed() {
  // Ignore keys if a text field is active
  if (cp5.get(Textfield.class, "input_0").isFocus() ||
      cp5.get(Textfield.class, "input_1").isFocus() ||
      cp5.get(Textfield.class, "input_2").isFocus()) {
    return;
  }

  float step = 1.0;

  if (key == 'w' || key == 'W') input_0 += step;
  if (key == 's' || key == 'S') input_0 -= step;
  if (key == 'e' || key == 'E') input_1 += step;
  if (key == 'd' || key == 'D') input_1 -= step;
  if (key == 'r' || key == 'R') input_2 += step;
  if (key == 'f' || key == 'F') input_2 -= step;

  updateTextFields();
  sendValuesToArduino();
}



// Handle manual entry





// Send formatted data to Arduino
void sendValuesToArduino() {
  String data = "0:" + input_0 + ",1:" + input_1 + ",2:" + input_2 + "\n";
  myPort.write(data);
  println("Sent: " + data);
}

// Update text fields when values change
void updateTextFields() {
  cp5.get(Textfield.class, "input_0").setText(str(input_0));
  cp5.get(Textfield.class, "input_1").setText(str(input_1));
  cp5.get(Textfield.class, "input_2").setText(str(input_2));
}
