<?php
file_put_contents(__DIR__ . '/trace_trans.log', date('[H:i:s] ') . "SIMPLE TEST HIT: " . $_SERVER['REQUEST_METHOD'] . "\n", FILE_APPEND);
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

echo json_encode(['status' => 'alive', 'message' => 'This is a test response']);
?>
