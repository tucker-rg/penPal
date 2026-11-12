// The UI Manager draws the user interface, handles coordinate conversion


// UI manager has access to playback_manager and main (see drawDoodle() and syncUI())
// ideally, there should be a UIState class which contains:
// class UIState {
//   boolean isPlaying;
//   boolean useNormalized;
//   float size, maxSize;
//   float angle, minAngle, maxAngle;
  
class UIManager {

  // ===== Dependencies =====
  PApplet parent;

  // Control p5
  ControlP5 cp5;

  // ===== Layout =====
  int squareSize; // this is determined according to display
  int outerOffsetX = 250; // change these for different size screen (200 for full screen, 90 for small)
  int outerOffsetY = 200; // change ... (200 for full screen, 75 for small)

  int innerOffset = 30; // for the sliders
  int controlHeight = 25;
  int betweenControls = 15;
  int font_size = 10;

  // ====== Initialize =====
  int controlX, controlW, controlH, spacer;
  int buttonW, buttonH; // for the buttons
  int imageSize;
  int miscButtonW;
  PGraphics[] presetThumbnails = new PGraphics[NUM_PRESETS];
  int presetY;

  // ===== Mini Constructor =====
  UIManager(PApplet parent, ControlP5 cp5) {
    this.parent = parent;
    this.cp5 = cp5;
    squareSize = parent.height - 2 * outerOffsetY;
    setupUI();
  }
  
  // sets up the UI
  void setupUI() {
    PFont font = createFont("Arial", font_size);
    cp5.setFont(font);

    squareSize = height - 2 * outerOffsetY;
    controlX = outerOffsetX + squareSize + innerOffset;
    controlW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 3;
    controlH = controlHeight;
    spacer = controlH + betweenControls; 
    imageSize = (width - outerOffsetX - squareSize - innerOffset - betweenControls * 3 - outerOffsetX) / 4;
    miscButtonW = imageSize;
    
    buttonW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 5;
    buttonH = buttonW / 2;
    
    for (int i = 0; i < presetThumbnails.length; i++) {
      presetThumbnails[i] = drawThumbnail(presets[i], imageSize);
    }
    
    // Replay speed slider
    cp5.addSlider("replaySpeed")
    .setLabel("speed")
    .setPosition(controlX, outerOffsetY + betweenControls)
    .setRange(0.1, 2.0)
    .setValue(1.0)
    .setSize(controlW, controlH);

    // Size slider
    cp5.addSlider("size") 
      .setPosition(controlX, outerOffsetY + spacer + betweenControls)
      .setRange(0.1, 2.0)
      .setValue(1.0)
      .setSize(controlW, controlH);
      
    // Rotation slider
    cp5.addSlider("angle")
      .setPosition(controlX, outerOffsetY + spacer + spacer + betweenControls)
      .setRange(-180, 180)
      .setValue(0)
      .setSize(controlW, controlH);
    
    int buttonY = outerOffsetY + spacer * 3 + betweenControls * 2 + font_size + betweenControls;
    
    // Add label for default strokes (above shape buttons)
    cp5.addLabel("DEFAULT PRESETS:")
      .setPosition(controlX, buttonY - font_size - betweenControls)  // Position above the buttons
      .setFont(font)
      .setColor(color(255));

    // Image buttons using Button with custom images
    cp5.addButton("set4")
      .setPosition(controlX, buttonY)
      .setSize(imageSize, imageSize)
      .setImages(presetThumbnails[4], presetThumbnails[4], presetThumbnails[4]); // normal, over, pressed

    cp5.addButton("set5")
      .setPosition(controlX + imageSize + betweenControls, buttonY)
      .setSize(imageSize, imageSize)
      .setImages(presetThumbnails[5], presetThumbnails[5], presetThumbnails[5]);

    cp5.addButton("set6")
      .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls, buttonY)
      .setSize(imageSize, imageSize)
      .setImages(presetThumbnails[6], presetThumbnails[6], presetThumbnails[6]);

    cp5.addButton("set7")
      .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls + imageSize + betweenControls, buttonY)
      .setSize(imageSize, imageSize)
      .setImages(presetThumbnails[7], presetThumbnails[7], presetThumbnails[7]);
    
    // Preset buttons
    presetY = buttonY + imageSize + betweenControls + font_size + betweenControls;
    
    // Add label for custom strokes (above preset buttons)
    cp5.addLabel("CUSTOM PRESETS:")
      .setPosition(controlX, presetY - font_size - betweenControls)  // Position above the preset buttons
      .setFont(font)
      .setColor(color(255));
      
    cp5.addButton("set0")
      .setPosition(controlX, presetY)
      .setSize(imageSize, imageSize)
      .setImages(presetThumbnails[0], presetThumbnails[0], presetThumbnails[0]);

    cp5.addButton("set1")
      .setPosition(controlX + imageSize + betweenControls, presetY)
      .setSize(imageSize, imageSize)
      .setImages(presetThumbnails[1], presetThumbnails[1], presetThumbnails[1]);

    cp5.addButton("set2")
      .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls, presetY)
      .setSize(imageSize, imageSize)
      .setImages(presetThumbnails[2], presetThumbnails[2], presetThumbnails[2]);
      
    cp5.addButton("set3")
      .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls + imageSize + betweenControls, presetY)
      .setSize(imageSize, imageSize)
      .setImages(presetThumbnails[3], presetThumbnails[3], presetThumbnails[3]);
      
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
    cp5.addButton("save")
      .setPosition(controlX + miscButtonW + betweenControls + miscButtonW + betweenControls, miscButtonY)
      .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY);
      
    // create a toggle
    cp5.addToggle("handleNormalize")
      .setLabel("normalize")
      .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY)
      .setPosition(controlX + miscButtonW + betweenControls + miscButtonW + betweenControls  + miscButtonW + betweenControls, miscButtonY)
      ;
  }


  // syncs with the playbackManager to update the ui
  void syncUI() {
    setControllerValue("handleNormalize", playbackManager.useNormalized ? 1 : 0);
    setControllerValue("handleTogglePlayback", playbackManager.isPlaying() ? 1 : 0);

    Slider sizeSlider = (Slider)cp5.getController("size");
    sizeSlider.setBroadcast(false);
    sizeSlider.setRange(0.1, min(2.0, playbackManager.maxSize));
    sizeSlider.setValue(playbackManager.size);
    sizeSlider.setBroadcast(true);

    Slider angleSlider = (Slider)cp5.getController("angle");
    angleSlider.setBroadcast(false);
    angleSlider.setRange(playbackManager.minAngle, playbackManager.maxAngle);
    angleSlider.setValue(playbackManager.angle);
    angleSlider.setBroadcast(true);
  }

  void setControllerValue(String name, float val) {
    cp5.getController(name).setBroadcast(false);
    cp5.getController(name).setValue(val);
    cp5.getController(name).setBroadcast(true);
  }
  
  // draw
  void draw(Doodle currDoodle, PVector latestPoint, int sp) {
    drawDoodle(currDoodle);
    // the buttons should reflect the state
    syncUI(); 

    if (latestPoint == null) {
      return;
    }

    if (playbackManager.isPlaying() || playbackManager.isPaused()) {
      drawTip(latestPoint, 255); // with no transparency
    } else {
      drawTip(latestPoint, 50); // just the outline
    }

    highlightPreset(sp);
  }

  // Highlight preset
  void highlightPreset(int sp) {
    stroke(0, 150, 255);   // Bright blue border
    strokeWeight(5);
    noFill();

    // Highlight custom preset
    if (sp >= 0 && sp < 4) {
      int x = controlX + (sp) * (imageSize + betweenControls);
      int y = presetY;
      rect(x, y, imageSize, imageSize);
    }

    // Highlight default preset
    if (sp >= 4 && sp < 8) {
      int x = controlX + (sp-4) * (imageSize + betweenControls);
      int y = outerOffsetY + spacer * 3 + betweenControls * 2 + font_size + betweenControls; // Same as buttonY
      rect(x, y, imageSize, imageSize);
    }
  }

  // draws the drawing square and the current doodle, with whatever transformations
  void drawDoodle(Doodle currDoodle) {
    // drawing the background square
    stroke(0);
    fill(255);
    strokeWeight(0);
    parent.rect(outerOffsetX, outerOffsetY, squareSize, squareSize);
    
    // drawing the doodle
    pushMatrix();
    translate(outerOffsetX, outerOffsetY);
    
    int strokeInd = 0;
    while (strokeInd < currDoodle.getStrokeCount()) {
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
          PVector transformedPos = playbackManager.applyTransformations(worldPos);
          PVector v2 = toSquareFromGrid(transformedPos);
    
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
      strokeInd++;
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

  PGraphics drawThumbnail(Doodle doodle, int imageSize) {
    PGraphics pg = createGraphics(imageSize, imageSize);
    int count = doodle.getCount();
    
    pg.beginDraw();
    pg.background(240);
    pg.stroke(0);
    pg.strokeWeight(2);
    pg.noFill();
    
    if (count > 0) {
      float padding = 10;
      
      // Step 1: Find bounds
      float minX = Float.MAX_VALUE, maxX = -Float.MAX_VALUE;
      float minY = Float.MAX_VALUE, maxY = -Float.MAX_VALUE;
      for (int i = 0; i < count; i++) {
        float x = doodle.getPoint(i).pos.x;
        float y = doodle.getPoint(i).pos.y;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }

      float strokeWidth = maxX - minX;
      float strokeHeight = maxY - minY;

      // Step 2: Compute scale
      float availableW = imageSize - 2 * padding;
      float availableH = imageSize - 2 * padding;
      float scale = min(availableW / strokeWidth, availableH / strokeHeight);

      // Step 3: Compute center offsets
      float centerX = (minX + maxX) / 2;
      float centerY = (minY + maxY) / 2;
      float canvasCenter = imageSize / 2;

      // Step 4: Draw with segmentation logic
      boolean drawing = false;
      final float zEps = 1e-3; // pen up/down threshold

      for (int i = 0; i < count; i++) {
        TimedPoint tp = doodle.getPoint(i);
        PVector worldPos = tp.pos;
        boolean penDown = abs(worldPos.z) < zEps;

        float x = (worldPos.x - centerX) * scale + canvasCenter;
        float y = -(worldPos.y - centerY) * scale + canvasCenter;

        if (penDown) {
          if (!drawing) {
            pg.beginShape();
            drawing = true;
          }
          pg.vertex(x, y);
        } else {
          if (drawing) {
            pg.endShape();
            drawing = false;
          }
        }
      }

      // close last stroke if still drawing
      if (drawing) {
        pg.endShape();
      }
    }
    
    pg.endDraw();
    return pg;
  }

  void resetThumbnail(int i) {
    presetThumbnails[i] = drawThumbnail(presets[i], imageSize);
    cp5.getController("set" + i)
     .setImages(presetThumbnails[i], presetThumbnails[i], presetThumbnails[i]);
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
