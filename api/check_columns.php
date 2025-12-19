<?php
require_once 'config.php';

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $conn->query("DESCRIBE app_bids");
    $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);

    echo "Columns in app_photos:\n";
    foreach ($columns as $col) {
        echo "- $col\n";
    }

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
