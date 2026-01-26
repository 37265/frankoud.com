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
$sql = 'SELECT id, first_name, last_name FROM Customer';

$stmt = $pdo->query($sql); 

echo sizeof($stmt->fetchAll(PDO::FETCH_ASSOC));
// echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));