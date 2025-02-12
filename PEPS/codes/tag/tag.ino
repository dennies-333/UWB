#include <SPI.h>
#include "DW1000Ranging.h"
#include "DW1000.h"

//makerfabs
#define SPI_SCK 18
#define SPI_MISO 19
#define SPI_MOSI 23
#define DW_CS 4

// connection pins
const uint8_t PIN_RST = 27; // reset pin
const uint8_t PIN_IRQ = 34; // irq pin
const uint8_t PIN_SS = 4;
 
// TAG antenna delay defaults to 16384
// leftmost two bytes below will become the "short address"
char tag_addr[] = "7D:00:22:EA:82:60:3B:9C";
 
void setup()
{
  Serial.begin(115200);
  delay(1000);
 
  //init the configuration
  SPI.begin(SPI_SCK, SPI_MISO, SPI_MOSI);
  DW1000Ranging.initCommunication(PIN_RST, PIN_SS, PIN_IRQ); //Reset, CS, IRQ pin
 
  DW1000Ranging.attachNewRange(newRange);
  DW1000Ranging.attachNewDevice(newDevice);
  DW1000Ranging.attachInactiveDevice(inactiveDevice);
 
// start as tag, do not assign random short address
 
  DW1000Ranging.startAsTag(tag_addr, DW1000.MODE_LONGDATA_RANGE_LOWPOWER, false);
}
 
void loop()
{
  DW1000Ranging.loop();
}
 
void newRange()
{
    Serial.print(DW1000Ranging.getDistantDevice()->getShortAddress(), HEX);
    Serial.print(", ");
  
    #define NUMBER_OF_DISTANCES 1
    float dist = 0.0;
    for (int i = 0; i < NUMBER_OF_DISTANCES; i++) {
      dist += DW1000Ranging.getDistantDevice()->getRange();
    }
    dist = dist / NUMBER_OF_DISTANCES;
    Serial.println(dist);
  
}
 
void newDevice(DW1000Device *device)
{
  Serial.print("Device added: ");
  Serial.println(device->getShortAddress(), HEX);
}
 
void inactiveDevice(DW1000Device *device)
{
  Serial.print("delete inactive device: ");
  Serial.println(device->getShortAddress(), HEX);
}
