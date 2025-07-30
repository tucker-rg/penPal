import controlP5.*;

ControlP5 cp5;

int outerOffsetX = 100;
int outerOffsetY = 70;
int innerOffset = 50;
int squareSize;
int controlHeight = 60;
float replay_speed = 1.0;
float size = 1.0;

int controlX, controlW, controlH, spacer;

void setup() {
  size(1280, 800);
  
  cp5 = new ControlP5(this);

  PFont font = createFont("Arial", 10);
  cp5.setFont(font);
  
  squareSize = height - 2 * outerOffsetY;
  controlX = outerOffsetX + squareSize + innerOffset;
  controlW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 3;
  controlH = controlHeight;
  spacer = controlH + innerOffset; 

  // Replay speed slider
  cp5.addSlider("replay_speed")
     .setPosition(controlX, outerOffsetY + innerOffset)
     .setRange(0.1, 3.0)
     .setValue(replay_speed)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label

  // Size slider
  cp5.addSlider("size")
     .setPosition(controlX, outerOffsetY + innerOffset + spacer)
     .setRange(0.1, 3.0)
     .setValue(size)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label
}

void draw() {
  background(200);
  
  // Draw square
  stroke(0);
  fill(255);
  strokeWeight(0);
  rect(outerOffsetX, outerOffsetY, squareSize, squareSize);
  
}
