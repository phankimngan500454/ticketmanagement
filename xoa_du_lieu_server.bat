@echo off
set PGPASSWORD=Bvdkkh@123

echo Dang thu chay psql truc tiep...
psql -U postgres -d ticketmanagement -c "TRUNCATE TABLE tickets CASCADE;"
echo.

echo Dang thu duong dan 16...
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -d ticketmanagement -c "TRUNCATE TABLE tickets CASCADE;"
echo.

echo Dang thu duong dan 15...
"C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -d ticketmanagement -c "TRUNCATE TABLE tickets CASCADE;"
echo.

echo Dang thu duong dan 14...
"C:\Program Files\PostgreSQL\14\bin\psql.exe" -U postgres -d ticketmanagement -c "TRUNCATE TABLE tickets CASCADE;"
echo.

echo Dang thu voi ten database la ticketmanagement_server...
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -d ticketmanagement_server -c "TRUNCATE TABLE tickets CASCADE;"
"C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -d ticketmanagement_server -c "TRUNCATE TABLE tickets CASCADE;"
"C:\Program Files\PostgreSQL\14\bin\psql.exe" -U postgres -d ticketmanagement_server -c "TRUNCATE TABLE tickets CASCADE;"
echo.

echo ========================================================
echo DA CHAY XONG! BAN HAY NHIN XEM CO DONG CHU "TRUNCATE TABLE" CHUA?
echo ========================================================
pause
