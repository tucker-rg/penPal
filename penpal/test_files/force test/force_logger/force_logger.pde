import processing.serial.*;

Serial myPort;
ArrayList<Float> data = new ArrayList<Float>();
PrintWriter output;

void setup() {
  size(800, 400);
  println(Serial.list());
  
  // Open the first available serial port at 115200
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.bufferUntil('\n');

  output = createWriter("force_data.csv");
  output.println("sample,raw");
}

void draw() {
  background(20);
  stroke(0,255,0);
  noFill();

  // Draw plot
  beginShape();
  for (int i = 0; i < data.size(); i++) {
    float x = map(i, 0, data.size(), 0, width);
    float y = map(data.get(i), 0, 15000, height, 0);
    vertex(x, y);
  }
  endShape();

  fill(255);
  text("Samples: " + data.size(), 10, 20);
  text("Press 'S' to stop + save CSV", 10, 40);
}

void serialEvent(Serial s) {
  String line = trim(s.readStringUntil('\n'));
  if (line != null && line.length() > 0) {
    try {
      float raw = float(line);
      data.add(raw);
      output.println(data.size() + "," + raw);
    } catch (Exception e) {
      println("Bad line: " + line);
    }
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    output.flush();
    output.close();
    println("CSV saved. Stopped logging.");
    noLoop();
  }
}
