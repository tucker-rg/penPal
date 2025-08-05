// these are just helper functions, basic stuff

void startReplay() {
  println("starting replay");
  state = REPLAYING;
  replayStartTime = millis();
  replayIndex = 0;
  updateUI();
  lastSentIndex = -1;
} 

void clear() {
  println("clearing.");
  boolean normalized = currentDoodle.getNormalized();
  currentDoodle = new Doodle(normalized);
  
  // clear the currently selected preset too
  if (selectedPreset == 1) {
    reset1();
  } else if (selectedPreset == 2) {
    reset2();
  } else if (selectedPreset == 3) {
    reset3();
  } else if (selectedPreset == 4) {
    reset4();
  }
  selectedPreset = 0; 
  updateUI();
}

// returns if the mouse is currently within the square
boolean inBounds() {
  float localX = mouseX - outerOffsetX;
  float localY = mouseY - outerOffsetY;

  // Are we in the square
  if (localX >= 0 && localX <= squareSize &&
      localY >= 0 && localY <= squareSize) {
    return true;
  } else {
    return false;
  }
}

// Modified inBounds to accept PVector (screen position)
boolean inBounds(PVector pos) {
  float localX = pos.x - outerOffsetX;
  float localY = pos.y - outerOffsetY;

  return (localX >= 0 && localX <= squareSize &&
          localY >= 0 && localY <= squareSize);
}

// converts screen coordinates to square coordinates
PVector toSquare(PVector pos) {
  float localX = pos.x - outerOffsetX;
  float localY = pos.y - outerOffsetY;

  PVector returns = new PVector(localX, localY);
  return returns;
}

// converts square coordinates to screen coordinates
PVector toScreen(PVector pos) {
  float localX = pos.x + outerOffsetX;
  float localY = pos.y + outerOffsetY;

  PVector returns = new PVector(localX, localY);
  return returns;
}

// converts square coordinates to grid coordinates
PVector toGrid(PVector pos) {
  float gridX = map(pos.x, 0, squareSize, DRAWING_MIN, DRAWING_MAX);
  float gridY = map(pos.y, 0, squareSize, DRAWING_MAX, DRAWING_MIN); // We reverse
  PVector gridCoord = new PVector(gridX, gridY);
  
  return gridCoord;
}

// converts grid coordinates to square coordinates
PVector toSquareFromGrid(PVector pos) {
  float localX = map(pos.x, DRAWING_MIN, DRAWING_MAX, 0, squareSize);
  float localY = map(pos.y, DRAWING_MAX, DRAWING_MIN, 0, squareSize);
  
  PVector squareCoord = new PVector(localX, localY);
  return squareCoord;
}
