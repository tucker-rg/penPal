String[] lines;
PrintWriter output;

void setup() {
  lines = loadStrings("input.txt");
  output = createWriter("output.txt");

  for (String line : lines) {
    line = line.trim();

    // Remove escaped braces and trailing backslash-comma
    line = line.replaceAll("\\\\", ""); // remove backslashes
    line = line.replaceAll(",$", "");   // remove trailing comma

    // Wrap into desired format
    if (line.startsWith("{") && line.endsWith("}")) {
      output.println("lookup[i++] = new float[] " + line + ";");
    }
  }

  output.flush();
  output.close();
  println("Done!");
}
