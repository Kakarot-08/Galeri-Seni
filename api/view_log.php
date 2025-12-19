<?php
header('Content-Type: text/plain');
$logFile = 'debug.log';

if (file_exists($logFile)) {
    echo "--- Debug Log Contents ---\n\n";
    echo file_get_contents($logFile);
} else {
    echo "Log file 'debug.log' is empty or does not exist yet.\n";
    echo "Try uploading a photo first to generate logs.";
}
?>
