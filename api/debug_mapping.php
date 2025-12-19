<?php
require 'config.php';
header('Content-Type: text/plain');

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    
    echo "=== TRANSACTION DETAILS ===\n";
    $stmt = $conn->query("SELECT id, seller_id, amount, status FROM app_transactions");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo "Tx {$row['id']} | Seller: {$row['seller_id']} | Amt: {$row['amount']} | St: {$row['status']}\n";
    }

    echo "\n=== USER IDS ===\n";
    $stmt2 = $conn->query("SELECT id, email FROM app_users");
    while ($row = $stmt2->fetch(PDO::FETCH_ASSOC)) {
        echo "User {$row['id']} = {$row['email']}\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
