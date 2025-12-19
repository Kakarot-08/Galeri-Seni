<?php
// Database configuration
$servername = "localhost";
// IMPORTANT: Change this to match the name of your database in phpMyAdmin
$dbname = "artilier_db"; 
$username = "root"; 
$password = "";     

// Firebase configuration
$firebaseApiKey = "your_firebase_api_key";

// Global initialization
ini_set('display_errors', 0);
error_reporting(E_ALL);
date_default_timezone_set('UTC'); // Prevent timezone warnings

// Global Debug Helper checks if exists to avoid redeclaration if config included twice
if (!function_exists('logDebug')) {
    function logDebug($message) {
        $logFile = __DIR__ . '/debug.log';
        file_put_contents($logFile, date('[Y-m-d H:i:s] ') . $message . "\n", FILE_APPEND);
    }
}
