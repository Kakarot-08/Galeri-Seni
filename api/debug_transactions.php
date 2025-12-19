<?php
require 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    
    echo "=== TRANSACTIONS ===\n";
    $stmt = $conn->query("SELECT * FROM app_transactions LIMIT 20");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    print_r($rows);
    
    echo "\n=== STATUSES ===\n";
    $stmt2 = $conn->query("SELECT status, COUNT(*) as c FROM app_transactions GROUP BY status");
    print_r($stmt2->fetchAll(PDO::FETCH_ASSOC));

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
