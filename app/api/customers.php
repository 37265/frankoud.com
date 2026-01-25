<?php
header('Content-Type: application/json');

$pdo = new PDO(
  'mysql:host=mariadb;dbname=InAudible;charset=utf8mb4',
  'root',
  'greenbanana',
  [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
  ]
);

$stmt = $pdo->query('SELECT id, name FROM Customer');
echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));