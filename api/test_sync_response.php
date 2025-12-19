<?php
require 'config.php';
header('Content-Type: text/plain');

// Simulate what sync_profile does for zakhill1@gmail.com
$email = 'zakhill1@gmail.com';
$uid = 'TEST_UID_123';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    
    echo "=== TESTING SYNC_PROFILE LOGIC ===\n\n";
    
    // Same query as sync_profile.php
    $stmt = $conn->prepare("SELECT id, firebase_uid, email, name, role, balance FROM app_users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        echo "User found!\n";
        echo "JSON Response would be:\n";
        echo json_encode($user, JSON_PRETTY_PRINT);
        echo "\n\nBalance value: " . $user['balance'] . "\n";
        echo "Balance type: " . gettype($user['balance']) . "\n";
    } else {
        echo "User NOT found!\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
