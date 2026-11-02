<?php
// config/database.php — satu-satunya tempat koneksi database.

const DB_HOST = '127.0.0.1';
const DB_PORT = '3306';
const DB_NAME = 'db_pbd';
const DB_USER = 'root';
const DB_PASS = 'Aptasalim11';

function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';dbname=' . DB_NAME . ';charset=utf8mb4',
                DB_USER,
                DB_PASS,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                ]
            );
        } catch (PDOException $e) {
            error_log($e->getMessage());
            http_response_code(500);
            exit('Koneksi database gagal. Pastikan MySQL berjalan dan periksa config/database.php.');
        }
    }
    return $pdo;
}
