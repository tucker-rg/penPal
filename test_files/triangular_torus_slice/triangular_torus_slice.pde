// Triangular Torus Slice
// - Defines a triangle (3 vertices) in the XY plane (z = 0).
// - Defines an axis (two points) that lies in the XY plane (z = 0).
// - Rotates (sweeps) the triangle around the axis by angle `theta` (radians).
// - Builds a mesh by sampling `steps` intermediate rotations and connects corresponding vertices.
// - Controls: e (toggle edit mode), +/- angle, [ ] steps, c caps, w wireframe, r reset.
// - In Edit mode you can drag triangle vertices and axis endpoints in top-down view.

PVector[] tri = new PVector[3];
PVector axisP1, axisP2; // axis endpoints (both z = 0)
float theta = PI;        // sweep angle in radians (default 180°)
int steps = 72;          // subdivisions along sweep (higher => smoother)
boolean showCaps = true;
boolean wireframe = false;

float sceneRotX = -0.5, sceneRotY = 0.8; // initial 3D view rotation
float zoomFactor = 1.0;

boolean editMode = false;
int draggingIndex = -1; // 0..2 triangle verts, -2 axisP1, -3 axisP2
float pickRadius = 12;

float lastMouseX, lastMouseY;

void setup() {
  size(1000, 700, P3D);
  // default triangle (centered around origin)
  tri[0] = new PVector(150, -60, 0);
  tri[1] = new PVector(260, 100, 0);
  tri[2] = new PVector(40, 120, 0);
  // default axis (line along +X through left of triangle)
  axisP1 = new PVector(-120, 0, 0);
  axisP2 = new PVector(120, 0, 0);
  smooth(8);
  textFont(createFont("SansSerif", 12));
}

void draw() {
  background(200);
  if (editMode) {
    drawTopDownEdit();
  } else {
    draw3DView();
  }
  drawHUD();
}

void draw3DView() {
  pushMatrix();
  translate(width/2, height/2);
  scale(zoomFactor);
  // basic orbiting
  rotateX(sceneRotX);
  rotateY(sceneRotY);

  lights();
  ambientLight(60, 60, 60);
  directionalLight(200, 200, 200, -0.5, -0.8, -0.3);
  noStroke();

  // Draw axis (as a thin cylinder-like line)
  stroke(255, 180);
  strokeWeight(2);
  line(axisP1.x, axisP1.y, axisP1.z, axisP2.x, axisP2.y, axisP2.z);
  noStroke();

  // Prepare sweep grid: (steps+1) x 3 vertices
  if (steps < 1) steps = 1;
  PVector axisDir = PVector.sub(axisP2, axisP1);
  if (axisDir.mag() == 0) axisDir = new PVector(1, 0, 0);
  axisDir.normalize();

  PVector[][] sweep = new PVector[steps+1][3];
  for (int i = 0; i <= steps; i++) {
    float a = (float)i / steps * theta;
    for (int j = 0; j < 3; j++) {
      sweep[i][j] = rotateAroundAxis(tri[j], axisP1, axisDir, a);
    }
  }

  // Fill material
  colorMode(HSB, 360, 100, 100);
  float hueBase = 210; // bluish
  // draw faces (connect corresponding triangle vertices between consecutive sweep rings)
  for (int i = 0; i < steps; i++) {
    for (int j = 0; j < 3; j++) {
      int jNext = (j + 1) % 3;

      PVector v0 = sweep[i][j];
      PVector v1 = sweep[i][jNext];
      PVector v2 = sweep[i+1][jNext];
      PVector v3 = sweep[i+1][j];

      // First triangle (v0, v1, v2)
      PVector n1 = faceNormal(v0, v1, v2);
      pushStyle();
      ambient((int)map(i, 0, steps, 50, 120)); // slight shading by angle
      fill((hueBase + j*30 + map(i,0,steps,0,40)) % 360, 60, 90);
      beginShape(TRIANGLES);
      normal(n1.x, n1.y, n1.z);
      vertex(v0.x, v0.y, v0.z);
      vertex(v1.x, v1.y, v1.z);
      vertex(v2.x, v2.y, v2.z);
      endShape();

      // Second triangle (v0, v2, v3)
      PVector n2 = faceNormal(v0, v2, v3);
      beginShape(TRIANGLES);
      normal(n2.x, n2.y, n2.z);
      vertex(v0.x, v0.y, v0.z);
      vertex(v2.x, v2.y, v2.z);
      vertex(v3.x, v3.y, v3.z);
      endShape();
      popStyle();
    }
  }

  // Caps
  if (showCaps) {
    // start cap (i = 0)
    PVector a = sweep[0][0], b = sweep[0][1], c = sweep[0][2];
    PVector nStart = faceNormal(a, b, c);
    pushStyle();
    fill((hueBase+180)%360, 40, 92);
    beginShape(TRIANGLES);
    normal(nStart.x, nStart.y, nStart.z);
    vertex(a.x, a.y, a.z);
    vertex(b.x, b.y, b.z);
    vertex(c.x, c.y, c.z);
    endShape();
    popStyle();

    // end cap (i = steps) - orient normal reversed so it faces outward consistently
    PVector d = sweep[steps][0], e = sweep[steps][1], f = sweep[steps][2];
    PVector nEnd = faceNormal(d, f, e); // reverse winding
    pushStyle();
    fill((hueBase+200)%360, 48, 85);
    beginShape(TRIANGLES);
    normal(nEnd.x, nEnd.y, nEnd.z);
    vertex(d.x, d.y, d.z);
    vertex(f.x, f.y, f.z);
    vertex(e.x, e.y, e.z);
    endShape();
    popStyle();
  }

  // Wireframe overlay (optional)
  if (wireframe) {
    stroke(0, 180);
    strokeWeight(1);
    noFill();
    for (int i = 0; i < steps; i++) {
      for (int j = 0; j < 3; j++) {
        int jNext = (j + 1) % 3;
        PVector v0 = sweep[i][j];
        PVector v1 = sweep[i][jNext];
        PVector v2 = sweep[i+1][jNext];
        PVector v3 = sweep[i+1][j];
        // edges
        line(v0.x, v0.y, v0.z, v1.x, v1.y, v1.z);
        line(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
        line(v2.x, v2.y, v2.z, v3.x, v3.y, v3.z);
        line(v3.x, v3.y, v3.z, v0.x, v0.y, v0.z);
      }
    }
  }

  // draw original triangle & axis points as guides
  stroke(255, 220);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int j = 0; j < 3; j++) vertex(tri[j].x, tri[j].y, tri[j].z);
  endShape(CLOSE);
  noStroke();
  fill(255, 150);
  for (int j = 0; j < 3; j++) {
    pushMatrix();
    translate(tri[j].x, tri[j].y, tri[j].z);
    sphereDetail(6);
    sphere(4);
    popMatrix();
  }

  popMatrix();
}

void drawTopDownEdit() {
  // 2D orthographic top-down editing (Z ignored). Origin at center.
  pushMatrix();
  translate(width/2, height/2);
  scale(1);
  // grid
  stroke(60);
  for (int x = -width; x <= width; x += 40) line(x, -height, x, height);
  for (int y = -height; y <= height; y += 40) line(-width, y, width, y);

  // axis
  strokeWeight(3);
  stroke(255, 150, 0);
  line(axisP1.x, axisP1.y, axisP2.x, axisP2.y);
  // axis endpoints
  fill(255, 180, 0);
  noStroke();
  ellipse(axisP1.x, axisP1.y, 12, 12);
  ellipse(axisP2.x, axisP2.y, 12, 12);

  // triangle
  stroke(0, 200);
  strokeWeight(2);
  fill(120, 120);
  beginShape();
  for (int i = 0; i < 3; i++) vertex(tri[i].x, tri[i].y);
  endShape(CLOSE);

  // vertices
  fill(0, 200, 220);
  noStroke();
  for (int i = 0; i < 3; i++) ellipse(tri[i].x, tri[i].y, 12, 12);

  popMatrix();
}

void drawHUD() {
  hint(DISABLE_DEPTH_TEST); // draw HUD on top
  fill(255);
  textAlign(LEFT, TOP);
  String mode = editMode ? "EDIT MODE (top-down): drag vertices & axis endpoints" : "3D VIEW: drag mouse to orbit, mouse wheel to zoom";
  text(mode, 10, 10);
  text("theta: " + degrees(theta, 2) + "°    steps: " + steps + "    caps: " + (showCaps ? "ON" : "OFF") + "    wireframe: " + (wireframe ? "ON" : "OFF"), 10, 30);
  text("Controls: e toggle edit | +/- adjust angle | [ ] steps | c caps | w wireframe | r reset", 10, 50);
  text("Tip: choose an axis that does NOT intersect the triangle for classic 'triangular-torus-slice' appearance", 10, 70);
  hint(ENABLE_DEPTH_TEST);
  
  // --- print arc lengths of swept edges ---
  float[] arcLens = new float[3];
  for (int i = 0; i < 3; i++) {
    float r = distancePointLine(tri[i], axisP1, axisP2);
    arcLens[i] = r * abs(theta);
  }
  println("Arc lengths (one per vertex sweep):",
          nf(arcLens[0],1,3),
          nf(arcLens[1],1,3),
          nf(arcLens[2],1,3));
}

// small helper to print float with limited decimals
float degrees(float rad, int decimals) {
  float d = degrees(rad);
  float p = pow(10, decimals);
  return round(d * p) / p;
}

// --- interaction --- //

void mousePressed() {
  lastMouseX = mouseX;
  lastMouseY = mouseY;
  if (editMode) {
    // pick nearest control (in 2D top-down coordinates)
    PVector m = screenToWorld2D(mouseX, mouseY);
    // pick tri verts
    for (int i = 0; i < 3; i++) {
      if (PVector.dist(m, tri[i]) <= pickRadius) {
        draggingIndex = i;
        return;
      }
    }
    if (PVector.dist(m, axisP1) <= pickRadius) {
      draggingIndex = -2;
      return;
    }
    if (PVector.dist(m, axisP2) <= pickRadius) {
      draggingIndex = -3;
      return;
    }
    draggingIndex = -1;
  } else {
    draggingIndex = -1; // not used
  }
}

void mouseDragged() {
  float dx = mouseX - lastMouseX;
  float dy = mouseY - lastMouseY;
  lastMouseX = mouseX;
  lastMouseY = mouseY;

  if (editMode) {
    if (draggingIndex >= 0 && draggingIndex <= 2) {
      PVector m = screenToWorld2D(mouseX, mouseY);
      tri[draggingIndex].x = m.x;
      tri[draggingIndex].y = m.y;
      tri[draggingIndex].z = 0;
    } else if (draggingIndex == -2) {
      PVector m = screenToWorld2D(mouseX, mouseY);
      axisP1.x = m.x; axisP1.y = m.y; axisP1.z = 0;
    } else if (draggingIndex == -3) {
      PVector m = screenToWorld2D(mouseX, mouseY);
      axisP2.x = m.x; axisP2.y = m.y; axisP2.z = 0;
    }
  } else {
    // orbit
    sceneRotY += dx * 0.01;
    sceneRotX += dy * 0.01;
  }
}

void mouseReleased() {
  draggingIndex = -1;
}

void mouseWheel(processing.event.MouseEvent ev) {
  float e = ev.getCount();
  zoomFactor *= (1 - e * 0.08);
  zoomFactor = constrain(zoomFactor, 0.2, 5);
}

void keyPressed() {
  if (key == 'e' || key == 'E') editMode = !editMode;
  else if (key == '+') theta += radians(5);
  else if (key == '-') theta -= radians(5);
  else if (key == '[') steps = max(1, steps - 4);
  else if (key == ']') steps = min(1024, steps + 4);
  else if (key == 'c' || key == 'C') showCaps = !showCaps;
  else if (key == 'w' || key == 'W') wireframe = !wireframe;
  else if (key == 'r' || key == 'R') resetDefaults();
  // clamp theta for safety
  theta = constrain(theta, -TWO_PI*4, TWO_PI*4); // allow multiple revolutions, but bounded
}

void resetDefaults() {
  tri[0].set(150, -60, 0);
  tri[1].set(260, 100, 0);
  tri[2].set(40, 120, 0);
  axisP1.set(-120, 0, 0);
  axisP2.set(120, 0, 0);
  theta = PI;
  steps = 72;
  showCaps = true;
  wireframe = false;
  sceneRotX = -0.5; sceneRotY = 0.8; zoomFactor = 1;
}

// --- math helpers --- //

// Rotate point p around an axis line that passes through axisPoint and has unit direction axisDir (Rodrigues)
// axisDir must be normalized.
PVector rotateAroundAxis(PVector p, PVector axisPoint, PVector axisDir, float ang) {
  // v = p - a
  PVector v = PVector.sub(p, axisPoint);
  float cosA = cos(ang);
  float sinA = sin(ang);
  PVector term1 = PVector.mult(v, cosA);
  PVector crossUV = cross(axisDir, v);
  PVector term2 = PVector.mult(crossUV, sinA);
  float dot = axisDir.x * v.x + axisDir.y * v.y + axisDir.z * v.z;
  PVector term3 = PVector.mult(axisDir, dot * (1 - cosA));
  PVector vrot = PVector.add(PVector.add(term1, term2), term3);
  return PVector.add(axisPoint, vrot);
}

PVector cross(PVector a, PVector b) {
  return new PVector(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
}

PVector faceNormal(PVector a, PVector b, PVector c) {
  PVector u = PVector.sub(b, a);
  PVector v = PVector.sub(c, a);
  PVector n = cross(u, v);
  float m = n.mag();
  if (m == 0) return new PVector(0, 0, 1);
  n.div(m);
  return n;
}

// Distance from point p to line through a1->a2
float distancePointLine(PVector p, PVector a1, PVector a2) {
  PVector ap = PVector.sub(p, a1);
  PVector ab = PVector.sub(a2, a1);
  float abLen = ab.mag();
  if (abLen == 0) return ap.mag();
  PVector abNorm = PVector.div(ab, abLen);
  PVector proj = PVector.mult(abNorm, ap.dot(abNorm));
  PVector perp = PVector.sub(ap, proj);
  return perp.mag();
}

// small utility: convert mouse screen coords to top-down world coords used in edit mode
PVector screenToWorld2D(float sx, float sy) {
  return new PVector(sx - width/2.0, sy - height/2.0, 0);
}
