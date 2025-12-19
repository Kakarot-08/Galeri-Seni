<?php
header('Content-Type: application/json');
header('X-API-Version: V100');
require_once 'config.php';
require_once 'firebase_auth.php';

if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
} else {
    header('Access-Control-Allow-Origin: *');
}
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit(0);

function getBearerToken() {
    $headers = array_change_key_case(getallheaders(), CASE_LOWER);
    if (isset($headers['authorization']) && preg_match('/Bearer\s(\S+)/', $headers['authorization'], $matches)) return $matches[1];
    if (isset($_SERVER['HTTP_AUTHORIZATION']) && preg_match('/Bearer\s(\S+)/', $_SERVER['HTTP_AUTHORIZATION'], $matches)) return $matches[1];
    return null;
}

try {
    $token = getBearerToken();
    if (!$token) { http_response_code(401); echo json_encode(['error' => 'No token provided']); exit; }
    
    $firebaseUid = verifyFirebaseToken("Bearer " . $token);
    if (!$firebaseUid) { http_response_code(401); echo json_encode(['error' => 'Unauthorized']); exit; }

    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);

    $action = isset($_REQUEST['action']) ? trim($_REQUEST['action']) : '';
    $photoId = $_REQUEST['photo_id'] ?? '';

    if ($action === 'list') {
        $stmt = $conn->prepare("SELECT photo_id FROM app_likes WHERE user_id = ?");
        $stmt->execute([$firebaseUid]);
        echo json_encode(['liked_photos' => $stmt->fetchAll(PDO::FETCH_COLUMN)]);
        exit;
    }

    if (empty($photoId)) { http_response_code(400); echo json_encode(['error' => 'Photo ID is required']); exit; }

    if ($action === 'status') {
        $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE user_id = ? AND photo_id = ?");
        $stmt->execute([$firebaseUid, $photoId]);
        $isLiked = $stmt->fetchColumn() > 0;
        
        $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE photo_id = ?");
        $stmt->execute([$photoId]);
        echo json_encode(['is_liked' => $isLiked, 'like_count' => (int)$stmt->fetchColumn()]);
    } 
    else if ($action === 'like') {
        $conn->prepare("INSERT IGNORE INTO app_likes (user_id, photo_id) VALUES (?, ?)")->execute([$firebaseUid, $photoId]);
        
        $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE photo_id = ?");
        $stmt->execute([$photoId]);
        echo json_encode(['message' => 'Liked successfully', 'like_count' => (int)$stmt->fetchColumn()]);
    } 
    else if ($action === 'unlike') {
        $conn->prepare("DELETE FROM app_likes WHERE user_id = ? AND photo_id = ?")->execute([$firebaseUid, $photoId]);
        
        $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE photo_id = ?");
        $stmt->execute([$photoId]);
        echo json_encode(['message' => 'Unliked successfully', 'like_count' => (int)$stmt->fetchColumn()]);
    } 
    else {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid action: ' . $action]);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
