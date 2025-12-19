<?php
header('Content-Type: text/plain');
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // 1. Create users table
    $sql = "CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        firebase_uid VARCHAR(255) NOT NULL UNIQUE,
        email VARCHAR(255) NOT NULL,
        name VARCHAR(255),
        role VARCHAR(50) DEFAULT 'user',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    $conn->exec($sql);
    echo "SUCCESS: 'users' table created (or already exists).\n";

    // 2. Fix photos table schema if needed (ensure user_id is INT)
    // We won't alter it blindly, but we assume it exists from previous checks.

    // 3. Ensure a test user exists (Optional, but good for testing)
    // We can't easily insert a user without a valid firebase_uid from the app, so we skip this.

    echo "Database fix completed successfully.";

} catch(PDOException $e) {
    echo "FALURE: " . $e->getMessage();
}
?>
