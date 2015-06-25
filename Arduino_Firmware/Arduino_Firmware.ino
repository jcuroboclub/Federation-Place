/*
SENSOR NODE SOFTWARE

This software is intended to run on a Arduino-compatible Sparkfun Pro Micro 3.3V.

The hardware connections are as follows:

Buttons: (all are active high)
 - Happy_button = pin 15
 - Indifferent_button= pin 14
 - Sad_button= pin 16

LEDs associated with the buttons:
 - Green_light = A0
 - Yellow_light = A1
 - Red_light = A2

The HTU2ID sensor:
 - SDA = pin 2
 - SCL = pin 3

Hardware Connections for RGB LED (common cathode)
 - redPWM = pin 5
 - greenPWM = pin 9
 - bluePWM = pin 6
*/

// In DEBUG mode, status information is printed over the serial port.
#define DEBUG 1

// SENSOR ID. Each sensor must have a unique ID, which is used to determine which reading comes from which part of the building.
#define SENSOR_ID 7

// Time delay between sensor readings (in seconds)
unsigned int sensor_period = 20;
bool have_upload_period = false; // has the hardcoded value been uploaded from the coordinator?

//DEFINE LIBRARIES
#include <SoftwareSerial.h>
#include <Wire.h> // The I2C library
#include "SparkFunHTU21D.h" // Sensor's library

//Global variables
HTU21D The_sensor;

//Pins
int ButtonPins[] = {15, 14, 16}; // Happy, Indifferent, Sad
int LEDpins[] = {A0, A1, A2}; // Green, Yellow, Red
int PWM[] = {5, 9, 6}; // Red, Green, Blue
SoftwareSerial XBee(8, 7); // RX, TX

// Keep track of the status of the system using this enumeration
enum NodeStatus {
  StartingUp, // before first contact
  NodeOK, // working normally
  LossOfRadioContact // Lost contact with the coordinator
} nodeStatus;

// Keep track of the button status using this state machine
enum ButtonStatus {
  // These numbers match up with the corresponding indices in LEDpins and ButtonPins
  HappyDown = 0,
  IndifferentDown = 1,
  SadDown = 2,
  NoButtons = 3
} buttonStatus;

// Time of last radio contact
unsigned long last_contact = 0; // time from millis() of last contact with the coordinator

void setup() {
  // General Setup
  nodeStatus = StartingUp;
  
  // Initialise the pins and turn on all the LEDs for testing
  for (int i = 0; i < 3; i++)
  {
    pinMode(LEDpins[i], OUTPUT);
    digitalWrite(LEDpins[i], 1);
    
    pinMode(PWM[i], OUTPUT);
    digitalWrite(PWM[i], 1);
  }  

  // Initialise the serial ports (for both Xbees and the USB serial)
  XBee.begin(9600); // Initialise the XBee SoftwareSerial
  Serial.begin(9600);
  
  // Wait a bit, and then turn off the LEDs
  delay(1000);
  ledRGB(0, 0, 0);
  digitalWrite(LEDpins[0], 0);
  digitalWrite(LEDpins[1], 0);
  digitalWrite(LEDpins[2], 0);
  
  // Just once, read the sensors on startup
  readSensors();
}

void loop() {
  // Is it time to obtain new sensor data?
  static unsigned long last_sensor_read = 0;
  unsigned long current_time = millis();
  if ((current_time - last_sensor_read)/1000 >= sensor_period) {
    // Unsigned arithmetic automatically accounts for clock rollover
    readSensors();
    last_sensor_read = current_time;
  }
  
  // Have we been told about the update period?
  if ((!have_upload_period) && (nodeStatus == NodeOK)) {
    static unsigned long last_request = 0;
    if ((current_time - last_request) >= 5000) {
      // SensorID,?
      XBee.print(SENSOR_ID);
      XBee.println(",?");
      last_request = millis();
    }
  }
  
  // Check that we're still in radio communication with the coordinator
  checkRadio();
  
  // Handle the buttons
  readButtons();
  
  // Update the LEDs
  updateStatusLED();
  updateButtonLEDs();
   
#if DEBUG
  static unsigned long last_print = 0;
  if ((millis() - last_print) > 1000) {
    last_print = millis();
    switch (nodeStatus) {
      case StartingUp:
        Serial.println("Status: Starting up");
        break;
      case NodeOK:
        //Serial.println("Status OK");
        break;
      case LossOfRadioContact:
        Serial.println("Loss of radio contact");
        break;
    }
  }  
#endif
    
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// SENSORS
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void readSensors() {
  // Read the temp and humidity from the sensors
  float humid = The_sensor.readHumidity();
  float temp = The_sensor.readTemperature();
  
  // Output in CSV format
  // SensorID,temp,humidity
  XBee.print(SENSOR_ID);
  XBee.print(",");
  XBee.print(temp);
  XBee.print(",");
  XBee.print(humid);
  XBee.println("");

#if DEBUG
  Serial.print("Sensor ");
  Serial.print(SENSOR_ID);
  Serial.print(" Temperature:");
  Serial.print(temp );
  Serial.print("C ");
  Serial.print(" Humidity:");
  Serial.print(humid );
  Serial.println("%");
#endif
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// BUTTONS
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void readButtons()
{
  static unsigned long last_change = 0;
  unsigned long current_time = millis();
  if ((current_time - last_change) < 1000) {
    // It has been too soon since the last change. Disallow this.
    return;
  }
    
  if (buttonStatus == NoButtons) {
    // Allowable transitions: to any button down.
    
    // Loop through all buttons:
    for (int i = 0; i < (int)NoButtons; i++) {
      // Read the button state
      if (digitalRead(ButtonPins[i])) {
        // A comfort button has been pressed.
        
        last_change = millis();
        buttonStatus = (ButtonStatus)i; // Update the state machine
        
        // Send this message over the radio in the format:
        //     SensorID,comfort_code
        // The comfort_code is:
        //      'A' = happy
        //      'B' = indifferent
        //      'C' = sad
        XBee.print(SENSOR_ID);
        XBee.print(",");
        XBee.println((char)(buttonStatus + 'A'));
        
#if DEBUG
        Serial.print("Sensor ");
        Serial.print(SENSOR_ID);
        Serial.print(" Comfort: ");
        Serial.println((char)(buttonStatus + 'A'));
#endif
        
        break; // Only allow one button to be pressed at once
      }
    }
  } else {
    // A button is currently pressed.
    
    // Allowable transitions: to button released.
    if (digitalRead(ButtonPins[buttonStatus]) == 0) {
      // The button has been released.
      buttonStatus = NoButtons;
      last_change = millis();
    }
  }
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// RADIO
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void checkRadio() 
{
  // The coordinator will send us periodic packets to indicate that we're still in radio contact.
  if (XBee.available()) {
    char msg = XBee.read();
    if (msg == 0x00) {
      Serial.println("Coordinator reports failure to upload.");
    } else if (msg == 0x01) {
      Serial.println("Coordinator reports success.");      
      // Byte 1 indicates an OK status from the coordinator.
      last_contact = millis();
      nodeStatus = NodeOK;
    } else {
      // Update how often we send messages
      sensor_period = (unsigned int)msg;
      Serial.print("New upload period ");
      Serial.print(sensor_period);
      Serial.println(" s");
      have_upload_period = true;
    }
  }

  // Check how long it has been since last radio contact
  unsigned long current_time = millis();
  if ((current_time - last_contact)/1000 > (sensor_period*2 + 2)) {
    // Unsigned arithmetic automatically accounts for clock rollover
    // More than n seconds have passed since last radio contact
    nodeStatus = LossOfRadioContact;
  }
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// LEDs
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

void updateStatusLED() 
{
  switch (nodeStatus) {
    case StartingUp:
      // Fast blinking green led
      if ((millis() / 100) % 2 == 0) {
        ledRGB(0, 128, 0);
      } else {
        ledRGB(0, 0, 0);
      }
      break;
    case NodeOK:
      // Solid green LED
      ledRGB(0, 40, 0);
      break;
    case LossOfRadioContact:
      // Blinking red LED
      if ((millis() / 200) % 2 == 0) {
        ledRGB(255, 0, 0);
      } else {
        ledRGB(0, 0, 0);
      } 
      break;
  }
}

void updateButtonLEDs() 
{
  for (int i = 0; i < NoButtons; i++) {
    digitalWrite(LEDpins[i], buttonStatus == i);
  }
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// RGB LED.
// Takes an input of the RGB PWM ratio (from 1-255)
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void ledRGB (int red, int green, int blue) {
  analogWrite(PWM[0], red);
  analogWrite(PWM[1], green);
  analogWrite(PWM[2], blue);
}


