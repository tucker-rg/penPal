import controlP5.*;
import processing.serial.*;
import java.util.*;

ControlP5 cp5;
Serial myPort;

ArrayList<PVector> points = new ArrayList<PVector>();  // Store drawing
Table lookup;
PVector lastSent = new PVector(-9999, -9999);
float minMoveDist = 2;  // Minimum movement before updating
String lastCommand = "";


void setup() {
  size(400, 400);
  
  // Serial setup
  printArray(Serial.list());
  String portName = Serial.list()[3];  // Adjust index as needed
  myPort = new Serial(this, portName, 57600);

  cp5 = new ControlP5(this);
  
  // Load lookup table
  lookup = loadTable("lookup_table.csv", "header");

  println("Setup complete.");
}

void draw() {
  background(255);

  stroke(0);
  noFill();
  beginShape();
  for (PVector p : points) {
    vertex(p.x, p.y);
  }
  endShape();
}

void mouseDragged() {
  PVector current = new PVector(mouseX, mouseY);
  points.add(current);

  float distMoved = PVector.dist(current, lastSent);
  println("Mouse moved: " + distMoved);

  if (distMoved >= minMoveDist) {
    sendMotorCommand(mouseX, mouseY);
    lastSent.set(current);
  } else {
    println("Movement too small, not sending.");
  }
}


// Normalize mouseX/mouseY to match lookup table range
void sendMotorCommand(float x, float y) {
  float realX = map(x, 0, width, -12.5, 12.5);
  float realY = map(y, 0, height, -12.5, 12.5);

  println("Sending for screen (" + x + "," + y + ") -> real (" + realX + "," + realY + ")");

  TableRow row = getExactRow(realX, realY);
  if (row != null) {
    int s0 = row.getInt("servo_0");
    int s1 = row.getInt("servo_1");
    int s2 = row.getInt("servo_2");

    String data = "0:" + s0 + ",1:" + s1 + ",2:" + s2 + "\n";

    if (!data.equals(lastCommand)) {
      myPort.write(data);
      println("Sent: " + data);
      lastCommand = data;
    } else {
      println("Skipping duplicate command: " + data.trim());
    }
  } else {
    println("No exact match found in table for rounded coordinates.");
  }
}

// Find closest matching X, Y in table
TableRow getExactRow(float x, float y) {
  float rx = round(x * 2) / 2.0;  // round to nearest 0.5
  float ry = round(y * 2) / 2.0;

  println("Rounded to: X = " + rx + ", Y = " + ry);

  for (TableRow row : lookup.rows()) {
    if (row.getFloat("X") == rx && row.getFloat("Y") == ry) {
      return row;
    }
  }

  return null;  // no exact match found
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    points.clear();
    println("Cleared drawing");
  }
}
