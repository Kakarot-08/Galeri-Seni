<?php
require 'config.php';
header('Content-Type: text/plain');

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    
    echo "=== TABLE STRUCTURE ===\n";
    $stmt = $conn->query("DESCRIBE app_users");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo $row['Field'] . " (" . $row['Type'] . ") Default: " . $row['Default'] . "\n";
    }
    
    echo "\n=== FIRST 5 USERS ===\n";
    $stmt2 = $conn->query("SELECT id, email, balance FROM app_users LIMIT 5");
    while ($u = $stmt2->fetch(PDO::FETCH_ASSOC)) {
        print_r($u);
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
