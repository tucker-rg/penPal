// these are just helper functions, basic stuff

void startReplay() {
  println("starting replay");
  state = REPLAYING;
  replayStartTime = millis();
  replayIndex = 0;
  updateUI();
  lastSentIndex = -1;
  if (currentDoodle.mode == 1) { // for when we want to loop back to the beginning by picking up the pen
    currentDoodle.addTransition(currentDoodle.getPoint(0));
    currentDoodle.setMode(2);
  }
} 

void stopReplay() {
  println("starting replay");
  state = DRAWING;
  updateUI();
} 

void clear() {
  println("clearing.");
  boolean normalized = currentDoodle.getNormalized();
  currentDoodle = new Doodle(normalized);
  
  //// clear the currently selected preset too
  //if (selectedPreset == 1) {
  //  reset1();
  //} else if (selectedPreset == 2) {
  //  reset2();
  //} else if (selectedPreset == 3) {
  //  reset3();
  //} else if (selectedPreset == 4) {
  //  reset4();
  //}
  // selectedPreset = 0; 
  selectedPreset = findFirstAvailableSlot();
  
  updateUI();
}

// Modified inBounds to accept PVector (screen position)
boolean inBounds(PVector pos) {
  if (pos.z != 0) {
    println("this position is not in bounds");
    return false;
  }
  
  float localX = pos.x - outerOffsetX;
  float localY = pos.y - outerOffsetY;

  return (localX >= 0 && localX <= squareSize &&
          localY >= 0 && localY <= squareSize);
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
  
