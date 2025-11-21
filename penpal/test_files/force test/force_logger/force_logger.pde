import processing.serial.*;
import javax.swing.JOptionPane;

Serial myPort;
ArrayList<Float> data = new ArrayList<Float>();
boolean saving = false;

void setup() {
  size(800, 400);

  // Print available ports
  //println(Serial.list());

  // *** CHOOSE THE CORRECT INDEX HERE ***
  myPort = new Serial(this, Serial.list()[3], 115200);
  myPort.bufferUntil('\n');

  surface.setTitle("Force Logger");
}

void draw() {
  background(20);

  // Graph
  stroke(0, 255, 0);
  noFill();
  beginShape();
  if (saving) { 
    for (int i = 0; i < data.size(); i++) {
      float x = map(i, 0, max(1, data.size()), 0, width);
      float y = map(data.get(i), 0, 15000, height, 0);
      vertex(x, y);
    }
  }
  endShape();

  // UI text
  fill(255);
  textSize(14);
  text("Samples: " + data.size(), 10, 20);
  text("Press 'S' = Save CSV   |   Press 'D' = Delete Data", 10, 40);
}

void serialEvent(Serial s) {
  String line = trim(s.readStringUntil('\n'));
  if (line == null || line.length() == 0) return;

  try {
    float val = float(line);
    data.add(val);
  } catch (Exception e) {
    println("Bad line: " + line);
  }
}

void keyPressed() {

  // -----------------------------
  // DELETE DATA WITHOUT SAVING
  // -----------------------------
  if (key == 'd' || key == 'D') {
    data.clear();
    println("Data cleared without saving.");
    saving = false;
  }

  // -----------------------------
  // SAVE DATA AS CSV + CLEAR DATA
  // -----------------------------
  if (key == 's' || key == 'S') {
    if (saving) {
      // Ask user for filename
      String filename = JOptionPane.showInputDialog("Enter CSV filename (no extension):");
  
      if (filename == null || filename.trim().equals("")) {
        println("Save cancelled (empty filename).");
        return;
      }
  
      filename = filename.trim() + ".csv";
  
      PrintWriter output = createWriter(filename);
      output.println("sample,raw");
  
      for (int i = 0; i < data.size(); i++) {
        output.println((i+1) + "," + data.get(i));
      }
  
      output.flush();
      output.close();
  
      println("Saved: " + filename);
  
      data.clear();   // Reset buffer for next run
      saving = false;
    } else {
      saving = true;
    }
  }
}
