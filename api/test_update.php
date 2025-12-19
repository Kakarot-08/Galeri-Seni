<?php
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Attempting update...\n";
    // Try to update a non-existent ID just to check query validity (columns)
    $stmt = $conn->prepare("UPDATE app_photos SET highest_bid = 100, highest_bidder = 'Test', highest_bidder_uid = '123' WHERE id = 1");
    if ($stmt->execute()) {
        echo "Update Query Success!\n";
    } else {
        echo "Update Failed (Logic)\n";
    }

} catch (PDOException $e) {
    echo "SQL Error: " . $e->getMessage() . "\n";
}
?>
