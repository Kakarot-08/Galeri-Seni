<?php
header('Content-Type: application/json');
require_once 'config.php';
require_once 'firebase_auth.php';

// CORS setup
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
} else {
    header('Access-Control-Allow-Origin: *');
}
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

function getBearerToken() {
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        if (preg_match('/Bearer\s(\S+)/', $headers['Authorization'], $matches)) {
            return $matches[1];
        }
    }
    return null;
}

try {
    $token = getBearerToken();
    $firebaseUid = verifyFirebaseToken($token);

    if (!$firebaseUid) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }

    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $action = $_GET['action'] ?? '';
    $photoId = $_GET['photo_id'] ?? '';

    // Action-based routing
    if ($action === 'list') {
        // Return list of photo IDs liked by the user
        $stmt = $conn->prepare("SELECT photo_id FROM app_likes WHERE user_id = ?");
        $stmt->execute([$firebaseUid]);
        $likes = $stmt->fetchAll(PDO::FETCH_COLUMN);
        echo json_encode(['liked_photos' => $likes]);
        exit;
    }

    if (empty($photoId)) {
        http_response_code(400);
        echo json_encode(['error' => 'Photo ID is required']);
        exit;
    }

    if ($action === 'status') {
        // Check if user liked the photo
        $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE user_id = ? AND photo_id = ?");
        $stmt->execute([$firebaseUid, $photoId]);
        $isLiked = $stmt->fetchColumn() > 0;

        // Get total likes count
        $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE photo_id = ?");
        $stmt->execute([$photoId]);
        $likeCount = $stmt->fetchColumn();

        echo json_encode([
            'is_liked' => $isLiked,
            'like_count' => (int)$likeCount
        ]);
    } 
    else if ($action === 'like') {
        // Use REPLACE to avoid duplicate key errors while ensuring it exists
        $stmt = $conn->prepare("INSERT IGNORE INTO app_likes (user_id, photo_id) VALUES (?, ?)");
        $stmt->execute([$firebaseUid, $photoId]);
        
        // Get updated count
        $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE photo_id = ?");
        $stmt->execute([$photoId]);
        $likeCount = $stmt->fetchColumn();

        echo json_encode([
            'message' => 'Liked successfully',
            'like_count' => (int)$likeCount
        ]);
    } 
    else if ($action === 'unlike') {
        $stmt = $conn->prepare("DELETE FROM app_likes WHERE user_id = ? AND photo_id = ?");
        $stmt->execute([$firebaseUid, $photoId]);
        
        // Get updated count
        $stmt = $conn->prepare("SELECT COUNT(*) FROM app_likes WHERE photo_id = ?");
        $stmt->execute([$photoId]);
        $likeCount = $stmt->fetchColumn();

        echo json_encode([
            'message' => 'Unliked successfully',
            'like_count' => (int)$likeCount
        ]);
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
