// all of the coordinate conversions

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
