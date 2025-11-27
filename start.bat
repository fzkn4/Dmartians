@echo off
echo Starting Capstone Application with Docker...
echo.

echo Building and starting containers...
docker-compose up -d --build

echo.
echo Waiting for services to start...
timeout /t 10 /nobreak > nul

echo.
echo Application is starting up!
echo.
echo Access URLs:
echo - Main Website: http://localhost:8080
echo - Admin Panel: http://localhost:8080/admin_login.php
echo - phpMyAdmin: http://localhost:8081
echo.
echo Database Connection:
echo - Host: localhost
echo - Port: 3307
echo - Database: capstone_db
echo - Username: capstone_user
echo - Password: capstone_password
echo.
echo Default admin credentials:
echo - Username: admin
echo - Password: admin123
echo.
echo Press any key to stop the application...
pause > nul

echo Stopping application...
docker-compose down
echo Application stopped.
pause
