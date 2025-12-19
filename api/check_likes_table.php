<?php
require 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Checking app_likes table...\n";
    
    // Check if table exists
    $stmt = $conn->query("SHOW TABLES LIKE 'app_likes'");
    if ($stmt->rowCount() > 0) {
        echo "Table exists!\n";
        
        // Show sample data
        $stmt2 = $conn->query("SELECT * FROM app_likes LIMIT 5");
        $rows = $stmt2->fetchAll(PDO::FETCH_ASSOC);
        echo "Sample data:\n";
        print_r($rows);
    } else {
        echo "Table doesn't exist. Creating...\n";
        
        $conn->exec("
            CREATE TABLE app_likes (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_id VARCHAR(255) NOT NULL,
                photo_id VARCHAR(50) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE KEY unique_like (user_id, photo_id),
                INDEX idx_photo (photo_id),
                INDEX idx_user (user_id)
            )
        ");
        
        echo "Table created successfully!\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
