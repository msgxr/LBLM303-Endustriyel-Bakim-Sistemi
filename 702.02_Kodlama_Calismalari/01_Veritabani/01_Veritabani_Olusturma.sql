-- İlk kurulum: yalnız veritabanını oluşturur.
USE master;
GO

IF DB_ID(N'EndustriyelBakimDB') IS NULL
    CREATE DATABASE EndustriyelBakimDB;
GO

USE EndustriyelBakimDB;
GO
