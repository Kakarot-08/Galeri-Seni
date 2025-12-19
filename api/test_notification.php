<?php
require_once 'config.php';
require_once 'firebase_auth.php';

echo "Testing notification logic...\n";

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // 1. Get a photo ID
    $stmt = $conn->query("SELECT id, user_id, title FROM app_photos LIMIT 1");
    $photo = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$photo) {
        die("No photos found to test with.\n");
    }

    echo "Found Photo ID: " . $photo['id'] . " (Owner ID: " . $photo['user_id'] . ")\n";

    // 2. Get Owner UID
    $stmt = $conn->prepare("SELECT firebase_uid, email FROM app_users WHERE id = ?");
    $stmt->execute([$photo['user_id']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        die("Owner user not found for ID " . $photo['user_id'] . "\n");
    }

    echo "Owner UID: " . $user['firebase_uid'] . " (" . $user['email'] . ")\n";

    // 3. Insert Notification
    echo "Inserting test notification...\n";
    $stmt = $conn->prepare("INSERT INTO app_notifications (user_uid, type, title, message, data) VALUES (?, 'bid_placed', 'TEST NOTIFICATION', 'This is a test.', '{}')");
    if ($stmt->execute([$user['firebase_uid']])) {
        echo "Notification inserted successfully for UID " . $user['firebase_uid'] . "\n";
    } else {
        echo "Insert Failed.\n";
    }

} catch (PDOException $e) {
    echo "DB Error: " . $e->getMessage() . "\n";
}
?>
