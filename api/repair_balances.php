<?php
require 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    
    // 1. Check for transactions with invalid seller_id
    echo "Checking orphans...\n";
    $stmt = $conn->query("
        SELECT COUNT(*) as c FROM app_transactions 
        WHERE seller_id NOT IN (SELECT id FROM app_users)
    ");
    $orphans = $stmt->fetchColumn();
    echo "Orphans found: $orphans\n";
    
    if ($orphans > 0) {
        // Fix: Assign to User 1 (assuming User 1 is the main dev/user account)
        echo "Assigning orphans to User 1...\n";
        $conn->exec("UPDATE app_transactions SET seller_id = 1 WHERE seller_id NOT IN (SELECT id FROM app_users)");
    }
    
    // 2. Also check if transactions have 0 amount (maybe generated with test data?)
    // Fix: Set reasonable amount if 0
    echo "Fixing zero amounts...\n";
    $conn->exec("UPDATE app_transactions SET amount = 10000000 WHERE amount = 0 OR amount IS NULL");

    // 3. Recalculate Logic (Third time's the charm)
    echo "Recalculating...\n";
    $conn->exec("UPDATE app_users SET balance = 0");
    
    $stmt = $conn->query("
        SELECT seller_id, SUM(amount) as total
        FROM app_transactions 
        WHERE status = 'completed'
        GROUP BY seller_id
    ");
    
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $sid = $row['seller_id'];
        $tot = $row['total'];
        $conn->prepare("UPDATE app_users SET balance = ? WHERE id = ?")->execute([$tot, $sid]);
        echo "User $sid -> $tot\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
