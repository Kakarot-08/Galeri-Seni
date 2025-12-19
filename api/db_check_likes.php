<?php
require 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== DB CHECK ===\n";
    
    // Check app_likes schema
    echo "Columns in app_likes:\n";
    $stmt = $conn->query("DESCRIBE app_likes");
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        print_r($row);
    }
    
    // Check sample data
    echo "\nSample rows in app_likes:\n";
    $stmt = $conn->query("SELECT * FROM app_likes LIMIT 5");
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        print_r($row);
    }
    
    // Check if current user has likes
    // Andy1's UID from earlier logs: VBRBmuvKyGh0HvxOwVt9WnSAQ893
    $uid = 'VBRBmuvKyGh0HvxOwVt9WnSAQ893';
    $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE user_id = ?");
    $stmt->execute([$uid]);
    echo "\nLikes for UID $uid: " . $stmt->fetchColumn() . "\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
