<?php
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Connected. Checking schema...\n";

    // 1. Ensure app_bids exists
    $conn->exec("CREATE TABLE IF NOT EXISTS app_bids (
        id INT AUTO_INCREMENT PRIMARY KEY,
        photo_id INT NOT NULL,
        bidder_uid VARCHAR(255) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    echo "app_bids table OK.\n";

    // 2. Ensure app_notifications exists
    $conn->exec("CREATE TABLE IF NOT EXISTS app_notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_uid VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255),
        message TEXT,
        data TEXT,
        is_read TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    echo "app_notifications table OK.\n";

    // 3. Add columns to app_photos if missing
    $columns = [
        'highest_bid' => "DECIMAL(10,2) DEFAULT 0",
        'highest_bidder' => "VARCHAR(255) DEFAULT 'No one'",
        'highest_bidder_uid' => "VARCHAR(255) DEFAULT NULL"
    ];

    foreach ($columns as $col => $def) {
        try {
            // Try to select the column to see if it exists
            $conn->query("SELECT $col FROM app_photos LIMIT 1");
            echo "Column $col already exists.\n";
        } catch (Exception $e) {
            // If it fails, it likely doesn't exist, so add it
            echo "Adding column $col...\n";
            try {
                $conn->exec("ALTER TABLE app_photos ADD COLUMN $col $def");
                echo "Column $col added.\n";
            } catch (Exception $e2) {
                echo "Failed to add $col: " . $e2->getMessage() . "\n";
            }
        }
    }

    echo "Schema check complete.\n";

} catch (PDOException $e) {
    echo "DB Connection Failed: " . $e->getMessage() . "\n";
}
?>
