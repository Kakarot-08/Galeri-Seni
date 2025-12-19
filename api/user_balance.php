<?php
require_once 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit(0);

try {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (empty($authHeader) || substr($authHeader, 0, 7) !== 'Bearer ') {
        throw new Exception("Missing Token");
    }
    
    $token = substr($authHeader, 7);
    $parts = explode('.', $token);
    $payload = json_decode(base64_decode(str_replace('_', '/', str_replace('-', '+', $parts[1]))), true);
    $email = $payload['email'] ?? null;
    
    if (!$email) throw new Exception("No email in token");

    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Look up by Email - SIMPLE AND DIRECT
    $stmt = $conn->prepare("SELECT balance FROM app_users WHERE email = ?");
    $stmt->execute([$email]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result) {
        echo json_encode(['balance' => $result['balance']]);
    } else {
        echo json_encode(['balance' => '0.00']);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage(), 'balance' => '0.00']);
}
?>
