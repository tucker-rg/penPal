// Triangular Torus Slice
// - Defines a triangle (3 vertices) in the XY plane (z = 0).
// - Defines an axis (two points) that lies in the XY plane (z = 0).
// - Rotates (sweeps) the triangle around the axis by angle `theta` (radians).
// - Builds a mesh by sampling `steps` intermediate rotations and connects corresponding vertices.
// - Controls: e (toggle edit mode), +/- angle, [ ] steps, c caps, w wireframe, r reset.
// - In Edit mode you can drag triangle vertices and axis endpoints in top-down view.

import processing.serial.*;
import java.util.*;
import quickhull3d.*;  // if you put QuickHull3D.java in /code

Serial myPort;

// all units in mm
float s = 10;
float R = s / sqrt(3);        // distance from center to each vertex
float r = s / (2*sqrt(3));    // distance from center to each side (inradius)

PVector[] tri = {
  new PVector(0,   R),
  new PVector(-s/2, -r),
  new PVector( s/2, -r)
};

float tipLength = 13.0;
float spoolDiameter = 14.0; // in mm

PVector axisP1, axisP2; // axis endpoints (both z = 0)
float theta;        // sweep angle in radians (default 180°)
int steps = 72;          // subdivisions along sweep (higher => smoother)

PVector lastAxisPoint = null;
PVector lastAxisDir = null;
float lastTheta = 0;
boolean lastSolutionOK = false;
PVector lastTarget = null;
boolean offlineMode = true;

MotorCommand penControl = new MotorCommand();

// For viewer
float sceneRotX = -0.5, sceneRotY = 0.8; // initial 3D view rotation
float zoomFactor = 4.0;

ArrayList<PVector> reachablePoints = new ArrayList<PVector>();
int selectedPoint = -1;
boolean drawHull = true;
boolean drawCloud = true;
boolean drawHullEdges = true;

void setup() {
  size(1000, 700, P3D);
  //findReachablePoints();
  findReachablePointsSpherical();
  //findReachablePointsCylindrical();
  // smooth(8);
  // textFont(createFont("SansSerif", 12));
  
  if (!offlineMode) {
    println("setting up serial");
    // Serial setup
    printArray(Serial.list());
    String portName = Serial.list()[3];  // Adjust index as needed
    myPort = new Serial(this, portName, 115200); //57600
    myPort.bufferUntil('\n');  // trigger serialEvent on newline
  }
  
  selectedPoint = 0;
  drawTendons(reachablePoints.get(selectedPoint));
  selectedPoint = -1;
}

void draw() {
  background(200);
  draw3DView();
  drawHUD();
}

void findReachablePoints() {
  // iterate through all the points to find the reachable ones
  for (float z = 10; z < 50; z+= 3) {
    for (float x = -100; x <= 100; x+= 10) {
      for (float y = -100; y <= 100; y+= 10) {
        PVector point = new PVector(x, y, z);
        if (isReachable(point)) {
          reachablePoints.add(point);
          println("added point: ", point);
        }
      }
    }
  }
}

void findReachablePointsCylindrical() {
  float zMin = 10;
  float zMax = 100;
  float zStep = 2;            // vertical layers
  float rMax = 100;           // max radius
  int baseRadialDiv = 30;     // radial rings per layer
  int baseThetaDiv = 72;      // angular divisions

  for (float z = zMin; z <= zMax; z += zStep) {
    int numRadial = baseRadialDiv;
    int numTheta  = baseThetaDiv;

    // total points in this layer
    int totalPoints = numRadial * numTheta;

    // enforce divisibility by 3
    if (totalPoints % 3 != 0) {
      totalPoints += (3 - (totalPoints % 3));  
    }

    // adjust numTheta (angular resolution) to enforce divisibility
    numTheta = totalPoints / numRadial;

    for (int i = 1; i <= numRadial; i++) {
      // distribute radii evenly out to rMax
      float r = rMax * i / numRadial;

      for (int j = 0; j < numTheta; j++) {
        float theta = map(j, 0, numTheta, 0, TWO_PI);

        float x = r * cos(theta);
        float y = r * sin(theta);

        PVector point = new PVector(x, y, z);
        if (isReachable(point)) {
          reachablePoints.add(point);
          println("added point:", point);
        }
      }
    }
  }
}

void findReachablePointsSpherical() {
  float rMin = 5;
  float rMax = 70;
  float rStep = 3;            // radial shells
  int basePhi   = 72;         // baseline latitude divisions
  int baseTheta = 144;         // baseline longitude divisions

  for (float r = rMin; r <= rMax; r += rStep) {
    // optionally: scale density with radius if desired
    int numPhi = basePhi;
    int numTheta = baseTheta;

    // total points in shell
    int totalPoints = numPhi * numTheta;

    // round to nearest multiple of 3
    if (totalPoints % 3 != 0) {
      totalPoints += (3 - (totalPoints % 3));  
    }

    // recompute numTheta to match this total (while keeping numPhi fixed)
    numTheta = totalPoints / numPhi;

    for (int i = 0; i < numPhi; i++) {
      // uniform in cos(phi)
      float u = map(i, 0, numPhi-1, -1, 1);  

      for (int j = 0; j < numTheta; j++) {
        float theta = map(j, 0, numTheta, 0, TWO_PI);

        float x = r * sqrt(1 - u*u) * cos(theta);
        float y = r * sqrt(1 - u*u) * sin(theta);
        float z = r * u;

        PVector point = new PVector(x, y, z);
        if (isReachable(point) && z > 10) {
          reachablePoints.add(point);
          println("added point:", point);
        }
      }
    }
  }
}

boolean isReachable(PVector point) {
  float[] tendonLengths = getTendonLengths(point);
  float[] motorPositions;
  motorPositions = new float[3];
  
  if (tendonLengths != null) {
    motorPositions = getMotorPositions(tendonLengths);
  }
  
  if (motorPositions != null) {
    return true;
  }
  return false;
}

// for some 3-dimensional tendonLengths PVector, finds the motor positions (or returns null if they are invalid)
float[] getMotorPositions(float[] tendonLengths) {
  float[] motorPositions;
  motorPositions = new float[3];
  for (int i = 0; i < 3; i++) {
    motorPositions[i] = arcLengthToMotorPosition(tendonLengths[i]);
  }
  // println("found motor positions: (", motorPositions[0], ", ", motorPositions[1], ", ", motorPositions[2], ")");
  
  
  if (motorPositions[0] < 10 || motorPositions[0] > 310 || motorPositions[1] < 10 || motorPositions[1] > 310 || motorPositions[2] < 10 || motorPositions[2] > 310) {
    println("invalid motor motorPositions, returning null");
    return null;
  }
  return motorPositions;
}
  
float arcLengthToMotorPosition(float arcLength) {
  return arcLength * 360 / (PI * spoolDiameter) - 10;
}

void draw3DView() {
  pushMatrix();
  translate(width/2, height/2);
  scale(zoomFactor);
  rotateX(sceneRotX);
  rotateY(sceneRotY);

  lights();
  ambientLight(60, 60, 60);
  directionalLight(200, 200, 200, -0.5, -0.8, -0.3);

  // --- draw triangle ---
  stroke(255, 220);
  strokeWeight(1);
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
    sphere(2);
    popMatrix();
  }
  
  // inside draw3DView()
  if (selectedPoint == -1) {
    // draw all red dots
    fill(255,0,0);
    if (drawCloud) {
      for (PVector p : reachablePoints) {
        pushMatrix();
        translate(p.x, p.y, p.z);
        sphere(0.2);
        popMatrix();
      }
    }
  } else {
    // first, we draw the other ones anyways
    fill(200, 150);
    if (drawCloud) {
      for (PVector p : reachablePoints) {
        pushMatrix();
        translate(p.x, p.y, p.z);
        sphere(0.2);
        popMatrix();
      }
    }
    // now, draw the selected one in red (and bigger)
    PVector p = reachablePoints.get(selectedPoint);
    fill(255,0,0);
    pushMatrix();
    translate(p.x, p.y, p.z);
    sphere(1);
    popMatrix();
    
    drawTendons(p);
    // write out the location
    // println("Selected point: (" + nf(p.x,1,2) + ", " + nf(p.y,1,2) + ", " + nf(p.z,1,2) + ")");
    
  }
  if (drawHull) {
    buildHull();
    //buildSmoothHull();
  }

  popMatrix();
}

void drawTendons(PVector point) {
  findAxisAndThetaForTipEnd(point);

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
  
  // --- Draw tip line from final cap center ---
  if (steps > 0) {
    // get final cap triangle vertices
    PVector aCap = sweep[steps][0];
    PVector bCap = sweep[steps][1];
    PVector cCap = sweep[steps][2];

    // centroid of cap
    PVector capCentroid = new PVector(
      (aCap.x + bCap.x + cCap.x)/3.0,
      (aCap.y + bCap.y + cCap.y)/3.0,
      (aCap.z + bCap.z + cCap.z)/3.0
    );

    // cap normal (outward-facing)
    PVector nCap = faceNormal(aCap, bCap, cCap);
    nCap.normalize();

    // tip endpoint
    PVector tipEnd = PVector.add(capCentroid, PVector.mult(nCap, tipLength));

    // draw line
    stroke(255, 0, 0);
    strokeWeight(1);
    line(capCentroid.x, capCentroid.y, capCentroid.z,
         tipEnd.x, tipEnd.y, tipEnd.z);

    // small sphere at tip end
    noStroke();
    fill(255, 0, 0);
    pushMatrix();
    translate(tipEnd.x, tipEnd.y, tipEnd.z);
    sphereDetail(6);
    sphere(0.2);
    popMatrix();
  }
}

void drawHUD() {
  hint(DISABLE_DEPTH_TEST); // draw HUD on top
  fill(255);
  textAlign(LEFT, TOP);
  text("theta: " + degrees(theta, 2), 10, 10);
  text("Controls: space to toggle shell/point selection, h to toggle hull, e to toggle hull edges, c to toggle point cloud, r to reset camera", 10, 30);
  //text("Tip: choose an axis that does NOT intersect the triangle for classic 'triangular-torus-slice' appearance", 10, 70);
  hint(ENABLE_DEPTH_TEST);
  // --- print arc lengths of swept edges ---
  float[] arcLens = new float[3];
  for (int i = 0; i < 3; i++) {
    float r = distancePointLine(tri[i], axisP1, axisP2);
    arcLens[i] = r * abs(theta);
  }
  text("Arc lengths (one per vertex sweep): " +
          nf(arcLens[0],1,3) + ", " +
          nf(arcLens[1],1,3) + ", " +
          nf(arcLens[2],1,3), 10, 50);
          
  text("motor commands: " +
          nf(arcLengthToMotorPosition(arcLens[0])) + ", " +
          nf(arcLengthToMotorPosition(arcLens[1])) + ", " +
          nf(arcLengthToMotorPosition(arcLens[2])), 10, 70);
  if (selectedPoint != -1) {
    text("position: " + reachablePoints.get(selectedPoint), 10, 90);
  }
}


void buildHull() {
  // 1) Build from Point3d[]
  quickhull3d.Point3d[] pts = new quickhull3d.Point3d[reachablePoints.size()];
  for (int i = 0; i < reachablePoints.size(); i++) {
    PVector p = reachablePoints.get(i);
    pts[i] = new quickhull3d.Point3d(p.x, p.y, p.z);
  }

  QuickHull3D hull = new QuickHull3D();
  hull.build(pts);

  // 2) Use the hulls own vertex array for indexing
  quickhull3d.Point3d[] verts = hull.getVertices();
  int[][] faces = hull.getFaces();

  // 3) Draw (optionally triangulate if you prefer)
  fill(100, 100, 255, 100);
  stroke(0, 0, 100);
  if (drawHullEdges) {
    strokeWeight(0.5);
  } else {
    strokeWeight(0);
  }

  for (int i = 0; i < faces.length; i++) {
    int[] f = faces[i];

    beginShape(); // polygon is convex
    for (int j = 0; j < f.length; j++) {
      quickhull3d.Point3d v = verts[f[j]];
      vertex((float)v.x, (float)v.y, (float)v.z);
    }
    endShape(CLOSE);
  }
}

void buildSmoothHull() {
  // 1) Build from Point3d[]
  quickhull3d.Point3d[] pts = new quickhull3d.Point3d[reachablePoints.size()];
  for (int i = 0; i < reachablePoints.size(); i++) {
    PVector p = reachablePoints.get(i);
    pts[i] = new quickhull3d.Point3d(p.x, p.y, p.z);
  }

  QuickHull3D hull = new QuickHull3D();
  hull.build(pts);

  // 2) Use the hull's own vertex array for indexing
  quickhull3d.Point3d[] verts = hull.getVertices();
  int[][] faces = hull.getFaces();

  // 3) Precompute vertex normals for smooth shading
  PVector[] vertexNormals = new PVector[verts.length];
  for (int i = 0; i < verts.length; i++) {
    vertexNormals[i] = new PVector(0, 0, 0);
  }

  // Calculate face normals and accumulate to vertices
  for (int i = 0; i < faces.length; i++) {
    int[] face = faces[i];
    if (face.length < 3) continue;
    
    // Calculate face normal
    quickhull3d.Point3d v0 = verts[face[0]];
    quickhull3d.Point3d v1 = verts[face[1]];
    quickhull3d.Point3d v2 = verts[face[2]];
    
    PVector a = new PVector((float)(v1.x - v0.x), (float)(v1.y - v0.y), (float)(v1.z - v0.z));
    PVector b = new PVector((float)(v2.x - v0.x), (float)(v2.y - v0.y), (float)(v2.z - v0.z));
    PVector faceNormal = a.cross(b);
    faceNormal.normalize();
    
    // Accumulate to all vertices of this face
    for (int j = 0; j < face.length; j++) {
      int vertexIndex = face[j];
      vertexNormals[vertexIndex].add(faceNormal);
    }
  }

  // Normalize all vertex normals
  for (int i = 0; i < vertexNormals.length; i++) {
    vertexNormals[i].normalize();
  }

  // 4) Draw with smooth shading
  fill(100, 100, 255, 100);
  noStroke(); // Remove edges for smoother appearance
  lights();   // Enable lighting
  
  for (int i = 0; i < faces.length; i++) {
    int[] face = faces[i];
    
    beginShape();
    for (int j = 0; j < face.length; j++) {
      int vertexIndex = face[j];
      quickhull3d.Point3d v = verts[vertexIndex];
      PVector n = vertexNormals[vertexIndex];
      normal(n.x, n.y, n.z);
      vertex((float)v.x, (float)v.y, (float)v.z);
    }
    endShape(CLOSE);
  }
}

void drawDimLine(PVector p1, PVector p2, String label) {
  float x1 = screenX(p1.x, p1.y, p1.z);
  float y1 = screenY(p1.x, p1.y, p1.z);
  float x2 = screenX(p2.x, p2.y, p2.z);
  float y2 = screenY(p2.x, p2.y, p2.z);
  
  line(x1, y1, x2, y2);
  text(label, (x1 + x2) * 0.5, (y1 + y2) * 0.5 - 10); // offset label a bit
}


float[] getTendonLengths(PVector pos) {
  // --- find arc lengths of swept edges ---
  boolean foundLengths = findAxisAndThetaForTipEnd(pos); // first we send the pen to the position
  
  float[] arcLens;
  arcLens = new float[3];
  
  if (foundLengths && abs(theta) < PI / 2) { // we can use the axis and theta stuff (we enforce a 90 degree limit)
    for (int i = 0; i < 3; i++) {
      float r = distancePointLine(tri[i], axisP1, axisP2);
      arcLens[i] = r * abs(theta);
    }
  }
  
  if (!foundLengths) {
    if (pos.x == 0 && pos.y == 0 && pos.z > tipLength) { // if the desired point is directly ahead
      // println("our position is just directly ahead");
      for (int i = 0; i < 3; i++) {
        arcLens[i] = pos.z - tipLength;
      }
    }
  }
  return arcLens;
}

// small helper to print float with limited decimals
float degrees(float rad, int decimals) {
  float d = degrees(rad);
  float p = pow(10, decimals);
  return round(d * p) / p;
}

// --- main solver ---
// Returns true if a solution was found (axis in z=0 plane and theta), false otherwise.
// Prints axis point, unit direction, theta, and verification error.
// target: PVector (can be arbitrary 3D)

boolean findAxisAndThetaForTipEnd(PVector target) {
  return findAxisAndThetaForTipEnd(target, true);
}

boolean findAxisAndThetaForTipEnd(PVector target, boolean tryFlipNormal) {
  final float EPS = 1e-8f;
  PVector C = centroidOfTriangle();                 // centroid of triangle
  PVector n0 = faceNormal(tri[0], tri[1], tri[2]);  // initial cap normal (unit)
  n0.normalize();

  lastTarget = target.copy();

  // Build initial tip endpoint S (before any rotation)
  PVector S = PVector.add(C, PVector.mult(n0, tipLength));

  // Try solving; if no solution and tryFlipNormal==true, try -n0
  boolean ok = solvePointRotation(S, target, n0);
  if (!ok && tryFlipNormal) {
    // try flipping the initial normal (user might have wanted the other face side)
    PVector nFlip = PVector.mult(n0, -1);
    PVector Sflip = PVector.add(C, PVector.mult(nFlip, tipLength));
    ok = solvePointRotation(Sflip, target, nFlip);
    if (ok) {
      println("Solved only after flipping initial normal (used -n0).");
    }
  }
  if (!ok) {
    println("findAxisAndThetaForTipEnd(): NO SOLUTION found for target.");
  }
  
  return ok;
}

// --- low-level solver that maps point S -> target by rotation about some axis with direction u in z=0 ---
// The function chooses u perpendicular to the XY projection of (target - S) (the necessary condition),
// then solves two linear equations for axis point A = (Ax,Ay,0), then computes theta.
// Returns true if verification distance < tolerance.
boolean solvePointRotation(PVector S, PVector target, PVector usedNormal /* for reporting only */) {
  final float EPS = 1e-9f;
  PVector d = PVector.sub(target, S);
  float dx = d.x, dy = d.y, dz = d.z;

  // Degenerate: same XY projection but different Z -> impossible for axis constrained to z=0
  if (abs(dx) < EPS && abs(dy) < EPS) {
    if (abs(dz) < EPS) {
      // trivial: S == target
      lastAxisDir = new PVector(1, 0, 0);
      lastAxisPoint = new PVector((S.x + target.x)/2f, (S.y + target.y)/2f, 0);
      lastTheta = 0;
      lastSolutionOK = true;
      lastTarget = target.copy();
      println("Trivial: target equals initial tip endpoint (theta = 0).");
      return true;
    } else {
      println("NO SOLUTION: target shares XY projection with S but different Z — impossible with axis in z=0.");
      lastSolutionOK = false;
      return false;
    }
  }

  // Choose axis direction u in XY plane perpendicular to (target - S) projection
  PVector u = new PVector(-dy, dx, 0);
  if (u.mag() < EPS) {
    println("Numerical degeneracy when choosing axis direction u.");
    lastSolutionOK = false;
    return false;
  }
  u.normalize();

  // canonicalize direction so results are stable (optional)
  if (u.x < -EPS || (abs(u.x) < EPS && u.y < 0)) u.mult(-1);

  // Two linear equations for Ax,Ay:
  // (1) u_x * Ax + u_y * Ay = u · S    (we pick axis point A so that (S-A) has zero component along u)
  // (2) d_x * Ax + d_y * Ay = (|target|^2 - |S|^2) / 2   (derived from |target - A|^2 = |S - A|^2)
  float e = u.dot(S);
  float rhs = (target.x*target.x + target.y*target.y + target.z*target.z
             - (S.x*S.x + S.y*S.y + S.z*S.z)) * 0.5f;

  float det = u.x * d.y - u.y * d.x;
  if (abs(det) < 1e-10f) {
    println("Degenerate linear system (det ~= 0). Can't find unique axis point A with this method.");
    lastSolutionOK = false;
    return false;
  }

  float Ax = ( e * d.y - u.y * rhs ) / det;
  float Ay = ( u.x * rhs - e * d.x ) / det;
  PVector A = new PVector(Ax, Ay, 0);

  // vectors relative to A
  PVector v = PVector.sub(S, A);
  PVector w = PVector.sub(target, A);

  // compute signed angle theta (using axis direction u for sign via triple product)
  PVector crossVW = cross(v, w);
  float numer = u.dot(crossVW);
  float denom = v.dot(w);
  float thetaFound = atan2(numer, denom);

  // Verify by rotating S around axis (A,u,thetaFound)
  PVector Srot = rotateAroundAxis(S, A, u, thetaFound);
  float err = PVector.dist(Srot, target);

  // store results globally for drawing/inspection
  lastAxisPoint = A.copy();
  lastAxisDir = u.copy();
  lastTheta = thetaFound;
  lastSolutionOK = (err < 1e-4f);
  lastTarget = target.copy();

  // print nicely
  //println("=== findAxisAndThetaForTipEnd() result ===");
  //println("Initial tip S = " + nf(S.x,1,4) + ", " + nf(S.y,1,4) + ", " + nf(S.z,1,4));
  //println("Target T      = " + nf(target.x,1,4) + ", " + nf(target.y,1,4) + ", " + nf(target.z,1,4));
  //println("Axis point A  = " + nf(A.x,1,5) + ", " + nf(A.y,1,5) + ", 0.00000");
  //println("Axis dir u    = " + nf(u.x,1,6) + ", " + nf(u.y,1,6) + ", " + nf(u.z,1,6));
  //println("Theta (rad)   = " + nf(thetaFound,1,6) + "   Theta (deg) = " + nf(degrees(thetaFound),1,4));
  //println("Verification: |rotate(S) - T| = " + nf(err,1,6));
  //if (!lastSolutionOK) println("WARNING: verification error is large — solution may be unstable.");

  // setting the actual display
  axisP1 = A;
  axisP2 = PVector.add(A, u);
  theta = thetaFound;
  
  if (axisIntersectsTriangle()) {
    return false;
  }
  
  return lastSolutionOK;
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

// --- centroid helper ---
PVector centroidOfTriangle() {
  //PVector c = new PVector(0,0,0);
  //for (int i = 0; i < 3; i++) c.add(tri[i]);
  //c.div(3.0);
  //return c;
  
  PVector c = new PVector(0, 0, 0);
  return c;
}

void mousePressed() {
  // Apply same transforms as draw3DView before calling screenX/Y
  pushMatrix();
  translate(width/2, height/2);
  scale(zoomFactor);
  rotateX(sceneRotX);
  rotateY(sceneRotY);

  int hitIndex = -1;
  for (int i = 0; i < reachablePoints.size(); i++) {
    PVector p = reachablePoints.get(i);
    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);
    if (dist(mouseX, mouseY, sx, sy) < 8 && selectedPoint == -1) {
      hitIndex = i;
      break;
    }
  }

  popMatrix();

  if (hitIndex != -1) {
    selectedPoint = hitIndex;
    println("Selected " + hitIndex + " at " + reachablePoints.get(hitIndex));
    penControl.sendMotorCommand(reachablePoints.get(hitIndex));
  }
}

boolean axisIntersectsTriangle() {
  // direction vector of axis
  PVector d = PVector.sub(axisP2, axisP1);

  // check intersection with each triangle edge
  for (int i = 0; i < 3; i++) {
    PVector v1 = tri[i];
    PVector v2 = tri[(i+1) % 3];

    PVector e = PVector.sub(v2, v1);       // edge vector
    float det = d.x * e.y - d.y * e.x;     // determinant

    if (abs(det) > 1e-6) { // not parallel
      PVector diff = PVector.sub(v1, axisP1);
      float t = (diff.x * e.y - diff.y * e.x) / det;
      float u = (diff.x * d.y - diff.y * d.x) / det;
      if (u >= 0 && u <= 1) {
        return true; // infinite line crosses segment
      }
    }
  }

  // finally, check if axisP1 lies inside the triangle -> means line passes through it
  if (pointInTriangle(axisP1, tri[0], tri[1], tri[2])) return true;

  return false;
}

// helper: point in triangle
boolean pointInTriangle(PVector p, PVector a, PVector b, PVector c) {
  float d1 = sign(p, a, b);
  float d2 = sign(p, b, c);
  float d3 = sign(p, c, a);
  boolean hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
  boolean hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
  return !(hasNeg && hasPos);
}

// helper to compute orientation sign
float sign(PVector p1, PVector p2, PVector p3) {
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}


void mouseDragged() {
  sceneRotY += (mouseX - pmouseX) * 0.01;
  sceneRotX -= (mouseY - pmouseY) * 0.01;
  println("y: ", sceneRotY, " x: ", sceneRotX);
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoomFactor *= (1 - e * 0.05);
}

void resetView() {
  sceneRotX = 0.75;   // look straight down -Z
  sceneRotY = 0;   // no sideways rotation
  zoomFactor = 5.0; // default zoom
}

void keyPressed() {
  if (key == ' ') {
    selectedPoint = -1;
  }
  if (key == 'h') {
    drawHull = !drawHull;
  }
  if (key == 'c') {
    drawCloud = !drawCloud;
  }
  if (key == 'e') {
    drawHullEdges = !drawHullEdges;
  }
  if (key == 'r') {   // <--- reset camera with 'r'
    resetView();
  }
}
