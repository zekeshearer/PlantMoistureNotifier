/*
  # the sensor value description
  # 0  ~300     dry soil
  # 300~700     humid soil
  # 700~950     in water
*/
#include <EEPROM.h>

const int MOISTURE_TRESHOLD = 115; // the value after the LED goes ON
const int ID_EEPROM_START_ADDRESS = 0;
byte identifier[6];

// the setup routine runs once when you press reset:
void setup() {
  Serial.begin(); 
  pinMode(1, OUTPUT); 
  
  bool idHasBeenSet = false;
  for(int i=0; i<6; i++){
    byte value = EEPROM.read(ID_EEPROM_START_ADDRESS + i);
    identifier[i] = value;
    if(value != 255){
      idHasBeenSet = true;
    }
  }
  
  // If every byte in the identifier is 255, this means it's never been set
  if(idHasBeenSet == false){
    randomSeed(analogRead(0));
    for(int i=0; i<6; i++){
      identifier[i] = random(256);
      EEPROM.write(ID_EEPROM_START_ADDRESS + i, identifier[i]);
    }
  }
  
  uint16_t beaconIdentifier = identifier[0];
  beaconIdentifier = beaconIdentifier<<8 + identifier[1];
  uint16_t beaconMajor = identifier[2];
  beaconMajor = beaconMajor<<8 + identifier[3];
  uint16_t beaconMinor = identifier[4];
  beaconMinor = beaconMinor<<8 + identifier[5];
  
  Bean.setBeaconParameters(beaconIdentifier,beaconMajor,beaconMinor);
  Bean.setBeaconEnable(false);
}

// the loop routine runs over and over again forever:
void loop() {

  // Whenever serial data is sent to the Bean, reply with the unique identifier
  if ( Serial.available() ) {
    Serial.print("Unique ID: 0x");
    for(int i=0; i<6; i++){
      Serial.print(String(identifier[i], HEX));
    }
    Serial.print('\n');
    
    // Clear the incoming serial buffer
    while( Serial.available() ) {
      Serial.read();
    }
  }
  
  digitalWrite(1, HIGH); 
  delay(500);
  int moisture = analogRead(A0);
  digitalWrite(1, LOW); 
  
  
  if(moisture < MOISTURE_TRESHOLD) {
    Bean.setLed(255,0,0);  //red
    Bean.setBeaconEnable(true);
    Bean.sleep(10);
  }else{
    Bean.setLed(0,0,0);  //off
    Bean.setBeaconEnable(true);
    Bean.sleep(10);
  }
  
  Bean.setLed(0,0,0);  //off
  Bean.sleep(1000);
}


