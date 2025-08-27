// UI
int outerOffsetX = 80; // 80
int outerOffsetY = 70; // 70
int innerOffset = 30;
int squareSize;
int controlHeight = 25; // 25
int betweenControls = 15; // 15
int controlX, controlW, controlH, spacer;
int buttonW, buttonH;
int font_size = 10;
int imageSize;
int miscButtonW;
PGraphics preset1Img, preset2Img, preset3Img, preset4Img;
int presetY;

void setupUI() {
  cp5 = new ControlP5(this);
  
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
  
  PGraphics lineImg = drawThumbnail(line, imageSize);
  PGraphics triangleImg = drawThumbnail(triangle, imageSize);
  PGraphics circleImg = drawThumbnail(circle, imageSize);
  PGraphics stampImg = drawThumbnail(stamp, imageSize);
  
  PGraphics preset1Img = drawThumbnail(preset1, imageSize);
  PGraphics preset2Img = drawThumbnail(preset2, imageSize);
  PGraphics preset3Img = drawThumbnail(preset3, imageSize);
  PGraphics preset4Img = drawThumbnail(preset4, imageSize);
  
  // Replay speed slider
  cp5.addSlider("replaySpeed")
   .setLabel("speed")
   .setPosition(controlX, outerOffsetY + betweenControls)
   .setRange(0.1, 2.0)
   .plugTo(currentDoodle, "replaySpeed")
   .setValue(currentDoodle.replaySpeed)
   .setSize(controlW, controlH);

  // Size slider
  cp5.addSlider("size") 
     .setPosition(controlX, outerOffsetY + spacer + betweenControls)
     .setRange(0.1, 2.0)
     .plugTo(currentDoodle, "size")
     .setValue(currentDoodle.size)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label
     
  // Rotation slider
  cp5.addSlider("angle")
     .setPosition(controlX, outerOffsetY + spacer + spacer + betweenControls)
     .setRange(-180, 180)
     .plugTo(currentDoodle, "angle")
     .setValue(currentDoodle.angle)
     .setSize(controlW, controlH);
     //.setLabel("orientation");  // Hide default label
  
  int buttonY = outerOffsetY + spacer * 3 + betweenControls * 2 + font_size + betweenControls;
  
  // Add label for default strokes (above shape buttons)
  cp5.addLabel("DEFAULT PRESETS:")
     .setPosition(controlX, buttonY - font_size - betweenControls)  // Position above the buttons
     .setFont(font)
     .setColor(color(255));

  // Image buttons using Button with custom images
  cp5.addButton("setLine")
     .setPosition(controlX, buttonY)
     .setSize(imageSize, imageSize)
     .setImages(lineImg, lineImg, lineImg); // normal, over, pressed

  cp5.addButton("setTriangle")
     .setPosition(controlX + imageSize + betweenControls, buttonY)
     .setSize(imageSize, imageSize)
     .setImages(triangleImg, triangleImg, triangleImg);

  cp5.addButton("setCircle")
     .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls, buttonY)
     .setSize(imageSize, imageSize)
     .setImages(circleImg, circleImg, circleImg);

  cp5.addButton("setStamp")
     .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls + imageSize + betweenControls, buttonY)
     .setSize(imageSize, imageSize)
     .setImages(stampImg, stampImg, stampImg);
  
  // Preset buttons
  presetY = buttonY + imageSize + betweenControls + font_size + betweenControls;
  
  // Add label for custom strokes (above preset buttons)
  cp5.addLabel("CUSTOM PRESETS:")
     .setPosition(controlX, presetY - font_size - betweenControls)  // Position above the preset buttons
     .setFont(font)
     .setColor(color(255));
     
  cp5.addButton("set1")
     .setPosition(controlX, presetY)
     .setSize(imageSize, imageSize)
     .setImages(preset1Img, preset1Img, preset1Img);

  cp5.addButton("set2")
     .setPosition(controlX + imageSize + betweenControls, presetY)
     .setSize(imageSize, imageSize)
     .setImages(preset2Img, preset2Img, preset2Img);

  cp5.addButton("set3")
     .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls, presetY)
     .setSize(imageSize, imageSize)
     .setImages(preset3Img, preset3Img, preset3Img);
     
  cp5.addButton("set4")
     .setPosition(controlX + imageSize + betweenControls + imageSize + betweenControls + imageSize + betweenControls, presetY)
     .setSize(imageSize, imageSize)
     .setImages(preset4Img, preset4Img, preset4Img);
     
  int miscButtonY = presetY + imageSize + innerOffset;
  
  // play button
  cp5.addButton("startReplay")
     .setLabel("play")
     .setPosition(controlX, miscButtonY)
     .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY);
  
  // clear button
  cp5.addButton("clear")
     .setPosition(controlX + miscButtonW + betweenControls, miscButtonY)
     .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY);
  
  // save button
  cp5.addButton("save")
     .setPosition(controlX + miscButtonW + betweenControls + miscButtonW + betweenControls, miscButtonY)
     .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY);
     
  // create a toggle
  cp5.addToggle("normalize")
     .setLabel("motion\nsmoothing")
     .setSize(miscButtonW, height - miscButtonY - betweenControls - outerOffsetY)
     .setPosition(controlX + miscButtonW + betweenControls + miscButtonW + betweenControls  + miscButtonW + betweenControls, miscButtonY)
     ;

}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom("normalize") && currentDoodle != null) {
    currentDoodle.setNormalized(theEvent.getController().getValue() == 1);
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
    PVector firstSegVertex = null;
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
          firstSegVertex = new PVector(x, y);
        }
        pg.vertex(x, y);
      } else {
        if (drawing) {
          if (doodle.connectLastPoint && firstSegVertex != null) {
            pg.vertex(firstSegVertex.x, firstSegVertex.y);
          }
          pg.endShape();
          drawing = false;
          firstSegVertex = null;
        }
      }
    }

    // close last stroke if still drawing
    if (drawing) {
      if (doodle.connectLastPoint && firstSegVertex != null) {
        pg.vertex(firstSegVertex.x, firstSegVertex.y);
      }
      pg.endShape();
    }
  }
  
  pg.endDraw();
  return pg;
}

// draws a square, with the shape inside that the user drew
void drawDrawingSquare() {
  stroke(0);
  fill(255);
  strokeWeight(0);
  rect(outerOffsetX, outerOffsetY, squareSize, squareSize);

  pushMatrix();
  translate(outerOffsetX, outerOffsetY);

  stroke(0);
  strokeWeight(5);
  noFill();

  if (currentDoodle.getCount() > 0) {
    boolean drawing = false;
    PVector firstSegVertex = null;
    final float zEps = 1e-3; // treat |z| < zEps as "down"

    for (int i = 0; i < currentDoodle.getCount(); i++) {
      // IMPORTANT: use the original z to decide segmentation
      TimedPoint tp = currentDoodle.getPoint(i);
      PVector worldPos = tp.pos;
      boolean penDown = abs(worldPos.z) < zEps;

      // Then flatten/transform only for drawing
      PVector v2 = toSquareFromGrid(worldPos);

      if (penDown) {
        if (!drawing) {
          beginShape();
          drawing = true;
          firstSegVertex = v2.copy();
        }
        vertex(v2.x, v2.y);
      } else {
        if (drawing) {
          // close current stroke (optionally loop it)
          if (currentDoodle.connectLastPoint && firstSegVertex != null) {
            vertex(firstSegVertex.x, firstSegVertex.y);
          }
          endShape();
          drawing = false;
          firstSegVertex = null;
        }
      }
    }

    // Close the last open stroke
    if (drawing) {
      if (currentDoodle.connectLastPoint && firstSegVertex != null) {
        vertex(firstSegVertex.x, firstSegVertex.y);
      }
      endShape();
    }

    // tip marker (unchanged)
    if (state != DRAWING) {
      PVector currentVertex = (state == REVREPLAYING)
        ? toSquareFromGrid(currentDoodle.getPoint(revReplayIndex).pos)
        : toSquareFromGrid(currentDoodle.getPoint(replayIndex).pos);
      strokeWeight(0);
      fill(255, 0, 0);
      circle(currentVertex.x, currentVertex.y, 20);
    }
  }

  popMatrix();
}


void updateUI() {
  if (currentDoodle == null) return;

  // Re-plug sliders
  cp5.getController("replaySpeed").plugTo(currentDoodle, "replaySpeed");
  cp5.getController("replaySpeed").setValue(currentDoodle.getReplaySpeed());

  cp5.getController("size").plugTo(currentDoodle, "size");
  cp5.getController("size").setValue(currentDoodle.size);

  cp5.getController("angle").plugTo(currentDoodle, "angle");
  cp5.getController("angle").setValue(currentDoodle.angle);

  // Re-sync toggle
  cp5.get(Toggle.class, "normalize").setValue(currentDoodle.normalized ? 1 : 0);
  
  // Re-generate preset thumbnails
  preset1Img = drawThumbnail(preset1, imageSize);
  preset2Img = drawThumbnail(preset2, imageSize);
  preset3Img = drawThumbnail(preset3, imageSize);
  preset4Img = drawThumbnail(preset4, imageSize);

  // Update images on ControlP5 buttons
  cp5.get(Button.class, "set1").setImages(preset1Img, preset1Img, preset1Img);
  cp5.get(Button.class, "set2").setImages(preset2Img, preset2Img, preset2Img);
  cp5.get(Button.class, "set3").setImages(preset3Img, preset3Img, preset3Img);
  cp5.get(Button.class, "set4").setImages(preset4Img, preset4Img, preset4Img);
}


// keyboard shortcuts
void keyPressed() {
  if (key == 'c' || key == 'C') {
    clear();
  }
  if (key == 's' || key == 'S') {
    save();
  }
  
  if (key == 'p' || key == 'P') {
    startReplay();
  }
  
  if (key == 'y') {
    for (int i = 0; i < currentDoodle.points.size(); i++) {
      println("point: ", i, " position: ", currentDoodle.getPoint(i).pos, " time: ", currentDoodle.getPoint(i).time);
    }
  }
  
  if (key == 'n' || key == 'N') {
    currentDoodle.setNormalized(!currentDoodle.normalized);
    cp5.get(Toggle.class, "normalize").setValue(currentDoodle.normalized ? 1 : 0);  // sync toggle UI
    // startReplay();
  }
  if (key == '1') {
    reset1();
  }
  if (key == '2') {
    reset2();
  }
  if (key == '3') {
    reset3();
  }
  if (key == '4') {
    reset4();
  }
  
  // penHeight
  if (key == '+' || key == '=') {
    penHeight += 0.1;
    println("current height: ", penHeight);
  }
  if (key == '-' || key == '_') {
    penHeight -= 0.1;
    println("current height: ", penHeight);
  }
  
  // yaw
  if (key == '{' || key == '[') {
    yaw -= 1;
    println("current yaw: ", yaw);
  }
  if (key == '}' || key == ']') {
    yaw += 1;
    println("current yaw: ", yaw);
  }
  
  // pitch
  if (key == ';' || key == ':') {
    pitch -= 1;
    println("current pitch: ", pitch);
  }
  if (key == '\'' || key == '\"') {
    pitch += 1;
    println("current pitch: ", pitch);
  }
  
  // roll
  if (key == '.' || key == '>') {
    roll -= 1;
    println("current roll: ", roll);
  }
  if (key == '/' || key == '?') {
    roll += 1;
    println("current roll: ", roll);
  }
} 
