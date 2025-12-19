<?php
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "=== FIXING DATABASE ===\n";

    // 1. Fix app_bids
    // Drop it to ensure clean slate (since it had wrong columns)
    try {
        $conn->exec("DROP TABLE app_bids");
        echo "Dropped app_bids.\n";
    } catch (Exception $e) {
        echo "Could not drop app_bids (maybe didn't exist).\n";
    }

    $conn->exec("CREATE TABLE app_bids (
        id INT AUTO_INCREMENT PRIMARY KEY,
        photo_id INT NOT NULL,
        bidder_uid VARCHAR(255) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    echo "Created app_bids with bidder_uid.\n";

    // 2. Fix app_photos
    // Check if highest_bidder_uid exists
    try {
        $stmt = $conn->query("SHOW COLUMNS FROM app_photos LIKE 'highest_bidder_uid'");
        $col = $stmt->fetch();
        if (!$col) {
            echo "Column highest_bidder_uid MISSING in app_photos. Adding...\n";
            $conn->exec("ALTER TABLE app_photos ADD COLUMN highest_bidder_uid VARCHAR(255) DEFAULT NULL");
            echo "Added highest_bidder_uid.\n";
        } else {
            echo "Column highest_bidder_uid EXISTS in app_photos.\n";
        }
    } catch (Exception $e) {
        echo "Error checking app_photos: " . $e->getMessage() . "\n";
    }

    echo "=== VERIFICATION ===\n";
    
    echo "app_bids columns:\n";
    $stmt = $conn->query("DESCRIBE app_bids");
    print_r($stmt->fetchAll(PDO::FETCH_COLUMN));

    echo "app_photos columns:\n";
    $stmt = $conn->query("DESCRIBE app_photos");
    print_r($stmt->fetchAll(PDO::FETCH_COLUMN));

} catch (PDOException $e) {
    echo "FATAL: " . $e->getMessage() . "\n";
}
?>
