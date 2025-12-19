<?php
require 'config.php';
try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $stmt = $conn->query("DESCRIBE app_users");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $hasBalance = false;
    foreach ($columns as $col) {
        if ($col['Field'] === 'balance') $hasBalance = true;
    }
    
    if (!$hasBalance) {
        echo "Balance column missing. Adding it...\n";
        $conn->exec("ALTER TABLE app_users ADD COLUMN balance DECIMAL(10,2) DEFAULT 0.00");
        echo "Added balance column.\n";
    } else {
        echo "Balance column exists.\n";
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
