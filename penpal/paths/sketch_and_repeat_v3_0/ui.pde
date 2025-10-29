// UI
int outerOffsetX = 80;
int outerOffsetY = 70;
int innerOffset = 30;
int squareSize;
int controlHeight = 25;
int betweenControls = 15;
float replay_speed = 1.0;
int controlX, controlW, controlH, spacer;
int buttonW, buttonH;
int font_size = 10;

// Button images
PGraphics lineImg, triangleImg, circleImg;
PGraphics stampImg;
PGraphics preset1Img, preset2Img, preset3Img, preset4Img;
int image_size;

void setupUI() {
  cp5 = new ControlP5(this);
  
  PFont font = createFont("Arial", font_size);
  cp5.setFont(font);

  squareSize = height - 2 * outerOffsetY;
  controlX = outerOffsetX + squareSize + innerOffset;
  controlW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 3;
  controlH = controlHeight;
  spacer = controlH + betweenControls; 
  
  buttonW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 5;
  buttonH = buttonW / 2;
  
  image_size = (width - outerOffsetX - squareSize - innerOffset - betweenControls * 3 - outerOffsetX) / 4;
  
  createButtonImages();
  
  // Replay speed slider
  cp5.addSlider("replaySpeed")
     .setPosition(controlX, outerOffsetY + betweenControls)
     .setRange(0.1, 2.0)
     .setValue(replay_speed)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label

  // Size slider
  cp5.addSlider("size") 
     .setPosition(controlX, outerOffsetY + spacer + betweenControls)
     .setRange(0.1, 2.0)
     .setValue(size)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label
     
  // Rotation slider
  cp5.addSlider("angle")
     .setPosition(controlX, outerOffsetY + spacer + spacer + betweenControls)
     .setRange(-180, 180)
     .setValue(angle)
     .setSize(controlW, controlH);
     //.setLabel("orientation");  // Hide default label
  
  int buttonY = outerOffsetY + spacer * 3 + betweenControls * 2 + font_size + betweenControls;
  
  // Add label for default strokes (above shape buttons)
  cp5.addLabel("DEFAULT PRESETS:")
     .setPosition(controlX, buttonY - font_size - betweenControls)  // Position above the buttons
     .setFont(font)
     .setColor(color(255));

  // Image buttons using Button with custom images
  cp5.addButton("SetLine")
     .setPosition(controlX, buttonY)
     .setSize(image_size, image_size)
     .setImages(lineImg, lineImg, lineImg); // normal, over, pressed

  cp5.addButton("SetTriangle")
     .setPosition(controlX + image_size + betweenControls, buttonY)
     .setSize(image_size, image_size)
     .setImages(triangleImg, triangleImg, triangleImg);

  cp5.addButton("SetCircle")
     .setPosition(controlX + image_size + betweenControls + image_size + betweenControls, buttonY)
     .setSize(image_size, image_size)
     .setImages(circleImg, circleImg, circleImg);

  cp5.addButton("SetStamp")
     .setPosition(controlX + image_size + betweenControls + image_size + betweenControls + image_size + betweenControls, buttonY)
     .setSize(image_size, image_size)
     .setImages(stampImg, stampImg, stampImg);
  
  // Preset buttons
  int presetY = buttonY + image_size + betweenControls + font_size + betweenControls;
  
  // Add label for custom strokes (above preset buttons)
  cp5.addLabel("CUSTOM PRESETS:")
     .setPosition(controlX, presetY - font_size - betweenControls)  // Position above the preset buttons
     .setFont(font)
     .setColor(color(255));
     
  cp5.addButton("set1")
     .setPosition(controlX, presetY)
     .setSize(image_size, image_size)
     .setImages(preset1Img, preset1Img, preset1Img);

  cp5.addButton("set2")
     .setPosition(controlX + image_size + betweenControls, presetY)
     .setSize(image_size, image_size)
     .setImages(preset2Img, preset2Img, preset2Img);

  cp5.addButton("set3")
     .setPosition(controlX + image_size + betweenControls + image_size + betweenControls, presetY)
     .setSize(image_size, image_size)
     .setImages(preset3Img, preset3Img, preset3Img);
     
  cp5.addButton("set4")
     .setPosition(controlX + image_size + betweenControls + image_size + betweenControls + image_size + betweenControls, presetY)
     .setSize(image_size, image_size)
     .setImages(preset4Img, preset4Img, preset4Img);
     
  int miscButtonY = presetY + image_size + innerOffset;
  // clear button
  cp5.addButton("clear")
     .setLabel("clear")
     .setPosition(controlX, miscButtonY)
     .setSize(controlW / 2, height - miscButtonY - betweenControls - outerOffsetY);
     
  // create a toggle
  cp5.addToggle("normalize")
     .setPosition(0,1)
     .setSize(controlW / 2, height - miscButtonY - betweenControls - outerOffsetY)
     .setPosition(controlX + controlW/2 + betweenControls, miscButtonY)
     ;

}

void drawPresetThumbnail(PGraphics pg, TimedPoint[] stroke, int length) {
  pg.beginDraw();
  pg.background(240);
  pg.stroke(0);
  pg.strokeWeight(2);
  pg.noFill();

  if (length > 1) {
    float padding = 10;
    
    // Step 1: Find bounds of the stroke
    float minX = Float.MAX_VALUE, maxX = -Float.MAX_VALUE;
    float minY = Float.MAX_VALUE, maxY = -Float.MAX_VALUE;

    for (int i = 0; i < length; i++) {
      float x = stroke[i].pos.x;
      float y = stroke[i].pos.y;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    float strokeWidth = maxX - minX;
    float strokeHeight = maxY - minY;

    // Step 2: Compute scale to fit into thumbnail with padding
    float availableW = image_size - 2 * padding;
    float availableH = image_size - 2 * padding;
    float scale = min(availableW / strokeWidth, availableH / strokeHeight);

    // Step 3: Compute offset to center
    float centerX = (minX + maxX) / 2;
    float centerY = (minY + maxY) / 2;
    float canvasCenter = image_size / 2;

    pg.beginShape();
    for (int i = 0; i < length; i++) {
      float x = (stroke[i].pos.x - centerX) * scale + canvasCenter;
      float y = -(stroke[i].pos.y - centerY) * scale + canvasCenter;
      pg.vertex(x, y);
    }
    
    // Optionally connect last point to first
    if (stroke == circle | stroke == stamp | stroke == triangle) {
      float firstX = (stroke[0].pos.x - centerX) * scale + canvasCenter;
      float firstY = -(stroke[0].pos.y - centerY) * scale + canvasCenter;
      pg.vertex(firstX, firstY);
    }
    pg.endShape();
  }

  pg.endDraw();
}



void createButtonImages() {
  lineImg = createGraphics(image_size, image_size);
  triangleImg = createGraphics(image_size, image_size);
  circleImg = createGraphics(image_size, image_size);
  
  stampImg = createGraphics(image_size, image_size);
  
  preset1Img = createGraphics(image_size, image_size);
  preset2Img = createGraphics(image_size, image_size);
  preset3Img = createGraphics(image_size, image_size);
  preset4Img = createGraphics(image_size, image_size);

  drawPresetThumbnail(preset1Img, preset1, preset1Length);
  drawPresetThumbnail(preset2Img, preset2, preset2Length);
  drawPresetThumbnail(preset3Img, preset3, preset3Length);
  drawPresetThumbnail(preset4Img, preset4, preset4Length);
  
  drawPresetThumbnail(stampImg, stamp, stamp.length);
  drawPresetThumbnail(lineImg, line, line.length);
  drawPresetThumbnail(triangleImg, triangle, triangle.length);
  drawPresetThumbnail(circleImg, circle, circle.length);
}

PImage createStampPlaceholder() {
  PGraphics placeholder = createGraphics(image_size, image_size);
  placeholder.beginDraw();
  placeholder.background(240);
  placeholder.fill(100);
  placeholder.textAlign(CENTER, CENTER);
  placeholder.textSize(12);
  placeholder.text("STAMP", 40, 40);
  placeholder.endDraw();
  return placeholder;
}

// draws a square, with the shape inside that the user drew
void drawSquare() {
  stroke(0);
  fill(255);
  strokeWeight(0);
  rect(outerOffsetX, outerOffsetY, squareSize, squareSize);
  
  // constrain drawing to inside the square
  pushMatrix();
  translate(outerOffsetX, outerOffsetY);
  
  // Draw stroke
  stroke(0);
  strokeWeight(5);
  noFill();
  
  if (strokeCount > 0) {
    beginShape();
    for (int i = 0; i < strokeCount; i++) {
      PVector newVertex = toSquareFromGrid(applyTransformations(stroke[i].pos));
      if (inBounds(toScreen(newVertex))) {
        vertex(newVertex.x, newVertex.y);
      }
    }
    if (connectLastPoint) {
      PVector firstVertex = toSquareFromGrid(applyTransformations(stroke[0].pos));
      vertex(firstVertex.x, firstVertex.y);
    }
    endShape();
    
    // Keep track of where the tip is with a red dot
    if (!drawing) {
      PVector currentVertex;
      if (revReplaying) {
        currentVertex = toSquareFromGrid(applyTransformations(stroke[revReplayIndex].pos));
      } else {
        currentVertex = toSquareFromGrid(applyTransformations(stroke[replayIndex].pos));
      }
      if (inBounds(toScreen(currentVertex))) {
        strokeWeight(0);
        fill(255, 0, 0);
        circle(currentVertex.x, currentVertex.y, 20);
      }
    }
  }
  
  popMatrix();
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom("normalize")) {
    normalize = theEvent.getController().getValue() == 1;
    setNormalize();
  }
}

// keyboard shortcuts
void keyPressed() {
  if (key == 'c' || key == 'C') {
    clear();
  }
  if (key == 'n' || key == 'N') {
    normalize = !normalize;
    cp5.get(Toggle.class, "normalize").setValue(normalize ? 1 : 0);  // sync toggle UI
    setNormalize();
  }
  if (key == '1') {
    set1();
  }
  if (key == '2') {
    set2();
  }
  if (key == '3') {
    set3();
  }
} 
