<?php
ob_start();
header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 0); // Disable output errors to keep JSON pure
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Max-Age: 86400');
} else {
    header('Access-Control-Allow-Origin: *');
}

header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_METHOD']))
        header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
    if (isset($_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']))
        header("Access-Control-Allow-Headers: {$_SERVER['HTTP_ACCESS_CONTROL_REQUEST_HEADERS']}");
    exit(0);
}

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

require_once 'config.php';
require_once 'firebase_auth.php';

// Trace helper
function trace($msg) {
    file_put_contents(__DIR__ . '/trace.log', date('[H:i:s] PH: ') . $msg . "\n", FILE_APPEND);
    file_put_contents(__DIR__ . '/path_discovery.txt', "FILE: " . __FILE__ . "\nCWD: " . getcwd() . "\n", FILE_APPEND);
}

try {
    // Get Firebase UID from Authorization header
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    // Debug log
    if (isset($headers['Authorization'])) {
        // Redact token for security logging
        // logDebug("Auth Header present (len: " . strlen($headers['Authorization']) . ")"); 
    } else {
        // logDebug("Auth Header MISSING");
    }

    $firebaseUid = verifyFirebaseToken($authHeader);

    if (!$firebaseUid) {
        http_response_code(401);
        ob_clean();
        echo json_encode(['error' => 'Unauthorized']);
        exit;
    }
} catch (Exception $e) {
    http_response_code(500);
    ob_clean();
    echo json_encode(['error' => 'Auth Error: ' . $e->getMessage()]);
    exit;
}

try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $method = $_SERVER['REQUEST_METHOD'];

    switch ($method) {
        case 'GET':
            handleGet($conn, $firebaseUid);
            break;
        case 'POST':
            handlePost($conn, $firebaseUid);
            break;
        case 'PUT':
            handlePut($conn, $firebaseUid);
            break;
        case 'DELETE':
            handleDelete($conn, $firebaseUid);
            break;
        default:
            http_response_code(405);
            ob_clean();
            echo json_encode(['error' => 'Method not allowed']);
    }
} catch(PDOException $e) {
    http_response_code(500);
    ob_clean();
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
}

function handleDelete($conn, $firebaseUid) {
    trace("handleDelete Started for UID: $firebaseUid");
    $photoId = $_GET['id'] ?? null;
    
    if (!$photoId) {
        // Try fallback to body if not in query
        $data = json_decode(file_get_contents('php://input'), true);
        $photoId = $data['photo_id'] ?? null;
    }

    if (!$photoId) {
        http_response_code(400);
        ob_clean();
        echo json_encode(['error' => 'Photo ID is required']);
        return;
    }

    try {
        // 1. Get current user ID and Role
        $stmt = $conn->prepare("SELECT id, role FROM app_users WHERE firebase_uid = ?");
        $stmt->execute([$firebaseUid]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user) {
            http_response_code(401);
            ob_clean(); 
            echo json_encode(['error' => 'User not found']); 
            return;
        }

        $userId = $user['id'];
        $userRole = $user['role'] ?? 'user';

        // 2. Get photo owner
        $stmt = $conn->prepare("SELECT user_id FROM app_photos WHERE id = ?");
        $stmt->execute([$photoId]);
        $photo = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$photo) {
            http_response_code(404);
            ob_clean();
            echo json_encode(['error' => 'Photo not found']);
            return;
        }

        // 3. Check permissions (Owner OR Admin)
        if ($photo['user_id'] != $userId && $userRole !== 'admin') {
            http_response_code(403);
            ob_clean();
            echo json_encode(['error' => 'Unauthorized to delete this photo']);
            return;
        }

        // 4. Delete related records
        // Delete Likes
        $conn->prepare("DELETE FROM app_likes WHERE photo_id = ?")->execute([$photoId]);
        
        // Delete Bids (Crucial for Foreign Key constraints if any, or just cleanup)
        // Check if table exists first to avoid error? No, just try delete.
        try {
            $conn->prepare("DELETE FROM app_bids WHERE photo_id = ?")->execute([$photoId]);
        } catch (Exception $ignore) {}

        // Delete Transactions (if any exist linked to this photo)
        try {
            $conn->prepare("DELETE FROM app_transactions WHERE photo_id = ?")->execute([$photoId]);
        } catch (Exception $ignore) {}

        // 5. Delete Photo
        $del = $conn->prepare("DELETE FROM app_photos WHERE id = ?");
        if ($del->execute([$photoId])) {
            trace("Photo $photoId deleted by user $userId");
            ob_clean();
            echo json_encode(['message' => 'Photo deleted successfully']);
        } else {
            // Should verify if rowCount > 0?
            if ($del->rowCount() == 0) {
                 // Maybe it was already deleted?
                 trace("Photo delete executed but 0 rows affected.");
                 // Still success from client perspective
                 ob_clean();
                 echo json_encode(['message' => 'Photo was already deleted or not found']);
            } else {
                throw new Exception("Delete failed (unknown reason)");
            }
        }

    } catch (Exception $e) {
        trace("Delete Error: " . $e->getMessage());
        http_response_code(500);
        ob_clean();
        echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
    }
}

function handlePut($conn, $firebaseUid) {
    trace("handlePut Started for UID: $firebaseUid");
    $data = json_decode(file_get_contents('php://input'), true);
    $photoId = $data['photo_id'] ?? null;
    $status = $data['status'] ?? 'approved'; 

    if (!$photoId) {
        trace("Missing PhotoID");
        http_response_code(400);
        ob_clean();
        echo json_encode(['error' => 'Photo ID is required']);
        return;
    }

    trace("Updating status to: $status for Photo: $photoId");
    $stmt = $conn->prepare("UPDATE app_photos SET status = :status WHERE id = :id");
    $stmt->bindParam(':status', $status);
    $stmt->bindParam(':id', $photoId);

    if ($stmt->execute()) {
        trace("Update Success");
        // Notification Logic for Accepting Offer
        if ($status === 'sold') {
            trace("Processing Sold Status...");
            try {
                $stmt = $conn->prepare("SELECT title, highest_bidder_uid, highest_bid FROM app_photos WHERE id = ?");
                $stmt->execute([$photoId]);
                $photo = $stmt->fetch(PDO::FETCH_ASSOC);
                
                trace("Photo fetched. Bidder: " . ($photo['highest_bidder_uid'] ?? 'NULL'));

                if ($photo && !empty($photo['highest_bidder_uid'])) {
                    $bidderUid = $photo['highest_bidder_uid'];
                    $amount = $photo['highest_bid'];
                    $title = $photo['title'];

                    $notifType = 'payment_required';
                    $notifTitle = 'Offer Accepted!';
                    $notifMsg = "Your offer of $$amount for '$title' was accepted. Please pay now.";
                    $notifData = json_encode([
                        'photo_id' => $photoId,
                        'photo_title' => $title,
                        'amount' => $amount
                    ]);

                    $ins = $conn->prepare("INSERT INTO app_notifications (user_uid, type, title, message, data) VALUES (?, ?, ?, ?, ?)");
                    if ($ins->execute([$bidderUid, $notifType, $notifTitle, $notifMsg, $notifData])) {
                        trace("Notification inserted for $bidderUid");
                    } else {
                        trace("Notification insert FAILED");
                    }
                } else {
                    trace("No highest bidder found to notify.");
                }
            } catch (Exception $e) {
                trace("Notification EXC: " . $e->getMessage());
            }
        }

        ob_clean();
        echo json_encode(['message' => "Photo status updated to $status"]);
    } else {
        trace("Update Failed: " . implode(" ", $stmt->errorInfo()));
        http_response_code(500);
        ob_clean();
        echo json_encode(['error' => 'Failed to update status']);
    }
}

function handleGet($conn, $firebaseUid) {
    $id = $_GET['id'] ?? null;
    $category = $_GET['category'] ?? null;
    $status = $_GET['status'] ?? 'approved';
    $sort = $_GET['sort'] ?? 'newest';
    $mode = $_GET['mode'] ?? '';

    $sql = "SELECT p.*, u.email as uploader_email, u.name as uploader_name, u.firebase_uid as uploader_uid,
            (SELECT COUNT(*) FROM app_likes WHERE photo_id = p.id) as like_count
            FROM app_photos p 
            JOIN app_users u ON p.user_id = u.id";
            
    $params = [];

    if ($id) {
        $sql .= " WHERE p.id = :id";
        $params[':id'] = $id;
    } elseif ($mode === 'mine') {
        $sql .= " WHERE p.user_id = :user_id";
        
        $userStmt = $conn->prepare("SELECT id FROM app_users WHERE firebase_uid = :fuid");
        $userStmt->execute([':fuid' => $firebaseUid]);
        $myUserId = $userStmt->fetchColumn();
        
        if (!$myUserId) {
            ob_clean(); echo json_encode([]); return;
        }
        $params[':user_id'] = $myUserId;
    } elseif ($mode === 'history') {
        // Admin History: Approved, Rejected, Sold
        $sql .= " WHERE p.status IN ('approved', 'rejected', 'sold')";
    } else {
        // Status handling
        if (strpos($status, ',') !== false) {
            $statuses = explode(',', $status);
            $statusPlaceholders = [];
            foreach ($statuses as $i => $s) {
                $key = ":status$i";
                $statusPlaceholders[] = $key;
                $params[$key] = trim($s);
            }
            $sql .= " WHERE p.status IN (" . implode(',', $statusPlaceholders) . ")";
        } else {
            $sql .= " WHERE p.status = :status";
            $params[':status'] = $status;
        }

        if ($category && $category !== 'All') {
            $sql .= " AND p.category = :category";
            $params[':category'] = $category;
        }
    }
    
    if ($sort === 'popular') {
        $sql .= " ORDER BY like_count DESC, p.created_at DESC";
    } else {
        $sql .= " ORDER BY p.created_at DESC";
    }
    
    $stmt = $conn->prepare($sql);
    foreach ($params as $key => $val) {
        $stmt->bindValue($key, $val);
    }
    
    trace("SQL: $sql");
    trace("Params: " . json_encode($params));

    $stmt->execute();
    $photos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    trace("Found " . count($photos) . " photos.");

    // Convert image data to base64 if needed
    foreach ($photos as &$photo) {
        if (isset($photo['image_data'])) {
            $photo['image_data'] = base64_encode($photo['image_data']);
        }
    }
    
    ob_clean();
    echo json_encode($photos);
}

// logDebug handled by config.php

function handlePost($conn, $firebaseUid) {
    logDebug("Starting handlePost for UID: $firebaseUid");
    $data = json_decode(file_get_contents('php://input'), true);
    
    $title = $data['title'] ?? '';
    $description = $data['description'] ?? '';
    $imageData = $data['image'] ?? '';
    $category = $data['category'] ?? 'Uncategorized';
    $userName = $data['user_name'] ?? 'App User'; // New field
    
    logDebug("Data received. Title: $title, Category: $category, Image length: " . strlen($imageData));

    if (empty($title) || empty($imageData)) {
        logDebug("Error: Missing title or image");
        http_response_code(400);
        ob_clean();
        echo json_encode(['error' => 'Title and image are required']);
        return;
    }
    
    try {
        // 1. Ensure 'app_users' table exists 
        $conn->exec("CREATE TABLE IF NOT EXISTS app_users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            firebase_uid VARCHAR(255) NOT NULL UNIQUE,
            email VARCHAR(255) NOT NULL,
            name VARCHAR(255),
            role VARCHAR(50) DEFAULT 'user',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");
        
        // 2. Get user ID or Register/Update
        $userStmt = $conn->prepare("SELECT id, name FROM app_users WHERE firebase_uid = :firebase_uid");
        $userStmt->bindParam(':firebase_uid', $firebaseUid);
        $userStmt->execute();
        $user = $userStmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user) {
            logDebug("User not found in DB. Auto-registering with name: $userName");
            $email = 'user_' . substr($firebaseUid, 0, 8) . '@artilier.com'; // Fallback if email not synced
            // If client sends email, use it (TODO: pass email from client if needed, but token has it usually but verified in PHP only gives UID usually unless using Admin SDK or passed claims)
            // For now, let's just stick with dummy email or if we can decode it (we can't easily without lib). 
            // Better: Client should pass email too if possible, but let's stick to name fix first.
            
            $insertSql = "INSERT IGNORE INTO app_users (firebase_uid, email, name, role) VALUES (:uid, :email, :name, 'user')";
            $insertStmt = $conn->prepare($insertSql);
            $insertStmt->bindParam(':uid', $firebaseUid);
            $insertStmt->bindParam(':email', $email);
            $insertStmt->bindParam(':name', $userName);
            
            if ($insertStmt->execute()) {
                $userId = $conn->lastInsertId();
                 // If ID is 0 (duplicate), fetch it again
                if ($userId == 0) {
                     $stmt = $conn->prepare("SELECT id FROM app_users WHERE firebase_uid = ?");
                     $stmt->execute([$firebaseUid]);
                     $userId = $stmt->fetchColumn();
                }
                logDebug("User auto-registered with ID: $userId");
            } else {
                 throw new Exception("Failed to auto-register user");
            }
        } else {
            $userId = $user['id'];
            // Update name if it was generic
            if ($user['name'] == 'App User' && $userName != 'App User') {
                 $upd = $conn->prepare("UPDATE app_users SET name = ? WHERE id = ?");
                 $upd->execute([$userName, $userId]);
            }
            logDebug("User found with ID: $userId");
        }
        
        // 3. Insert Photo
        $imageBinary = base64_decode($imageData);
        if ($imageBinary === false) {
             logDebug("Base64 decode failed");
             throw new Exception("Invalid image data");
        }
        
        $sql = "INSERT INTO app_photos (title, description, image_data, category, user_id, status) 
                VALUES (:title, :description, :image_data, :category, :user_id, 'pending')";
        
        $stmt = $conn->prepare($sql);
        $stmt->bindParam(':title', $title);
        $stmt->bindParam(':description', $description);
        $stmt->bindParam(':image_data', $imageBinary, PDO::PARAM_LOB);
        $stmt->bindParam(':category', $category);
        $stmt->bindParam(':user_id', $userId);
        
        if ($stmt->execute()) {
            $newId = $conn->lastInsertId();
            logDebug("Photo inserted successfully. ID: $newId");
            ob_clean();
            echo json_encode(['message' => 'Photo uploaded successfully', 'id' => $newId]);
        } else {
            logDebug("Photo insert failed: " . implode(" ", $stmt->errorInfo()));
            http_response_code(500);
            ob_clean();
            echo json_encode(['error' => 'Failed to upload photo']);
        }

    } catch (Exception $e) {
        logDebug("Exception in handlePost: " . $e->getMessage());
        http_response_code(500);
        ob_clean();
        echo json_encode(['error' => 'Server error: ' . $e->getMessage()]);
    }
}
