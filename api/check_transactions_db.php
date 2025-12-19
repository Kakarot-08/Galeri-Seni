<?php
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Checking app_transactions table...\n";
    
    // Check if table exists
    $stmt = $conn->query("SHOW TABLES LIKE 'app_transactions'");
    if ($stmt->rowCount() == 0) {
        echo "Table app_transactions DOES NOT EXIST. Creating...\n";
        $sql = "CREATE TABLE app_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            buyer_id INT NOT NULL,
            seller_id INT NOT NULL,
            photo_id INT NOT NULL,
            amount DECIMAL(10,2) NOT NULL,
            payment_method VARCHAR(50) DEFAULT 'unknown',
            status VARCHAR(50) DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )";
        $conn->exec($sql);
        echo "Table app_transactions created.\n";
    } else {
        echo "Table app_transactions exists.\n";
        $stmt = $conn->query("DESCRIBE app_transactions");
        $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
        echo "Columns: " . implode(", ", $columns) . "\n";
    }

} catch(PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}
?>
