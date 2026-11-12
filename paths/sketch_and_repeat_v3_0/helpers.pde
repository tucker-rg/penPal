// these are just helper functions, basic stuff

void startReplay() {
  drawing = false;
  replaying = true;
  revReplaying = false;
  replayStartTime = millis();
  replayIndex = 0;
  lastSentIndex = -1;
} 

void clear() {
  strokeCount = 0;
  drawing = true;
  replaying = false;
  revReplaying = false;
  utilitySetting = 0;
  replaySpeed = 1.0;
  size = 1.0;
  angle = 0;
  connectLastPoint = false;
  
  cp5.getController("replaySpeed").setValue(replaySpeed);
  cp5.getController("size").setValue(size);
  cp5.getController("angle").setValue(angle);
  
  println("Cleared.");
}

PVector applyTransformations(PVector original) {
  PVector transformed = original.copy();
  
  // Apply scaling
  //println("size: ", size);
  transformed.mult(size);
  
  // Apply rotation
  //println("orientation: ", angle);
  transformed.rotate(radians(-angle));
  
  return transformed;
}

PVector undoTransformations(PVector transformed) {
  PVector original = transformed.copy();
  
  // Apply scaling
  original.mult(1 / size);
  
  // Apply rotation
  original.rotate(radians(angle));
  
  return original;
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
