// The UI Manager draws the user interface, handles coordinate conversion
// UI Manager does NOT handle buttons, those are global
class UIManager {

  // ===== Dependencies =====
  PApplet parent;
  Doodle currentDoodle;

  // Control p5
  ControlP5 cp5;

  // ===== Layout =====
  int outerOffsetX = 80;
  int outerOffsetY = 70;
  int squareSize;

  int innerOffset = 30; // for the sliders
  int controlHeight = 25;
  int betweenControls = 15;
  int controlX, controlW, controlH, spacer;
  int buttonW, buttonH; // for the buttons
  int font_size = 10;
  int imageSize;
  int miscButtonW;
  // PGraphics preset1Img, preset2Img, preset3Img, preset4Img;
  int presetY;

  // ===== Mini Constructor =====
  UIManager(PApplet parent, ControlP5 cp5, Doodle currentDoodle) {
    this.parent = parent;
    this.cp5 = cp5;
    this.currentDoodle = currentDoodle;
    squareSize = parent.height - 2 * outerOffsetY;
    setupUI();
  }
  
  // sets up the UI (nothing for now)
  void setupUI() {
    PFont font = createFont("Arial", font_size);
    cp5.setFont(font);

    squareSize = height - 2 * outerOffsetY;
    controlX = outerOffsetX + squareSize + innerOffset;
    controlW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 3;
    controlH = controlHeight;
    spacer = controlH + betweenControls; 
    imageSize = (width - outerOffsetX - squareSize - innerOffset - betweenControls * 3 - outerOffsetX) / 4;
    //miscButtonW = (width - outerOffsetX - squareSize - innerOffset - betweenControls * 5 - outerOffsetX) / 3; // this is just arbitrary
    miscButtonW = imageSize;
    
    buttonW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 5;
    buttonH = buttonW / 2;
    
    // PGraphics lineImg = drawThumbnail(line, imageSize);
    // PGraphics triangleImg = drawThumbnail(triangle, imageSize);
    // PGraphics circleImg = drawThumbnail(circle, imageSize);
    // PGraphics stampImg = drawThumbnail(stamp, imageSize);
    
    // PGraphics preset1Img = drawThumbnail(preset1, imageSize);
    // PGraphics preset2Img = drawThumbnail(preset2, imageSize);
    // PGraphics preset3Img = drawThumbnail(preset3, imageSize);
    // PGraphics preset4Img = drawThumbnail(preset4, imageSize);
    
    // Replay speed slider
    cp5.addSlider("replaySpeed")
    .setLabel("speed")
    .setPosition(controlX, outerOffsetY + betweenControls)
    .setRange(0.1, 2.0)
    // .plugTo(currentDoodle, "replaySpeed")
    // .setValue(currentDoodle.replaySpeed)
    .setSize(controlW, controlH);

    // Size slider
    cp5.addSlider("size") 
      .setPosition(controlX, outerOffsetY + spacer + betweenControls)
      .setRange(0.1, 2.0)
      // .plugTo(currentDoodle, "size")
      // .setValue(currentDoodle.size)
      .setSize(controlW, controlH);
      //.setLabel("");  // Hide default label
      
    // Rotation slider
    cp5.addSlider("angle")
      .setPosition(controlX, outerOffsetY + spacer + spacer + betweenControls)
      .setRange(-180, 180)
      // .plugTo(currentDoodle, "angle")
      // .setValue(currentDoodle.angle)
      .setSize(controlW, controlH);
      //.setLabel("orientation");  // Hide default label
    
    int buttonY = outerOffsetY + spacer * 3 + betweenControls * 2 + font_size + betweenControls;
    
    // Add label for default strokes (above shape buttons)
    cp5.addLabel("DEFAULT PRESETS:")
      .setPosition(controlX, buttonY - font_size - betweenControls)  // Position above the buttons
      .setFont(font)
      .setColor(color(255));

    // Image buttons using Button with custom images
    // cp5.addButton("setLine")
    //   .setPosition(controlX, buttonY)
    //   .setSize(imageSize, imageSize)
    //   .setImages(lineImg, lineImg, lineImg); // normal, over, pressed

    // cp5.addButton("setTriangle")
    //   .setPosition(controlX + imageSize + betweenControls, buttonY)
    //   .setSize(imageSize, imageSize)
    //   .setImages(triangleImg, triangleImg, triangleImg);

    // cp5.addButton("setCircle")
    //   .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls, buttonY)
    //   .setSize(imageSize, imageSize)
    //   .setImages(circleImg, circleImg, circleImg);

    // cp5.addButton("setStamp")
    //   .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls + imageSize + betweenControls, buttonY)
    //   .setSize(imageSize, imageSize)
    //   .setImages(stampImg, stampImg, stampImg);
    
    // Preset buttons
    presetY = buttonY + imageSize + betweenControls + font_size + betweenControls;
    
    // // Add label for custom strokes (above preset buttons)
    // cp5.addLabel("CUSTOM PRESETS:")
    //   .setPosition(controlX, presetY - font_size - betweenControls)  // Position above the preset buttons
    //   .setFont(font)
    //   .setColor(color(255));
      
    // cp5.addButton("set1")
    //   .setPosition(controlX, presetY)
    //   .setSize(imageSize, imageSize)
    //   .setImages(preset1Img, preset1Img, preset1Img);

    // cp5.addButton("set2")
    //   .setPosition(controlX + imageSize + betweenControls, presetY)
    //   .setSize(imageSize, imageSize)
    //   .setImages(preset2Img, preset2Img, preset2Img);

    // cp5.addButton("set3")
    //   .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls, presetY)
    //   .setSize(imageSize, imageSize)
    //   .setImages(preset3Img, preset3Img, preset3Img);
      
    // cp5.addButton("set4")
    //   .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls + imageSize + betweenControls, presetY)
    //   .setSize(imageSize, imageSize)
    //   .setImages(preset4Img, preset4Img, preset4Img);
      
    int miscButtonY = presetY + imageSize + innerOffset;
    
    // play button
    cp5.addToggle("handleTogglePlayback")
      .setLabel("play")
      .setPosition(controlX, miscButtonY)
      .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY);
    
    // clear button
    cp5.addButton("handleClear")
      .setLabel("clear")
      .setPosition(controlX + miscButtonW + betweenControls, miscButtonY)
      .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY);
    
    // save button
    // cp5.addButton("save")
    //   .setPosition(controlX + miscButtonW + betweenControls + miscButtonW + betweenControls, miscButtonY)
    //   .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY);
      
    // create a toggle
    cp5.addToggle("handleNormalize")
      .setLabel("normalize")
      .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY)
      .setPosition(controlX + miscButtonW + betweenControls + miscButtonW + betweenControls  + miscButtonW + betweenControls, miscButtonY)
      ;
  }

  void syncUI() {
    setControllerValue("handleNormalize", playbackManager.useNormalized ? 1 : 0);
    setControllerValue("handleTogglePlayback", playbackManager.getPlaying() ? 1 : 0);
  }

  void setControllerValue(String name, float val) {
    cp5.getController(name).setBroadcast(false);
    cp5.getController(name).setValue(val);
    cp5.getController(name).setBroadcast(true);
  }
  
  // draw
  void draw(PVector latestPoint, Doodle currDoodle) {
    drawDoodle(currDoodle);
    if (latestPoint != null && systemState == State.PLAYBACK) {
      drawTip(latestPoint, 255); // with no transparency
    } else {
      // drawTip(latestPoint, 50); // just the outline
    }

    // the buttons should reflect the state
    syncUI();
  }

  // draws the drawing square, and the current doodle
  void drawDoodle(Doodle currDoodle) {
    // drawing the background square
    stroke(0);
    fill(255);
    strokeWeight(0);
    parent.rect(outerOffsetX, outerOffsetY, squareSize, squareSize);
    
    // drawing the doodle
    pushMatrix();
    translate(outerOffsetX, outerOffsetY);
  
    for (int strokeInd = 0; strokeInd < currDoodle.getStrokeCount(); strokeInd++) {
      parent.stroke(0);
      parent.strokeWeight(5);
      noFill();
      
      Stroke currentStroke = currDoodle.getStroke(strokeInd);
      
      if (currentStroke.getCount() > 0) {
        boolean drawing = false;
        final float zEps = 1e-3; // treat |z| less zEps as "down"
    
        for (int i = 0; i < currentStroke.getCount(); i++) {
          // IMPORTANT: use the original z to decide segmentation
          TimedPoint tp = currentStroke.getPointAtIndex(i);
          PVector worldPos = tp.pos;
          boolean penDown = abs(worldPos.z) < zEps;
    
          // Then flatten/transform only for drawing
          PVector v2 = toSquareFromGrid(worldPos);
    
          if (penDown) {
            if (!drawing) {
              beginShape();
              drawing = true;
            }
            
            vertex(v2.x, v2.y);
          } else {
            if (drawing) {
              endShape();
              drawing = false;
            }
          }
        }
    
        // Close the last open stroke
        if (drawing) {
          endShape();
        }
      }
    }
    popMatrix();
  }

  // draws the tip, with a desired transparency
  void drawTip(PVector latestPoint, int transparency) {
    // tip marker (unchanged)
    if (latestPoint != null) {
      PVector currentVertex = toScreenFromSquare(toSquareFromGrid(latestPoint));
      strokeWeight(0);
      fill(255, 0, 0, transparency);
      circle(currentVertex.x, currentVertex.y, 20);
    }
  }
  
  // coordinate conversions
  // the grid is global, square and screen are only important locally
  
  // gets the mouse's current grid position within the square, or returns null if outside the square
  PVector getGridPos() {
    PVector mousePos = new PVector(mouseX, mouseY);
    PVector square = toSquareFromScreen(mousePos);
    PVector grid = toGridFromSquare(square);
    
    if (grid.x < GRID_MIN || grid.x > GRID_MAX || grid.y < GRID_MIN || grid.y > GRID_MAX) {
      return null;
    }
    return grid;
  }
  
  // converts screen coordinates to square coordinates
  PVector toSquareFromScreen(PVector pos) {
    float localX = pos.x - outerOffsetX;
    float localY = pos.y - outerOffsetY;
  
    PVector returns = new PVector(localX, localY);
    return returns;
  }
  
  // converts square coordinates to screen coordinates
  PVector toScreenFromSquare(PVector pos) {
    float localX = pos.x + outerOffsetX;
    float localY = pos.y + outerOffsetY;
  
    PVector returns = new PVector(localX, localY);
    return returns;
  }
  
  // converts grid coordinates to square coordinates
  PVector toSquareFromGrid(PVector pos) {
    float localX = map(pos.x, GRID_MIN, GRID_MAX, 0, squareSize);
    float localY = map(pos.y, GRID_MAX, GRID_MIN, 0, squareSize);
    
    PVector squareCoord = new PVector(localX, localY);
    return squareCoord;
  }
  
  // converts square coordinates to grid coordinates
  PVector toGridFromSquare(PVector pos) {
    float gridX = map(pos.x, 0, squareSize, GRID_MIN, GRID_MAX);
    float gridY = map(pos.y, 0, squareSize, GRID_MAX, GRID_MIN); // We reverse
    
    PVector gridCoord = new PVector(gridX, gridY);
    return gridCoord;
  }
}
