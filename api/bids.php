<?php
ob_start();
header('Content-Type: application/json');

if (!function_exists('getallheaders')) {
    ini_set('display_errors', 0);
    function getallheaders() {
        $headers = [];
        foreach ($_SERVER as $name => $value) {
            if (substr($name, 0, 5) == 'HTTP_') {
                $headers[str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($name, 5)))))] = $value;
            }
        }
        return $headers;
    }
}

// CORS Helper
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');
} else {
    header('Access-Control-Allow-Origin: *');
}
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    exit(0);
}

require_once 'config.php';
require_once 'firebase_auth.php';

// Trace helper
function trace($msg) {
    file_put_contents(__DIR__ . '/trace.log', date('[H:i:s] ') . $msg . "\n", FILE_APPEND);
}

try {
    trace("Request Started");
    
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    logDebug("Received request. Method: " . $_SERVER['REQUEST_METHOD']);

    $firebaseUid = verifyFirebaseToken($authHeader);

    if (!$firebaseUid) {
        logDebug("Auth failed");
        trace("Auth Failed");
        http_response_code(401);
        ob_clean();
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }
    
    trace("Auth OK. UID: $firebaseUid");
    
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // 1. Ensure tables exist
    $conn->exec("CREATE TABLE IF NOT EXISTS app_bids (
        id INT AUTO_INCREMENT PRIMARY KEY,
        photo_id INT NOT NULL,
        bidder_uid VARCHAR(255) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    
    // 2. Handle POST (Place Bid)
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = json_decode(file_get_contents('php://input'), true);
        $photoId = $input['photo_id'] ?? null;
        $amount = $input['amount'] ?? null;
        
        trace("POST received. Photo: $photoId");
        logDebug("POST Bid. Photo: $photoId, Amount: $amount, User: " . ($input['user_name'] ?? '?'));

        if (!$photoId || !$amount) {
            logDebug("Missing params");
            http_response_code(400);
            ob_clean();
            echo json_encode(['error' => 'Missing photo_id or amount']);
            exit;
        }

        $bidderNameInput = $input['user_name'] ?? 'App User';
        $bidderName = $bidderNameInput; 

        // Insert Bid
        trace("Inserting Bid...");
        $stmt = $conn->prepare("INSERT INTO app_bids (photo_id, bidder_uid, amount) VALUES (?, ?, ?)");
        if ($stmt->execute([$photoId, $firebaseUid, $amount])) {
             logDebug("Inserted into app_bids ID: " . $conn->lastInsertId());
             trace("Insert Bid OK");
        } else {
             logDebug("Failed to insert app_bids: " . implode(" ", $stmt->errorInfo()));
             trace("Insert Bid FAILED");
        }

        // Update Photo Highest Bid
        trace("Updating Photo Highest Bid...");
        $stmt = $conn->prepare("UPDATE app_photos SET highest_bid = ?, highest_bidder = ?, highest_bidder_uid = ? WHERE id = ?");
        if ($stmt->execute([$amount, $bidderName, $firebaseUid, $photoId])) {
            logDebug("Updated app_photos with Bid: $amount for ID: $photoId");
            trace("Update Photo OK");
        } else {
            logDebug("Failed update app_photos: " . implode(" ", $stmt->errorInfo()));
            trace("Update Photo FAILED: " . implode(" ", $stmt->errorInfo()));
        }

        // Notification Logic (Simplified for now)
         try {
            $conn->exec("CREATE TABLE IF NOT EXISTS app_notifications (
                id INT AUTO_INCREMENT PRIMARY KEY,
                user_uid VARCHAR(255) NOT NULL,
                type VARCHAR(50) NOT NULL,
                title VARCHAR(255),
                message TEXT,
                data TEXT,
                is_read TINYINT(1) DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )");

            // Get photo owner
            $stmt = $conn->prepare("SELECT user_id FROM app_photos WHERE id = ?");
            $stmt->execute([$photoId]);
            $ownerId = $stmt->fetchColumn();

            if ($ownerId) {
                // Get owner UID
                $stmt = $conn->prepare("SELECT firebase_uid FROM app_users WHERE id = ?");
                $stmt->execute([$ownerId]);
                $ownerUid = $stmt->fetchColumn();

                if ($ownerUid && $ownerUid !== $firebaseUid) {
                     $stmt = $conn->prepare("INSERT INTO app_notifications (user_uid, type, title, message, data) VALUES (?, 'bid_placed', 'New Bid!', ?, ?)");
                     $msg = "$bidderName placed a bid of $$amount on your photo.";
                     $data = json_encode(['photo_id' => $photoId, 'amount' => $amount, 'bidder_name' => $bidderName]);
                     $stmt->execute([$ownerUid, $msg, $data]);
                     trace("Notification Sent");
                }
            }
        } catch(Exception $ex) {
            trace("Notification Error: " . $ex->getMessage());
        }

        ob_clean();
        echo json_encode(['status' => 'success', 'message' => 'Bid placed']);
    } else {
        ob_clean();
        echo json_encode([]);
    }

} catch (Exception $e) {
    logDebug("Exception: " . $e->getMessage());
    trace("EXCEPTION: " . $e->getMessage());
    http_response_code(500);
    ob_clean();
    echo json_encode(['error' => 'Server Error: ' . $e->getMessage()]);
}
?>
