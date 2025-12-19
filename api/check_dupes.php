<?php
require 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    
    echo "=== USERS ===\n";
    $stmt = $conn->query("SELECT id, firebase_uid, email, balance FROM app_users");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo "ID: {$row['id']} | Email: {$row['email']} | UID: {$row['firebase_uid']} | Bal: {$row['balance']}\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
