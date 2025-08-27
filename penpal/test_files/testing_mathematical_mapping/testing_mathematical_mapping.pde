// Torus-slice debug (axis fixed to world Z)
// Solve cz, Rmaj, beta0, theta from L1..L3 and base anchors.
// This is intentionally simpler than the full rotated-axis solver
// so you can verify the torus-slice geometry visually.

import processing.event.MouseEvent;

PVector[] base = new PVector[3];
float side = 180;
float[] L = {220, 220, 220};

// Unknowns
float cz = 140;
float Rmaj = 260;
float beta0 = 0;
float theta = 1.1f;

boolean paused = false;
float lambda = 1e-3f;
int itersPerFrame = 24;
float stepScale = 0.9f;

/* camera */
float camAzim = radians(35), camElev = radians(22), camDist = 760;
int pmx, pmy; boolean dragging=false;

void setup(){
  size(1000, 760, P3D);
  hint(ENABLE_STROKE_PERSPECTIVE);
  textFont(createFont("Helvetica",12));

  base = equilateral3D(new PVector(-180,0,0), side);
  // recentre base centroid to origin for simplicity
  PVector cent = centroid(base);
  for (int i=0;i<3;i++) base[i].sub(cent);

  // initial guess
  initSimpleGuess();
}

void draw(){
  background(248);
  pushMatrix();
  translate(width/2f, height/2f);
  scale(1, -1, 1);
  rotateX(camElev);
  rotateZ(camAzim);
  translate(0,0,-camDist);

  drawGroundGrid(1000,40);
  drawAxes(140);

  if (!paused) for (int k=0;k<itersPerFrame;k++) solveSimple();

  // render using axis = Z and center at (0,0,cz)
  VecBasis B = makeBasisZ();
  PVector c = new PVector(0,0,cz);

  // base triangle (should coincide with base[] since we fit to it)
  stroke(0,90); strokeWeight(2); noFill(); drawTriangle3D(base);

  // tip triangle at +theta/2
  PVector[] tip = new PVector[3];
  for (int i=0;i<3;i++) tip[i] = tendonPointZ(i, +theta*0.5f, c, B);
  stroke(0,180); drawTriangle3D(tip);

  // tendons (meridians)
  for (int i=0;i<3;i++) drawTendonZ(i, c, B);

  // axis line
  stroke(60,100,220,200); strokeWeight(3);
  PVector p1 = new PVector(0,0,cz-400), p2 = new PVector(0,0,cz+400);
  line(p1.x,p1.y,p1.z, p2.x,p2.y,p2.z);

  popMatrix();
  drawHUD();
}

/* ---------------- math for axis=Z --------------------- */

class VecBasis { PVector a,x,y; VecBasis(PVector A,PVector X,PVector Y){a=A;x=X;y=Y;} }
VecBasis makeBasisZ(){
  PVector a = new PVector(0,0,1);
  PVector x = new PVector(1,0,0);
  PVector y = new PVector(0,1,0);
  return new VecBasis(a,x,y);
}
PVector rhoZ(float beta, VecBasis B){ return B.x.copy().mult(cos(beta)).add(B.y.copy().mult(sin(beta))); }
float rFromL(float Li){ return Li / max(0.01f, theta); } // guard theta

PVector tendonPointZ(int i, float phi, PVector c, VecBasis B){
  float ri = rFromL(L[i]);
  float bi = beta0 + i * TWO_PI/3f;
  PVector rh = rhoZ(bi, B);
  return c.copy().add(rh.copy().mult(Rmaj + ri * cos(phi))).add(B.a.copy().mult(ri * sin(phi)));
}

/* ------------- solver (numeric GN) -------------------- */

void solveSimple(){
  // residuals: P_i(-theta/2) - base[i]  -> 9 residuals
  float[] r = new float[9]; residSimple(r);

  // Jacobian numeric wrt [cz, Rmaj, beta0, theta]
  float[][] J = new float[9][4];
  float[] save = {cz, Rmaj, beta0, theta};
  float[] eps = {1e-3f, 1e-2f, 1e-4f, 1e-4f};

  for (int j=0;j<4;j++){
    applyVarSimple(j, save[j] + eps[j]);
    float[] r2 = new float[9]; residSimple(r2);
    for (int i=0;i<9;i++) J[i][j] = (r2[i] - r[i]) / eps[j];
    applyVarSimple(j, save[j]);
  }

  // normal eqns
  float[][] A = new float[4][4];
  float[] b = new float[4];
  for (int i=0;i<4;i++){
    for (int j=0;j<4;j++){
      float s=0; for (int k=0;k<9;k++) s += J[k][i]*J[k][j];
      A[i][j] = s + (i==j?lambda:0);
    }
    float t=0; for (int k=0;k<9;k++) t += J[k][i]*r[k];
    b[i] = -t;
  }
  float[] d = solveLinearSmall(A,b);
  if (d==null) return;

  // update + guards
  cz   += stepScale * d[0];
  Rmaj += stepScale * d[1];
  beta0 += stepScale * d[2];
  theta = constrain(theta + stepScale * d[3], 0.05f, PI-1e-3f);

  // ensure Rmaj>max(r_i)+margin
  float rmax = max(rFromL(L[0]), max(rFromL(L[1]), rFromL(L[2])));
  if (Rmaj < rmax + 3f) Rmaj = rmax + 3f;
}

void residSimple(float[] out){
  VecBasis B = makeBasisZ();
  PVector c = new PVector(0,0,cz);
  float h = theta*0.5f;
  int k=0;
  for (int i=0;i<3;i++){
    PVector Pm = tendonPointZ(i, -h, c, B);
    out[k++] = Pm.x - base[i].x;
    out[k++] = Pm.y - base[i].y;
    out[k++] = Pm.z - base[i].z;
  }
}

void applyVarSimple(int j, float v){
  switch(j){
    case 0: cz = v; break;
    case 1: Rmaj = v; break;
    case 2: beta0 = v; break;
    case 3: theta = v; break;
  }
}

float[] solveLinearSmall(float[][] A, float[] b){
  int n=4;
  float[][] M = new float[n][n+1];
  for (int i=0;i<n;i++){ for (int j=0;j<n;j++) M[i][j]=A[i][j]; M[i][n]=b[i]; }
  for (int i=0;i<n;i++){
    int piv=i; float mv=abs(M[i][i]);
    for (int r=i+1;r<n;r++) if (abs(M[r][i])>mv){ mv=abs(M[r][i]); piv=r; }
    if (mv < 1e-12f) return null;
    if (piv!=i){ float[] t=M[i]; M[i]=M[piv]; M[piv]=t; }
    float diag=M[i][i];
    for (int j=i;j<=n;j++) M[i][j] /= diag;
    for (int r=0;r<n;r++) if (r!=i){
      float f=M[r][i];
      for (int j=i;j<=n;j++) M[r][j] -= f * M[i][j];
    }
  }
  float[] x = new float[n];
  for (int i=0;i<n;i++) x[i]=M[i][n];
  return x;
}

/* --------------- drawing helpers --------------------- */

void drawTendonZ(int i, PVector c, VecBasis B){
  int steps = 64;
  float h = theta*0.5f;
  stroke(30,120,240,230); strokeWeight(3); noFill();
  beginShape();
  for (int s=0;s<=steps;s++){
    float phi = -h + (2*h)*s/(float)steps;
    PVector p = tendonPointZ(i, phi, c, B);
    vertex(p.x,p.y,p.z);
  }
  endShape();
}

PVector[] equilateral3D(PVector c, float sideLen) {
  PVector[] p = new PVector[3];
  float Rg = sideLen / (float)Math.sqrt(3);
  for (int i = 0; i < 3; i++) {
    float a = -HALF_PI + i * TWO_PI/3f;
    p[i] = new PVector(c.x + Rg*cos(a), c.y + Rg*sin(a), c.z);
  }
  return p;
}
PVector centroid(PVector[] v){ PVector s=new PVector(); for(PVector p:v)s.add(p); s.mult(1f/v.length); return s; }

void initSimpleGuess(){
  cz = 140;
  float Lav = (L[0]+L[1]+L[2])/3f;
  theta = constrain(Lav/160f, 0.3f, 1.6f);
  float r0 = Lav/theta;
  Rmaj = max(120, r0 + 40);
  beta0 = 0;
  for (int k=0;k<40;k++) solveSimple();
}

void drawTriangle3D(PVector[] v) { beginShape(); for (int i=0;i<3;i++) vertex(v[i].x, v[i].y, v[i].z); endShape(CLOSE); }
void drawGroundGrid(float size, int steps) {
  stroke(0,35); strokeWeight(1); float half=size*0.5f;
  for (int i=-steps;i<=steps;i++){ float x=half*i/steps; line(-half,x,0, half,x,0); line(x,-half,0, x,half,0); }
}
void drawAxes(float Lax) {
  strokeWeight(3);
  stroke(200,60,60); line(0,0,0, Lax,0,0);
  stroke(60,170,60); line(0,0,0, 0,Lax,0);
  stroke(60,100,220); line(0,0,0, 0,0,Lax);
  stroke(0,60); strokeWeight(1);
}

void drawHUD(){
  float E=0; float[] rr=new float[9]; residSimple(rr); for(float v:rr) E+=v*v;
  fill(0); noStroke(); textAlign(LEFT,TOP);
  text(String.format("theta: %.3f  Rmaj: %.1f  cz: %.1f  beta0: %.3f  E=%.6g", theta, Rmaj, cz, beta0, E), 12, 12);
  text(String.format("L: [%.1f, %.1f, %.1f]", L[0],L[1],L[2]), 12, 30);
  text("[Q/A,W/S,E/D] change L1..L3   SPACE pause   drag: orbit  wheel: zoom", 12, 48);
}

/* --------------- input ------------------------------- */

void mousePressed(){ dragging=true; pmx=mouseX; pmy=mouseY; }
void mouseReleased(){ dragging=false; }
void mouseDragged(){ if(!dragging) return; float dx=mouseX-pmx, dy=mouseY-pmy; pmx=mouseX; pmy=mouseY; camAzim += 0.005f*dx; camElev += 0.005f*dy; camElev = constrain(camElev, radians(-85), radians(85)); }
void mouseWheel(MouseEvent e){ camDist *= (1.0f + 0.06f*e.getCount()); camDist = constrain(camDist, 220, 2200); }
void keyPressed(){ float d=6; if (key=='q'||key=='Q') L[0]+=d; if (key=='a'||key=='A') L[0]=max(6, L[0]-d); if (key=='w'||key=='W') L[1]+=d; if (key=='s'||key=='S') L[1]=max(6, L[1]-d); if (key=='e'||key=='E') L[2]+=d; if (key=='d'||key=='D') L[2]=max(6, L[2]-d); if (key==' ') paused = !paused; }
