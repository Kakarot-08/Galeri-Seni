<?php
$logFile = __DIR__ . '/trace.log';
if (file_exists($logFile)) {
    echo nl2br(file_get_contents($logFile));
} else {
    echo "Log file not found.";
}
?>
