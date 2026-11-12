import java.util.*;
import controlP5.*;
import processing.serial.*;

ControlP5 cp5;
Serial myPort;

// System state
enum State {
  DRAWING,
  PLAYBACK
}

State state = State.DRAWING; // default to drawing

// To store the current doodle
Doodle currentDoodle;

// and the other strokes
Doodle line;
Doodle triangle;
Doodle circle;
Doodle stamp;

Doodle preset1;
Doodle preset2;
Doodle preset3;
Doodle preset4;

// we automatically select the first preset at launch
int selectedPreset = 1; // -4 (stamp), -3 (circle), -2 (triangle), -1 (line)
                        // 1, 2, 3, 4 (custom presets)

MotorCommand penControl; // To communicate with the pen
NormalizationManager normalizationManager; // manages normalization
//DrawingManager drawingManager; // manages drawing

void setup() {
  size(1000, 600);  // default android window
  
  //println("creating the currentDoodle");
  currentDoodle = new Doodle();
  
  println("creating the default doodles");
  createLine();
  createTriangle();
  createCircle();
  createStamp();
  
  println("creating the custom preset doodles");
  
  preset1 = new Doodle();
  preset2 = new Doodle();
  preset3 = new Doodle();
  preset4 = new Doodle();
  
  // To manage the motors
  penControl.initializeComms(this);
  NormalizationManager normalizationManager = new NormalizationManager();
    
  // Draw controls
  println("drawing the controls");
  setupUI();
  
  println("Setup complete.");
}

void draw() {
  background(200);
  drawDrawingSquare();
  drawHighlight();

  // Handle modes
  if (state == State.PLAYBACK) {
    if (currentDoodle.mode == 3) manageMode1(currentDoodle);
    if (currentDoodle.mode == 2) manageMode2(currentDoodle);
  }
}

// builds the doodle as it is being drawn
  // Drawing bounds (of the grid)
  final float DRAWING_MIN = -12.5;
  final float DRAWING_MAX = 12.5;
  int strokeStartTime;
  
  void mousePressed() {
    if (inBounds()) {
      state = DRAWING;
      strokeStartTime = millis();
      
      if (selectedPreset < 0) { // i.e. if one of the presets
        clear();
      }
    
      if (currentDoodle.getStrokeCount() != 0) {
        // this is for transitions
        PVector pos = new PVector(mouseX, mouseY);
        if (inBounds()) {
          currentDoodle.addTransitionStroke(toGrid(toSquare(pos)));
        }
      }
    }
  }

  void mouseDragged() {
    if (state == DRAWING) {
      PVector pos = new PVector(mouseX, mouseY);
      float t = millis() - strokeStartTime;
      if (inBounds()) {
        currentDoodle.addPoint(new TimedPoint(toGrid(toSquare(pos)), t));
        println("added point via dragging: ", currentDoodle.getPoint(currentDoodle.getCount()-1).pos, " at time: ", currentDoodle.getPoint(currentDoodle.getCount()-1).time);
      }
    }
  }
  
  void mouseReleased() {
    if (currentDoodle.getCount() > 1 && state == DRAWING) {
      startReplay();
    }
  }
}
