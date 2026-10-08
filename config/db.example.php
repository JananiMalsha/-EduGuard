<?php
// Copy this file to db.php and fill in your own local values.
// db.php is ignored by Git, so your password is never uploaded.

$DB_HOST = 'localhost';
$DB_NAME = 'eduguard';
$DB_USER = 'root';
$DB_PASS = '';   // XAMPP default is empty

try {
  $pdo = new PDO(
    "mysql:host=$DB_HOST;dbname=$DB_NAME;charset=utf8mb4",
    $DB_USER,
    $DB_PASS,
    [
      PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
      PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
      PDO::ATTR_EMULATE_PREPARES   => false,
    ]
  );
} catch (PDOException $e) {
  // Do not show internal details to users
  error_log($e->getMessage());
  die('Database connection failed.');
}
