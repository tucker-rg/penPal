
// This is where we store the utility motions (line, circle, etc)
// Also, other preset motions, chosen by the user

TimedPoint[] line = new TimedPoint[2];
TimedPoint[] triangle = new TimedPoint[3];
TimedPoint[] circle = new TimedPoint[15];
TimedPoint[] stamp = new TimedPoint[156];

// Also three custom presets
TimedPoint[] preset1 = new TimedPoint[1000];
TimedPoint[] preset2 = new TimedPoint[1000];
TimedPoint[] preset3 = new TimedPoint[1000];
TimedPoint[] preset4 = new TimedPoint[1000];
int preset1Length = 0;
int preset2Length = 0;
int preset3Length = 0;
int preset4Length = 0;
boolean preset1Normalized;
boolean preset2Normalized;
boolean preset3Normalized;
boolean preset4Normalized;

int lineWait = 75;
int triangleWait = 50;
int circleWait = 10;
int stampWait = 30;

void setupUtil() {
  // the line
  PVector lPos0 = new PVector(-6.0, 0.0);
  PVector lPos1 = new PVector(6.0, 0.0);
  line[0] = new TimedPoint(lPos0, 0);
  line[1] = new TimedPoint(lPos1, 0); // we don't care about time here
  
  // the triangle
  PVector[] tPts = new PVector[triangle.length];
  //tPts[0] = new PVector(0.0, 4.0);
  //tPts[1] = new PVector(2.2675, 0.0);
  //tPts[2] = new PVector(4.0, -3.0);
  //tPts[3] = new PVector(0.0, -3.0);
  //tPts[4] = new PVector(-4.0, -3.0);
  //tPts[5] = new PVector(-2.2675, 0.0);
  //tPts[6] = new PVector(0.0, 4.0);
  
  //tPts[0] = new PVector(0.0, 5.8923); // bigger triangle
  //tPts[1] = new PVector(3.40192, 0.0);
  //tPts[2] = new PVector(6, -4.5);
  //tPts[3] = new PVector(0.0, -4.5);
  //tPts[4] = new PVector(-6, -4.5);
  //tPts[5] = new PVector(-3.40192, 0.0);
  
  tPts[0] = new PVector(0.0, 5.8923); // three pointed triangle
  tPts[1] = new PVector(6, -4.5);
  tPts[2] = new PVector(-6, -4.5);
  
  for (int i = 0; i < triangle.length; i++) {
    triangle[i] = new TimedPoint(tPts[i], i);
  }
  
  // the circle
  PVector[] cPts = new PVector[circle.length];
  for (int i = 0; i < circle.length; i++) {
    float angle = radians(i * (360 / circle.length));
    float x = 4 * cos(angle);
    float y = 4 * sin(angle);
    cPts[i] = new PVector(x, y);
    circle[i] = new TimedPoint(cPts[i], 0);
  }
  
  // the stamp (cat)
  PVector[] sPts = new PVector[stamp.length];
  sPts[0] = new PVector(5.4197, 6.1635);
  sPts[1] = new PVector(5.282, 6.0666);
  sPts[2] = new PVector(5.0659, 5.8751);
  sPts[3] = new PVector(5.0659, 5.8751);
  sPts[4] = new PVector(4.7077, 5.5704);
  sPts[5] = new PVector(4.4289, 5.4461);
  sPts[6] = new PVector(4.4289, 5.4461);
  sPts[7] = new PVector(3.9589, 5.4407);
  sPts[8] = new PVector(3.3049, 5.6804);
  sPts[9] = new PVector(3.3049, 5.6804);
  sPts[10] = new PVector(2.9708, 5.8243);
  sPts[11] = new PVector(2.8101, 5.8583);
  sPts[12] = new PVector(2.8101, 5.8583);
  sPts[13] = new PVector(2.7076, 5.8495);
  sPts[14] = new PVector(2.6482, 5.7922);
  sPts[15] = new PVector(2.6482, 5.7922);
  sPts[16] = new PVector(2.5825, 5.6053);
  sPts[17] = new PVector(2.5804, 5.3031);
  sPts[18] = new PVector(2.5804, 5.3031);
  sPts[19] = new PVector(2.6487, 4.8984);
  sPts[20] = new PVector(2.8414, 4.3044);
  sPts[21] = new PVector(2.8414, 4.3044);
  sPts[22] = new PVector(3.0232, 3.7485);
  sPts[23] = new PVector(3.0738, 3.426);
  sPts[24] = new PVector(3.0738, 3.426);
  sPts[25] = new PVector(3.0402, 3.1786);
  sPts[26] = new PVector(2.9224, 3.0006);
  sPts[27] = new PVector(2.9224, 3.0006);
  sPts[28] = new PVector(2.69, 2.8765);
  sPts[29] = new PVector(2.1326, 2.7722);
  sPts[30] = new PVector(2.1326, 2.7722);
  sPts[31] = new PVector(1.0357, 2.5505);
  sPts[32] = new PVector(0.1875, 2.2459);
  sPts[33] = new PVector(0.1875, 2.2459);
  sPts[34] = new PVector(-1.1875, 1.2433);
  sPts[35] = new PVector(-2.1453, -0.2946);
  sPts[36] = new PVector(-2.1453, -0.2946);
  sPts[37] = new PVector(-2.3269, -0.7925);
  sPts[38] = new PVector(-2.5644, -1.5852);
  sPts[39] = new PVector(-2.5644, -1.5852);
  sPts[40] = new PVector(-2.854, -2.4563);
  sPts[41] = new PVector(-3.2484, -2.93);
  sPts[42] = new PVector(-3.2484, -2.93);
  sPts[43] = new PVector(-4.0142, -3.5292);
  sPts[44] = new PVector(-5.0747, -4.0139);
  sPts[45] = new PVector(-5.0747, -4.0139);
  sPts[46] = new PVector(-5.6046, -4.2394);
  sPts[47] = new PVector(-5.8945, -4.4297);
  sPts[48] = new PVector(-5.8945, -4.4297);
  sPts[49] = new PVector(-6.1114, -4.7123);
  sPts[50] = new PVector(-6.2, -5.1039);
  sPts[51] = new PVector(-6.2, -5.1039);
  sPts[52] = new PVector(-6.0469, -5.6365);
  sPts[53] = new PVector(-5.4885, -6.0556);
  sPts[54] = new PVector(-5.4885, -6.0556);
  sPts[55] = new PVector(-5.3102, -6.1305);
  sPts[56] = new PVector(-5.1504, -6.1818);
  sPts[57] = new PVector(-5.1504, -6.1818);
  sPts[58] = new PVector(-4.8809, -6.2);
  sPts[59] = new PVector(-4.7679, -6.1181);
  sPts[60] = new PVector(-4.7679, -6.1181);
  sPts[61] = new PVector(-4.8368, -6.0298);
  sPts[62] = new PVector(-5.0016, -5.8586);
  sPts[63] = new PVector(-5.0016, -5.8586);
  sPts[64] = new PVector(-5.3157, -5.471);
  sPts[65] = new PVector(-5.3214, -5.1664);
  sPts[66] = new PVector(-5.3214, -5.1664);
  sPts[67] = new PVector(-5.0604, -4.8922);
  sPts[68] = new PVector(-4.576, -4.628);
  sPts[69] = new PVector(-4.576, -4.628);
  sPts[70] = new PVector(-3.8765, -4.3651);
  sPts[71] = new PVector(-3.1348, -4.0968);
  sPts[72] = new PVector(-3.1348, -4.0968);
  sPts[73] = new PVector(-2.4596, -3.9576);
  sPts[74] = new PVector(-1.9978, -4.1401);
  sPts[75] = new PVector(-1.9978, -4.1401);
  sPts[76] = new PVector(-1.9436, -4.1816);
  sPts[77] = new PVector(-1.8895, -4.223);
  sPts[78] = new PVector(-1.8895, -4.223);
  sPts[79] = new PVector(-0.7883, -4.2212);
  sPts[80] = new PVector(0.3128, -4.2194);
  sPts[81] = new PVector(0.3128, -4.2194);
  sPts[82] = new PVector(1.4146, -4.2164);
  sPts[83] = new PVector(2.5164, -4.2134);
  sPts[84] = new PVector(2.5164, -4.2134);
  sPts[85] = new PVector(2.5131, -4.1359);
  sPts[86] = new PVector(2.5099, -4.0584);
  sPts[87] = new PVector(2.5099, -4.0584);
  sPts[88] = new PVector(2.3596, -3.6605);
  sPts[89] = new PVector(1.7775, -3.5428);
  sPts[90] = new PVector(1.7775, -3.5428);
  sPts[91] = new PVector(1.5564, -3.5287);
  sPts[92] = new PVector(1.4577, -3.5164);
  sPts[93] = new PVector(1.4577, -3.5164);
  sPts[94] = new PVector(1.5021, -3.3735);
  sPts[95] = new PVector(1.6718, -3.0441);
  sPts[96] = new PVector(1.6718, -3.0441);
  sPts[97] = new PVector(2.1047, -2.3947);
  sPts[98] = new PVector(2.4955, -2.0166);
  sPts[99] = new PVector(2.4955, -2.0166);
  sPts[100] = new PVector(2.6101, -1.9722);
  sPts[101] = new PVector(2.7814, -1.971);
  sPts[102] = new PVector(2.7814, -1.971);
  sPts[103] = new PVector(3.0399, -2.0174);
  sPts[104] = new PVector(3.22, -2.1404);
  sPts[105] = new PVector(3.22, -2.1404);
  sPts[106] = new PVector(3.3158, -2.3028);
  sPts[107] = new PVector(3.3714, -2.6319);
  sPts[108] = new PVector(3.3714, -2.6319);
  sPts[109] = new PVector(3.4098, -2.8705);
  sPts[110] = new PVector(3.4707, -3.0549);
  sPts[111] = new PVector(3.4707, -3.0549);
  sPts[112] = new PVector(4.1317, -3.9265);
  sPts[113] = new PVector(4.921, -4.3312);
  sPts[114] = new PVector(4.921, -4.3312);
  sPts[115] = new PVector(5.0917, -4.2905);
  sPts[116] = new PVector(5.2134, -4.1425);
  sPts[117] = new PVector(5.2134, -4.1425);
  sPts[118] = new PVector(5.2738, -3.9418);
  sPts[119] = new PVector(5.2382, -3.7628);
  sPts[120] = new PVector(5.2382, -3.7628);
  sPts[121] = new PVector(5.1468, -3.6532);
  sPts[122] = new PVector(4.9811, -3.4852);
  sPts[123] = new PVector(4.9811, -3.4852);
  sPts[124] = new PVector(4.4316, -2.7363);
  sPts[125] = new PVector(4.2826, -1.7667);
  sPts[126] = new PVector(4.2826, -1.7667);
  sPts[127] = new PVector(4.4171, -0.6913);
  sPts[128] = new PVector(4.8375, 0.1417);
  sPts[129] = new PVector(4.8375, 0.1417);
  sPts[130] = new PVector(4.9967, 0.3222);
  sPts[131] = new PVector(5.2421, 0.5767);
  sPts[132] = new PVector(5.2421, 0.5767);
  sPts[133] = new PVector(5.7656, 1.2195);
  sPts[134] = new PVector(5.8857, 1.8469);
  sPts[135] = new PVector(5.8857, 1.8469);
  sPts[136] = new PVector(5.8606, 2.2301);
  sPts[137] = new PVector(5.7669, 2.6304);
  sPts[138] = new PVector(5.7669, 2.6304);
  sPts[139] = new PVector(5.6966, 3.2965);
  sPts[140] = new PVector(5.9993, 3.8057);
  sPts[141] = new PVector(5.9993, 3.8057);
  sPts[142] = new PVector(6.2, 4.1049);
  sPts[143] = new PVector(6.1677, 4.5231);
  sPts[144] = new PVector(6.1677, 4.5231);
  sPts[145] = new PVector(6.066, 5.0447);
  sPts[146] = new PVector(5.9967, 5.5266);
  sPts[147] = new PVector(5.9967, 5.5266);
  sPts[148] = new PVector(5.9009, 6.0046);
  sPts[149] = new PVector(5.7317, 6.1707);
  sPts[150] = new PVector(5.7317, 6.1707);
  sPts[151] = new PVector(5.5786, 6.2);
  sPts[152] = new PVector(5.4197, 6.1635);
  sPts[153] = new PVector(5.4197, 6.1635);
  sPts[154] = new PVector(5.4197, 6.1635);
  sPts[155] = new PVector(5.4197, 6.1635);
  
  for (int i = 0; i < stamp.length; i++) {
    stamp[i] = new TimedPoint(sPts[i], i * 30);
  }
}

// Utility functions
void SetLine() {
  clear();
  utilitySetting = 1;
  strokeCount = line.length;
  mode = 3; // BRUTE FORCE
  waitTime = lineWait;
  
  for (int i = 0; i < line.length; i++) {
    stroke[i] = line[i];
  }
  
  // Start replay
  startReplay();
  println("Utility setting: LINE");
}

void SetTriangle() {
  clear();
  utilitySetting = 2;
  strokeCount = triangle.length;
  mode = 3; // BRUTE FORCE
  connectLastPoint = true;
  waitTime = triangleWait;
  
  for (int i = 0; i < triangle.length; i++) {
    stroke[i] = triangle[i];
  }
  
  // Start replay
  startReplay();
  println("Utility setting: TRIANGLE");
}

void SetCircle() {
  clear();
  utilitySetting = 3;
  strokeCount = circle.length;
  mode = 3; // BRUTE FORCE
  connectLastPoint = true;
  waitTime = circleWait;
  
  for (int i = 0; i < circle.length; i++) {
    stroke[i] = circle[i];
  }
  
  // Start replay
  startReplay();
  println("Utility setting: TRIANGLE");
}

void SetStamp() {
  clear();
  utilitySetting = 4;
  strokeCount = stamp.length;
  // mode = 3; // BRUTE FORCE
  mode = 2;
  connectLastPoint = true;
  waitTime = stampWait;
  
  for (int i = 0; i < stamp.length; i++) {
    stroke[i] = stamp[i];
  }
  
  // Start replay
  startReplay();
  println("Utility setting: STAMP");
}

void set1() {
  if (strokeCount == 0 && preset1Length != 0) { // we set the current stroke as preset 1
    normalize = false;
    setNormalize();
    for (int i = 0; i < preset1Length; i++) {
      stroke[i] = preset1[i];
    }
    strokeCount = preset1Length;
    setMode1or2();
    setStrokeContents();
    normalize = preset1Normalized;
    setNormalize();
    startReplay();
  }
  if (strokeCount != 0) { // we set preset1 to the current stroke
    boolean currentlyNormal = normalize;
    normalize = false;
    setNormalize();
    for (int i = 0; i < strokeCount; i++) {
      preset1[i] = stroke[i];
    }
    preset1Length = strokeCount;
    setStrokeContents();
    preset1Normalized = currentlyNormal;
    normalize = currentlyNormal;
    setNormalize();
    drawPresetThumbnail(preset1Img, preset1, preset1Length);
    cp5.get(Button.class, "set1").setImages(preset1Img, preset1Img, preset1Img);
  }
}

void set2() {
  if (strokeCount == 0 && preset2Length != 0) { // we set the current stroke as preset 2
    normalize = false;
    setNormalize();
    for (int i = 0; i < preset2Length; i++) {
      stroke[i] = preset2[i];
    }
    strokeCount = preset2Length;
    setMode1or2();
    setStrokeContents();
    normalize = preset2Normalized;
    setNormalize();
    startReplay();
  }
  if (strokeCount != 0) { // we set preset2 to the current stroke
    boolean currentlyNormal = normalize;
    normalize = false;
    setNormalize();
    for (int i = 0; i < strokeCount; i++) {
      preset2[i] = stroke[i];
    }
    preset2Length = strokeCount;
    setStrokeContents();
    preset2Normalized = currentlyNormal;
    normalize = currentlyNormal;
    setNormalize();
    cp5.get(Toggle.class, "normalize").setValue(normalize ? 1 : 0);  // sync toggle UI
    drawPresetThumbnail(preset2Img, preset2, preset2Length);
    cp5.get(Button.class, "set2").setImages(preset2Img, preset2Img, preset2Img);
  }
}


void set3() {
  if (strokeCount == 0 && preset3Length != 0) { // we set the current stroke as preset 3
    normalize = false;
    setNormalize();
    for (int i = 0; i < preset3Length; i++) {
      stroke[i] = preset3[i];
    }
    strokeCount = preset3Length;
    setMode1or2();
    setStrokeContents();
    normalize = preset3Normalized;
    setNormalize();
    cp5.get(Toggle.class, "normalize").setValue(normalize ? 1 : 0);  // sync toggle UI
    startReplay();
  }
  if (strokeCount != 0) { // we set preset1 to the current stroke
    boolean currentlyNormal = normalize;
    normalize = false;
    setNormalize();
    for (int i = 0; i < strokeCount; i++) {
      preset3[i] = stroke[i];
    }
    preset3Length = strokeCount;
    setStrokeContents();
    preset3Normalized = currentlyNormal;
    normalize = currentlyNormal;
    setNormalize();
    cp5.get(Toggle.class, "normalize").setValue(normalize ? 1 : 0);  // sync toggle UI
    drawPresetThumbnail(preset3Img, preset3, preset3Length);
    cp5.get(Button.class, "set3").setImages(preset3Img, preset3Img, preset3Img);
  }
}

void set4() {
  if (strokeCount == 0 && preset4Length != 0) { // we set the current stroke as preset 4
    normalize = false;
    setNormalize();
    for (int i = 0; i < preset4Length; i++) {
      stroke[i] = preset4[i];
    }
    strokeCount = preset4Length;
    setMode1or2();
    setStrokeContents();
    normalize = preset4Normalized;
    setNormalize();
    cp5.get(Toggle.class, "normalize").setValue(normalize ? 1 : 0);  // sync toggle UI
    startReplay();
  }
  if (strokeCount != 0) { // we set preset1 to the current stroke
    boolean currentlyNormal = normalize;
    normalize = false;
    setNormalize();
    for (int i = 0; i < strokeCount; i++) {
      preset4[i] = stroke[i];
    }
    preset4Length = strokeCount;
    setStrokeContents();
    preset4Normalized = currentlyNormal;
    normalize = currentlyNormal;
    setNormalize();
    cp5.get(Toggle.class, "normalize").setValue(normalize ? 1 : 0);  // sync toggle UI
    drawPresetThumbnail(preset4Img, preset4, preset4Length);
    cp5.get(Button.class, "set4").setImages(preset4Img, preset4Img, preset4Img);
  }
}
