<?php
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$stmt = $conn->query("SELECT DISTINCT status FROM app_photos");
$statuses = $stmt->fetchAll(PDO::FETCH_COLUMN);
echo "Statuses in DB: " . implode(", ", $statuses) . "\n";

} catch(PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
