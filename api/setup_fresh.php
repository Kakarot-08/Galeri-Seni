<?php
header('Content-Type: text/plain');
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Creating new clean table 'app_users'...\n";
    $conn->exec("CREATE TABLE IF NOT EXISTS app_users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        firebase_uid VARCHAR(255) NOT NULL UNIQUE,
        email VARCHAR(255) NOT NULL,
        name VARCHAR(255),
        role VARCHAR(50) DEFAULT 'user',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    echo "SUCCESS: 'app_users' table created.\n";

    echo "Creating new clean table 'app_categories'...\n";
    $conn->exec("CREATE TABLE IF NOT EXISTS app_categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    // Insert defaults
    $conn->exec("INSERT IGNORE INTO app_categories (name) VALUES 
        ('Nature'), ('Portrait'), ('Architecture'), ('Street Photography'), 
        ('Wildlife'), ('Food'), ('Travel'), ('Abstract'), ('Fashion'), 
        ('Sports'), ('Black & White'), ('Macro')");
    echo "SUCCESS: 'app_categories' table created.\n";

    echo "Creating new clean table 'app_photos'...\n";
    $conn->exec("CREATE TABLE IF NOT EXISTS app_photos (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        image_data LONGBLOB,
        category VARCHAR(100) DEFAULT 'Uncategorized',
        user_id INT NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES app_users(id) ON DELETE CASCADE
    )");
    echo "SUCCESS: 'app_photos' table created.\n";

    echo "Creating new clean table 'app_likes'...\n";
    $conn->exec("CREATE TABLE IF NOT EXISTS app_likes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        photo_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY unique_user_photo (user_id, photo_id),
        FOREIGN KEY (photo_id) REFERENCES app_photos(id) ON DELETE CASCADE
    )");
    echo "SUCCESS: 'app_likes' table created.\n";

    echo "Creating new clean table 'app_transactions'...\n";
    $conn->exec("CREATE TABLE IF NOT EXISTS app_transactions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        buyer_id INT NOT NULL,
        seller_id INT NOT NULL,
        photo_id INT NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        status VARCHAR(50) DEFAULT 'completed',
        tracking_number VARCHAR(100),
        courier VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (buyer_id) REFERENCES app_users(id),
        FOREIGN KEY (seller_id) REFERENCES app_users(id),
        FOREIGN KEY (photo_id) REFERENCES app_photos(id)
    )");
    echo "SUCCESS: 'app_transactions' table created.\n";

    echo "Creating new clean table 'app_bids'...\n";
    $conn->exec("CREATE TABLE IF NOT EXISTS app_bids (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        photo_id INT NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES app_users(id),
        FOREIGN KEY (photo_id) REFERENCES app_photos(id)
    )");
    echo "SUCCESS: 'app_bids' table created.\n";

    echo "Creating new clean table 'app_notifications'...\n";
    $conn->exec("CREATE TABLE IF NOT EXISTS app_notifications (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        title VARCHAR(255),
        message TEXT,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES app_users(id)
    )");
    echo "SUCCESS: 'app_notifications' table created.\n";
    
    echo "\nGLOBAL FIX APPLIED: All tables migrated to 'app_*' prefix to bypass corruption.";

} catch(PDOException $e) {
    echo "FAILURE: " . $e->getMessage();
}
?>
