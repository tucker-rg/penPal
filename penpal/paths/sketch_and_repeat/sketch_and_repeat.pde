import controlP5.*;
import processing.serial.*;
import java.util.*;

ControlP5 cp5;
Serial myPort;

ArrayList<PVector> points = new ArrayList<PVector>();  // Store drawing
Table lookup;
PVector lastSent = new PVector(-9999, -9999);
float minMoveDist = 2;
String lastCommand = "";

boolean strokeComplete = false;
int strokeIndex = 0;
boolean forward = true;
int delayFrames = 10;  // how many frames between motor updates
int frameCounter = 0;


void setup() {
  size(400, 400);
  printArray(Serial.list());
  String portName = Serial.list()[3];  // Adjust as needed
  myPort = new Serial(this, portName, 57600);

  cp5 = new ControlP5(this);
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

  if (strokeComplete && points.size() > 0) {
    frameCounter++;
    if (frameCounter >= delayFrames) {
      frameCounter = 0;

      // Send current point to motors
      PVector p = points.get(strokeIndex);
      sendMotorCommand(p.x, p.y);

      // Update index
      if (forward) {
        strokeIndex++;
        if (strokeIndex >= points.size()) {
          strokeIndex = points.size() - 1;
          forward = false;
        }
      } else {
        strokeIndex--;
        if (strokeIndex < 0) {
          strokeIndex = 0;
          forward = true;
        }
      }
    }
  }
}

void mouseDragged() {
  if (!strokeComplete) {
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
}

void mouseReleased() {
  if (points.size() > 1) {
    println("Stroke complete. Beginning loop.");
    strokeComplete = true;
    strokeIndex = 0;
    forward = true;
  }
}

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

TableRow getExactRow(float x, float y) {
  float rx = round(x * 2) / 2.0;
  float ry = round(y * 2) / 2.0;

  println("Rounded to: X = " + rx + ", Y = " + ry);

  for (TableRow row : lookup.rows()) {
    if (row.getFloat("X") == rx && row.getFloat("Y") == ry) {
      return row;
    }
  }

  return null;
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    points.clear();
    strokeComplete = false;
    println("Cleared drawing");
  }
}
