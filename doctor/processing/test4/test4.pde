import peasy.*;
import processing.serial.*;

PeasyCam cam;
Serial myPort;

float tableLength = 70; // Length of the table (in cm)
float tableWidth = 30; // Width of the table (in cm)

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

  // Initialize anchors' positions
  anchor1 = new PVector(tableLength / 2,0, 0); // Top-right corner
  anchor2 = new PVector(-tableLength / 2, tableWidth / 2, 0); // Bottom-left corner
  anchor3 = new PVector(-tableLength / 2, -tableWidth / 2, 0); // Top-left corner

  // Initialize serial communication
  String portName = "COM10"; // Change this to the correct port name if necessary
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
 drawTag(tagPosition);// Draw tag at the calculated position
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

// Function to draw the table
void drawTable() {
  // Bind the texture
fill(200); // Gray color for table
  stroke(0); // Black border for table
  beginShape();
  vertex(-tableLength/2, -tableWidth/2, 0); // Bottom-left corner
  vertex(tableLength/2, -tableWidth/2, 0); // Bottom-right corner
  vertex(tableLength/2, tableWidth/2, 0); // Top-right corner
  vertex(-tableLength/2, tableWidth/2, 0); // Top-left corner
  endShape(CLOSE);
}

// Function to draw the anchors
void drawAnchors() {
  fill(255, 0, 0); // Red color for anchors
  noStroke(); // No border for anchors
  drawAnchor(anchor1, 5, "AABB"); // Draw anchor 1 with radius 5
  drawAnchor(anchor2, 5, "CCDD"); // Draw anchor 2 with radius 5
  drawAnchor(anchor3, 5, "EEFF"); // Draw anchor 3 with radius 5
}

// Function to draw the tag
//void drawTag(PVector position) {
//  fill(0, 0, 255); // Blue color for tag
//  pushMatrix(); // Save the current transformation matrix
//  translate(position.x, position.y, position.z + 5); // Move to tag position
//  rotateY(HALF_PI);
//  // Apply gyro-based rotations
//  rotateX(gyroY * 100); // Rotate around the X-axis
//  rotateY(gyroZ * 100); // Rotate around the Y-axis
//  rotateZ(gyroX * 100); // Rotate around the Z-axis

//  box(10, 5, 5); // Tag with specified dimensions (length, width, height)
//  popMatrix(); // Restore the transformation matrix
//}

void drawTag(PVector position) {
  float boxWidth = 10;
  float boxHeight = 5;
  float boxDepth = 5;

   // Blue color for tag
  pushMatrix();
  translate(position.x, position.y, position.z + 5);// Save the current transformation matrix // Move to tag position
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
  fill(0, 0, 255);
  vertex(-boxWidth / 2, -boxHeight / 2, -boxDepth / 2);
  vertex(-boxWidth / 2, -boxHeight / 2, boxDepth / 2);
  vertex(-boxWidth / 2, boxHeight / 2, boxDepth / 2);
  vertex(-boxWidth / 2, boxHeight / 2, -boxDepth / 2);

  // Right face (yellow)
  fill(0, 0, 255);
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

  // Bottom face (cyan)
  fill(0, 255, 255);
  vertex(-boxWidth / 2, boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, boxHeight / 2, -boxDepth / 2);
  vertex(boxWidth / 2, boxHeight / 2, boxDepth / 2);
  vertex(-boxWidth / 2, boxHeight / 2, boxDepth / 2);

  endShape(CLOSE); // Tag with specified dimensions (length, width, height)
  popMatrix(); // Restore the transformation matrix
}
// Function to draw an anchor
void drawAnchor(PVector anchor, float radius, String label) {
  pushMatrix(); // Save the current transformation matrix
  translate(anchor.x, anchor.y, anchor.z); // Move to anchor position
  sphere(radius); // Anchor with specified radius
  
  // Draw label next to the anchor
  translate(radius + 10, 0, 0); // Move to the right of the anchor
  //text(label, 0, 0); // Draw label
  popMatrix(); // Restore the transformation matrix
}
