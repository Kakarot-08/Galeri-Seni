<?php
require 'config.php';
try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $stmt = $conn->query("DESCRIBE app_transactions");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if ($row['Field'] == 'amount') echo "Amount Type: " . $row['Type'] . "\n";
    }
} catch (Exception $e) {}
?>
