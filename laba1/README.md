# Инструкция

1)скачать и распаковать

2)затем запустить cmd в той папке куда распаковали(например 
открыть через shift+пкм в проводнике powershell и прописать cmd)

3)прописать в cmd следующие команды:
- docker compose up --build

или
  
- docker build -t pogoda:latest .

- docker run -p 8080:8080 pogoda:latest


после чего перейти по ссылке 
http://localhost:8080/
