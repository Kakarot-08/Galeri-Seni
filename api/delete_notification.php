<?php
require_once 'config.php';
require_once 'firebase_auth.php';

try {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    $firebaseUid = verifyFirebaseToken($authHeader);

    if (!$firebaseUid) {
        http_response_code(401);
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
        $notifId = $_GET['id'] ?? null;
        if (!$notifId) {
            http_response_code(400);
            echo json_encode(['error' => 'Notification ID required']);
            exit;
        }

        $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // Verify ownership (optional but good)
        // For now just delete by ID
        $stmt = $conn->prepare("DELETE FROM app_notifications WHERE id = ?");
        $stmt->execute([$notifId]);

        echo json_encode(['message' => 'Notification deleted']);
    } else {
        http_response_code(405);
        echo json_encode(['error' => 'Method not allowed']);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
