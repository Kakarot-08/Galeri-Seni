<?php
require 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "Fixing NULL balances...\n";
    $conn->exec("UPDATE app_users SET balance = 0 WHERE balance IS NULL");
    
    echo "Recalculating balances (v2)...\n";
    // Get all transactions
    $stmt = $conn->query("
        SELECT seller_id, SUM(amount) as total
        FROM app_transactions 
        WHERE status = 'completed'
        GROUP BY seller_id
    ");
    
    $updates = 0;
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $sid = $row['seller_id'];
        $tot = (float)$row['total'];
        
        $upd = $conn->prepare("UPDATE app_users SET balance = ? WHERE id = ?");
        $upd->execute([$tot, $sid]);
        echo "Seller $sid -> $tot\n";
        $updates++;
    }
    
    echo "Done. Updated $updates sellers.\n";
    
    // Check for our user
    // We don't know who they are, dump all non-zero balances
    echo "\n=== Users with Balance ===\n";
    $chk = $conn->query("SELECT id, email, balance FROM app_users WHERE balance > 0");
    while ($u = $chk->fetch(PDO::FETCH_ASSOC)) {
        echo "User {$u['id']} ({$u['email']}): {$u['balance']}\n";
    }

} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
