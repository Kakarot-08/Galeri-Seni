<?php
header('Content-Type: text/plain');
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

try {
    echo "Attempting connection to $servername, DB: $dbname, User: $username...\n";
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "SUCCESS: Connected to database '$dbname'!";
} catch(PDOException $e) {
    echo "FAILURE: Connection failed: " . $e->getMessage();
}
?>
