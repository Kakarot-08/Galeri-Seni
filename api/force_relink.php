<?php
require 'config.php';

// This script forces the zakhill1@gmail.com account to link to ANY Firebase UID
// Run this, then restart the app

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    
    // Clear firebase_uid for zakhill1 so sync_profile can re-link it
    $stmt = $conn->prepare("UPDATE app_users SET firebase_uid = NULL WHERE email = 'zakhill1@gmail.com'");
    $stmt->execute();
    
    echo "Cleared Firebase UID for zakhill1@gmail.com\n";
    echo "Now restart the app and it will auto-link on next login.\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
