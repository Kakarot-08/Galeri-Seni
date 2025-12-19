<?php
require_once 'config.php';
require_once 'firebase_auth.php';

header('Content-Type: application/json');
if (isset($_SERVER['HTTP_ORIGIN'])) {
     header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
     header('Access-Control-Allow-Credentials: true');
} else {
     header('Access-Control-Allow-Origin: *');
}
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit(0);

try {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    // Manual Decode to get Email (since verifyFirebaseToken only returns UID)
    if (empty($authHeader) || substr($authHeader, 0, 7) !== 'Bearer ') {
        throw new Exception("Missing Token");
    }
    $token = substr($authHeader, 7);
    $parts = explode('.', $token);
    if (count($parts) < 2) throw new Exception("Invalid Token Format");
    
    $payload = json_decode(base64_decode(str_replace('_', '/', str_replace('-', '+', $parts[1]))), true);
    
    $uid = $payload['user_id'] ?? $payload['sub'] ?? null;
    $email = $payload['email'] ?? null;
    
    if (!$uid || !$email) {
        throw new Exception("Token missing UID or Email");
    }

    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // STRATEGY: Look up by EMAIL first (most reliable), then sync the UID
    $stmt = $conn->prepare("SELECT id, firebase_uid, email, name, role, balance FROM app_users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        // User found by email! Update their firebase_uid if it's different
        if ($user['firebase_uid'] !== $uid) {
            $updateUid = $conn->prepare("UPDATE app_users SET firebase_uid = ? WHERE id = ?");
            $updateUid->execute([$uid, $user['id']]);
            $user['firebase_uid'] = $uid; // Update in-memory for response
        }
        
        // Return user data with balance
        echo json_encode($user);
    } else {
        // User doesn't exist - create new account
        $name = explode('@', $email)[0];
        $ins = $conn->prepare("INSERT INTO app_users (firebase_uid, email, name, role, balance) VALUES (?, ?, ?, 'admin', 0.00)");
        $ins->execute([$uid, $email, $name]);
        
        // Return newly created user
        echo json_encode([
            'id' => $conn->lastInsertId(),
            'firebase_uid' => $uid,
            'email' => $email,
            'name' => $name,
            'role' => 'admin',
            'balance' => '0.00'
        ]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
