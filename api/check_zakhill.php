<?php
require 'config.php';
header('Content-Type: text/plain');

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    
    $email = 'zakhill1@gmail.com';
    
    echo "=== USER DATA FOR $email ===\n";
    $stmt = $conn->prepare("SELECT id, firebase_uid, email, balance FROM app_users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        print_r($user);
    } else {
        echo "NOT FOUND\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
