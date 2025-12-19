<?php
// Simulate a request to likes.php action=list
$_SERVER['REQUEST_METHOD'] = 'GET';
$_GET['action'] = 'list';
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer test_token';

// Mock the verifyFirebaseToken function
function verifyFirebaseToken($token) {
    // Return a test UID
    return 'VBRBmuvKyGh0HvxOwVt9WnSAQ893';
}

// Include the likes.php file
include 'likes.php';
?>
