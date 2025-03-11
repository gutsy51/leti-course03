#include <LiquidCrystal.h>

// Объявление пинов для ультразвукового датчика
const int trigPin = 9;
const int echoPin = 8;

// Объявление пинов для дисплея
const int rs = 2, en = 3, d4 = 4, d5 = 5, d6 = 6, d7 = 7;
LiquidCrystal lcd(rs, en, d4, d5, d6, d7);

// Переменные для расчета уровня топлива
const float tankHeight = 40.0; // Высота бака в см (пример)
const float tankVolume = 50.0; // Объем бака в литрах (пример)
float distance = 0.0;
float fuelLevel = 0.0;

void setup() {
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  lcd.begin(16, 2);
  lcd.print("Fuel Level:");
  Serial.begin(9600);
}

void loop() {
  distance = measureDistance();
  fuelLevel = calculateFuelLevel(distance);

  lcd.setCursor(0, 1);
  lcd.print(fuelLevel);
  lcd.print(" L");

  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");
  Serial.print("Fuel Level: ");
  Serial.print(fuelLevel);
  Serial.println(" L");

  delay(1000); // Интервал обновления данных
}

float measureDistance() {
  // Посылаем ультразвуковой импульс
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  // Измеряем длительность сигнала
  long duration = pulseIn(echoPin, HIGH);

  // Преобразуем в расстояние (см)
  float distance = (duration * 0.034) / 2;
  return distance;
}

float calculateFuelLevel(float distance) {
  // Рассчитываем оставшийся объем топлива
  if (distance > tankHeight) {
    return 0.0; // Бак пуст
  } else if (distance < 0) {
    return tankVolume; // Бак полный
  } else {
    float fuelHeight = tankHeight - distance;
    return (fuelHeight / tankHeight) * tankVolume;
  }
}
