import peasy.*;
import processing.serial.*;

PeasyCam cam;
Serial myPort;

int PPI = 96;  // Pixels per inch of your display
float CM_TO_INCH = 0.393701;  // Conversion factor from cm to inches

float tableLengthCM = 25; // Length of the table in cm
float tableWidthCM = 25; // Width of the table in cm

float tableLength;  // Length of the table in pixels
float tableWidth;  // Width of the table in pixels

PVector anchor1, anchor2, anchor3;
PVector tagPosition = new PVector(0, 0, 0);

float distance1 = -1; // Distance from anchor1 (aabb)
float distance2 = -1; // Distance from anchor2 (ccdd)
float distance3 = -1; // Distance from anchor3 (eeff)

float gyroX = 0, gyroY = 0, gyroZ = 0; // Variables to hold the gyro readings

PImage tableImage;

void setup() {
  size(800, 600, P3D); // Set up canvas with 3D rendering
  cam = new PeasyCam(this, 400); // Create a new PeasyCam object

  tableImage = loadImage("anatomy.jpg");

  // Convert table dimensions from cm to pixels
  tableLength = tableLengthCM * CM_TO_INCH * PPI;
  tableWidth = tableWidthCM * CM_TO_INCH * PPI;

  // Initialize anchors' positions
  anchor1 = new PVector(tableLength / 2, 0, 0); // Top-right corner
  anchor2 = new PVector(-tableLength / 2, tableWidth / 2, 0); // Bottom-left corner
  anchor3 = new PVector(-tableLength / 2, -tableWidth / 2, 0); // Top-left corner

  // Initialize serial communication
  String portName = "COM6"; // Change this to the correct port name if necessary
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n'); // Read data until newline character
}

void draw() {
  background(255); // Clear canvas

  drawTable(); // Draw table
  drawAnchors(); // Draw anchors

  // Read serial data and update tag position and rotation
  if (myPort.available() > 0) {
    String inString = myPort.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      String[] data = split(inString, ',');

      if (data.length == 2) {
        String id = data[0].trim();
        float value = float(data[1].trim());

        // Update distances based on IDs
        if (id.equals("aabb")) {
          distance1 = value * 100; // Convert meters to centimeters
        } else if (id.equals("ccdd")) {
          distance2 = value * 100; // Convert meters to centimeters
        } else if (id.equals("eeff")) {
          distance3 = value * 100; // Convert meters to centimeters
        }

        // Check if all distances are received to perform trilateration
        if (distance1 > -1 && distance2 > -1 && distance3 > -1) {
          tagPosition = trilaterate(anchor1, anchor2, anchor3, distance1, distance2, distance3);
          println("Distances (cm): " + distance1 + ", " + distance2 + ", " + distance3);
          println("Tag Position (cm): " + tagPosition);
          
          // Reset distances after successful trilateration
          distance1 = -1;
          distance2 = -1;
          distance3 = -1;
        }
      } else if (data.length == 3) {
        // Update gyro data
        try {
          gyroX = radians(float(data[0])); // Convert to radians
          gyroY = radians(float(data[1])); // Convert to radians
          gyroZ = radians(float(data[2])); // Convert to radians

          // Print parsed values for debugging
          //println("GyroX: " + gyroX + " GyroY: " + gyroY + " GyroZ: " + gyroZ);
        } catch (NumberFormatException e) {
          println("Failed to parse gyro data: " + inString);
        }
      } else {
        println("Invalid data received: " + inString);
      }
    }
  }
  drawTag(tagPosition); // Draw tag at the calculated position
}

// Function to perform trilateration with three anchors
PVector trilaterate(PVector anchor1, PVector anchor2, PVector anchor3, float distance1, float distance2, float distance3) {
  float x1 = anchor1.x;
  float y1 = anchor1.y;
  float x2 = anchor2.x;
  float y2 = anchor2.y;
  float x3 = anchor3.x;
  float y3 = anchor3.y;

  float A = 2 * (x2 - x1);
  float B = 2 * (y2 - y1);
  float D = 2 * (x3 - x2);
  float E = 2 * (y3 - y2);

  float C = distance1 * distance1 - distance2 * distance2 - x1 * x1 + x2 * x2 - y1 * y1 + y2 * y2;
  float F = distance2 * distance2 - distance3 * distance3 - x2 * x2 + x3 * x3 - y2 * y2 + y3 * y3;

  float x = (C * E - F * B) / (E * A - B * D);
  float y = (C * D - A * F) / (B * D - A * E);

  return new PVector(x, y, 0);
}

// Function to draw the table with a grid
void drawTable() {
  stroke(0); // Black border for table
  fill(200); // Gray color for table

  beginShape();
  vertex(-tableLength / 2, -tableWidth / 2, 0); // Bottom-left corner
  vertex(tableLength / 2, -tableWidth / 2, 0); // Bottom-right corner
  vertex(tableLength / 2, tableWidth / 2, 0); // Top-right corner
  vertex(-tableLength / 2, tableWidth / 2, 0); // Top-left corner
  endShape(CLOSE);

  // Draw the grid
  stroke(150); // Light gray color for grid
  for (int i = -int(tableLength / 2); i <= int(tableLength / 2); i += PPI) {
    line(i, -tableWidth / 2, 0, i, tableWidth / 2, 0); // Vertical lines
  }
  for (int j = -int(tableWidth / 2); j <= int(tableWidth / 2); j += PPI) {
    line(-tableLength / 2, j, 0, tableLength / 2, j, 0); // Horizontal lines
  }
}

// Function to draw the anchors as small thin boxes
void drawAnchors() {
  fill(255, 0, 0); // Red color for anchors
  noStroke(); // No border for anchors

  drawAnchor(anchor1, 5, "AABB"); // Draw anchor 1
  drawAnchor(anchor2, 5, "CCDD"); // Draw anchor 2
  drawAnchor(anchor3, 5, "EEFF"); // Draw anchor 3
}

// Function to draw the tag
void drawTag(PVector position) {
  float boxWidth = 2;
  float boxHeight = 1;
  float boxDepth = 1;

  pushMatrix(); // Save the current transformation matrix
  translate(position.x, position.y, position.z + 5); // Move to tag position
  rotateY(HALF_PI);

  // Apply gyro-based rotations
  rotateX(gyroY * 100); // Rotate around the X-axis
  rotateY(gyroZ * 100); // Rotate around the Y-axis
  rotateZ(gyroX * 100); // Rotate around the Z-axis

  beginShape(QUADS);

  // Front face (red)
  fill(0, 0, 255);
  vertex(-boxWidth / 2, -boxHeight / 2, boxDepth / 2);
  vertex(boxWidth / 2, -boxHeight / 2, boxDepth / 2);
  vertex(boxWidth / 2, boxHeight / 2, boxDepth / 2);
  vertex(-boxWidth / 2, boxHeight / 2, boxDepth / 2);

  // Back face (green)
  fill(0, 0, 255);
  vertex(-boxWidth / 2, -boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, -boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, boxHeight / 2, -boxDepth / 2);
  vertex(-boxWidth / 2, boxHeight / 2, -boxDepth / 2);

  // Left face (blue)
  fill(0, 255, 0);
  vertex(-boxWidth / 2, -boxHeight / 2, -boxDepth / 2);
  vertex(-boxWidth / 2, -boxHeight / 2, boxDepth / 2);
  vertex(-boxWidth / 2, boxHeight / 2, boxDepth / 2);
  vertex(-boxWidth / 2, boxHeight / 2, -boxDepth / 2);

  // Right face (yellow)
  fill(255, 255, 0);
  vertex(boxWidth / 2, -boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, -boxHeight / 2, boxDepth / 2);
  vertex(boxWidth / 2, boxHeight / 2, boxDepth / 2);
  vertex(boxWidth / 2, boxHeight / 2, -boxDepth / 2);

  // Top face (cyan)
  fill(0, 255, 255);
  vertex(-boxWidth / 2, -boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, -boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, -boxHeight / 2, boxDepth / 2);
  vertex(-boxWidth / 2, -boxHeight / 2, boxDepth / 2);

  // Bottom face (magenta)
  fill(255, 0, 255);
  vertex(-boxWidth / 2, boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, boxHeight / 2, boxDepth / 2);
  vertex(-boxWidth / 2, boxHeight / 2, boxDepth / 2);

  endShape();
  popMatrix(); // Restore the transformation matrix
}

// Function to draw an anchor at a given position
void drawAnchor(PVector pos, float size, String label) {
  pushMatrix(); // Save the current transformation matrix
  translate(pos.x, pos.y, pos.z);
  box(size);
  fill(0);
  textSize(12);
  textAlign(CENTER, CENTER);
  text(label, 0, 0);
  popMatrix(); // Restore the transformation matrix
}

// Function to handle key presses (optional)
void keyPressed() {
  if (key == 'r' || key == 'R') {
    // Reset tag position
    tagPosition = new PVector(0, 0, 0);
  }
}
