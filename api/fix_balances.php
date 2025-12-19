<?php
require 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Recalculating balances...\n";

    // 1. Reset all balances to 0 (safety)
    $conn->exec("UPDATE app_users SET balance = 0");

    // 2. Sum all completed sales for each seller
    // Assuming 'sold' status in app_photos implies a completed transaction? 
    // Or better, use 'app_transactions' table if available.
    // Let's check app_transactions logic. 
    // trace_trans in transactions.php logs to app_transactions? No, app_transactions is a table.
    
    // In transactions.php:
    // INSERT INTO app_transactions (buyer_id, seller_id, photo_id, amount, ...)
    
    $stmt = $conn->query("
        SELECT seller_id, SUM(amount) as total_earnings
        FROM app_transactions
        WHERE status = 'completed'
        GROUP BY seller_id
    ");
    
    $updates = 0;
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $sellerId = $row['seller_id'];
        $total = $row['total_earnings'];
        
        $upd = $conn->prepare("UPDATE app_users SET balance = ? WHERE id = ?");
        $upd->execute([$total, $sellerId]);
        echo "User $sellerId: Balance set to $total\n";
        $updates++;
    }

    echo "Completed. Updated $updates users.\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
