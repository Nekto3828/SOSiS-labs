// Переключаемся на базу данных testdb
db = db.getSiblingDB('testdb');

// Создаем тестовую коллекцию
db.testCollection.insertMany([
  { name: "item1", value: 100, timestamp: new Date() },
  { name: "item2", value: 200, timestamp: new Date() },
  { name: "item3", value: 300, timestamp: new Date() },
  { name: "item4", value: 400, timestamp: new Date() },
  { name: "item5", value: 500, timestamp: new Date() }
]);

// Создаем индексы
db.testCollection.createIndex({ name: 1 });
db.testCollection.createIndex({ timestamp: -1 });

print("Тестовые данные успешно добавлены!");