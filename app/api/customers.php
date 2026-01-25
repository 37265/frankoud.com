<?php
header('Content-Type: application/json');

$pdo = new PDO(
  'mysql:host=mariadb;port=3306;dbname=InAudible;charset=utf8mb4',
  'root',
  'greenbanana',
  [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
  ]
);

$stmt = $pdo->query('SELECT id, name FROM customer');
echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));