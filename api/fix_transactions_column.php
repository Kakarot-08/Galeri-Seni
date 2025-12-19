<?php
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Fixing app_transactions table...\n";
    
    // Add payment_method column if not exists
    try {
        $conn->exec("ALTER TABLE app_transactions ADD COLUMN payment_method VARCHAR(50) DEFAULT 'unknown'");
        echo "Added column: payment_method\n";
    } catch (Exception $e) {
        echo "Column payment_method likely exists or error: " . $e->getMessage() . "\n";
    }

    // Verify columns
    $stmt = $conn->query("DESCRIBE app_transactions");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($columns as $col) {
        echo $col['Field'] . "\n";
    }

} catch(PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}
?>
