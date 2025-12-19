<?php
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Fixing app_notifications schema...\n";

    try {
        $conn->exec("DROP TABLE app_notifications");
        echo "Dropped OLD table.\n";
    } catch (Exception $e) { echo "Table didn't exist.\n"; }

    $conn->exec("CREATE TABLE app_notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_uid VARCHAR(255) NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255),
        message TEXT,
        data TEXT,
        is_read TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    
    echo "Created NEW app_notifications table with user_uid column.\n";

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
