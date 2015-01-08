/*
  # the sensor value description
  # 0  ~300     dry soil
  # 300~700     humid soil
  # 700~950     in water
*/

const int MOISTURE_TRESHOLD = 115; // the value after the LED goes ON
string BEACON_IDENTIFIER = "1337";

// the setup routine runs once when you press reset:
void setup() {
  Serial.begin(); 
  pinMode(1, OUTPUT); 
  Bean.setBeaconParameters(BEACON_IDENTIFIER,0x0000,0x0001);
  Bean.setBeaconEnable(false);
}

// the loop routine runs over and over again forever:
void loop() {

  if ( Serial.available() ) {
    Serial.write(BEACON_IDENTIFIER);
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


