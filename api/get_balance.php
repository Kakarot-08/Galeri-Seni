<?php
require_once 'config.php';
require_once 'firebase_auth.php';

header('Content-Type: application/json');

// CORS Headers
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
} else {
    header('Access-Control-Allow-Origin: *');
}
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    if (empty($authHeader) || substr($authHeader, 0, 7) !== 'Bearer ') {
        throw new Exception("Missing Token");
    }
    $token = substr($authHeader, 7);
    
    // Decode token to get email directly
    $parts = explode('.', $token);
    $payload = json_decode(base64_decode(str_replace('_', '/', str_replace('-', '+', $parts[1]))), true);
    $email = $payload['email'] ?? null;
    
    if (!$email) throw new Exception("No email in token");

    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Look up by Email
    $stmt = $conn->prepare("SELECT id, email, balance, role FROM app_users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        echo json_encode([
            'found' => true,
            'email' => $user['email'],
            'balance' => $user['balance'],
            'id' => $user['id']
        ]);
    } else {
        echo json_encode(['found' => false, 'error' => 'User not found for email ' . $email]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
