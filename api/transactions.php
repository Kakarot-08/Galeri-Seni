<?php
ob_start();
header('Content-Type: application/json');

// Global Error Handler to prevent HTML output
function jsonErrorHandler($errno, $errstr, $errfile, $errline) {
    if (!(error_reporting() & $errno)) {
        return false;
    }
    ob_clean();
    echo json_encode([
        'error' => 'PHP Error',
        'message' => $errstr,
        'line' => $errline
    ]);
    exit;
}
set_error_handler("jsonErrorHandler");

if (!function_exists('getallheaders')) {
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

// CORS Headers
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
    exit(0);
}

require_once 'config.php';
require_once 'firebase_auth.php';

// Trace helper
function trace_trans($msg) {
    file_put_contents(__DIR__ . '/trace_trans.log', date('[H:i:s] ') . $msg . "\n", FILE_APPEND);
}

trace_trans("Request: " . $_SERVER['REQUEST_METHOD']);

try {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    // Auth Check
    $firebaseUid = null;
    try {
        $firebaseUid = verifyFirebaseToken($authHeader);
    } catch (Throwable $e) {
        trace_trans("Auth Crash: " . $e->getMessage());
    }

    if (!$firebaseUid) {
        trace_trans("Auth Failed. Header Len: " . strlen($authHeader));
        http_response_code(401);
        ob_clean();
        echo json_encode(['error' => 'Unauthorized - Invalid Token']);
        exit;
    }

    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Get current user ID
    $stmt = $conn->prepare("SELECT id, email FROM app_users WHERE firebase_uid = ?");
    $stmt->execute([$firebaseUid]);
    $currentUser = $stmt->fetch(PDO::FETCH_ASSOC);

    // Auto-register if missing (crucial for stability)
    if (!$currentUser) {
        trace_trans("User Not Found for UID: $firebaseUid. Attempting auto-register.");
        
        // If POST, we might have email in body
        $email = 'unknown@app.com';
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
             $rawData = file_get_contents('php://input');
             $input = json_decode($rawData, true);
             if (isset($input['buyer_email'])) {
                 $email = $input['buyer_email'];
             }
        }
        
        try {
            $ins = $conn->prepare("INSERT INTO app_users (firebase_uid, email, role, created_at) VALUES (?, ?, 'user', NOW())");
            $ins->execute([$firebaseUid, $email]);
            $userId = $conn->lastInsertId();
            trace_trans("Auto-registered User ID: $userId");
        } catch (Exception $e) {
            trace_trans("Auto-register failed: " . $e->getMessage());
            http_response_code(500);
            ob_clean();
            echo json_encode(['error' => 'User sync failed']);
            exit;
        }
    } else {
        $userId = $currentUser['id'];
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Decode input if not already done
        if (!isset($input)) {
             $input = json_decode(file_get_contents('php://input'), true);
        }
        $photoId = $input['photo_id'] ?? null;
        $amount = $input['amount'] ?? 0;
        $paymentMethod = $input['payment_method'] ?? 'unknown';

        trace_trans("Processing Payment: Photo $photoId");

        if (!$photoId) {
            http_response_code(400);
            ob_clean();
            echo json_encode(['error' => 'Photo ID is required']);
            exit;
        }

        // Get seller info
        $stmt = $conn->prepare("SELECT user_id FROM app_photos WHERE id = ?");
        $stmt->execute([$photoId]);
        $photo = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$photo) {
            http_response_code(400); // Changed from 404 to avoid confusion with File Not Found
            ob_clean();
            echo json_encode(['error' => 'Photo not found (ID: ' . $photoId . ')']);
            exit;
        }

        $sellerId = $photo['user_id'];
        
        // Find seller DB ID (Already have it!)
        // $stmt = $conn->prepare("SELECT id FROM app_users WHERE firebase_uid = ?");
        // $stmt->execute([$sellerUid]);
        // $seller = $stmt->fetch(PDO::FETCH_ASSOC);
        // $sellerId = $seller['id'] ?? 0;

        // Insert Transaction
        $trackingNumber = 'TRX-' . strtoupper(uniqid());
        
        $stmt = $conn->prepare("INSERT INTO app_transactions (buyer_id, seller_id, photo_id, amount, payment_method, status, tracking_number) VALUES (?, ?, ?, ?, ?, 'completed', ?)");
        $stmt->execute([$userId, $sellerId, $photoId, $amount, $paymentMethod, $trackingNumber]);
        $newId = $conn->lastInsertId();

        // Update photo status
        $upd = $conn->prepare("UPDATE app_photos SET status = 'sold' WHERE id = ?");
        $upd->execute([$photoId]);

        // Credit Seller Balance
        try {
             $bal = $conn->prepare("UPDATE app_users SET balance = balance + ? WHERE id = ?");
             $bal->execute([$amount, $sellerId]);
             trace_trans("Credited $amount to Seller $sellerId");
        } catch (Exception $e) {
             trace_trans("Failed to credit balance: " . $e->getMessage());
             // Don't fail the whole transaction, but log it critical
        }

        trace_trans("Success: Transaction $newId");

        ob_clean();
        echo json_encode(['message' => 'Payment successful', 'transaction_id' => $newId, 'tracking_number' => $trackingNumber]);
        exit;
    }

    // GET Logic
    $sql = "SELECT 
                t.*,
                b.email as buyer_email,
                s.email as seller_email,
                p.title as photo_title,
                p.image_data as photo_image
            FROM app_transactions t
            JOIN app_users b ON t.buyer_id = b.id
            JOIN app_users s ON t.seller_id = s.id
            JOIN app_photos p ON t.photo_id = p.id
            WHERE t.buyer_id = :uid OR t.seller_id = :uid
            ORDER BY t.created_at DESC";

    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':uid', $userId);
    $stmt->execute();
    $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Encode images
    foreach ($transactions as &$t) {
        if (!empty($t['photo_image'])) {
            $t['photo_image'] = base64_encode($t['photo_image']);
        }
    }

    ob_clean();
    echo json_encode($transactions);

} catch (Exception $e) {
    trace_trans("Exception: " . $e->getMessage());
    http_response_code(500);
    ob_clean();
    echo json_encode(['error' => 'Server Error: ' . $e->getMessage()]);
}
?>
