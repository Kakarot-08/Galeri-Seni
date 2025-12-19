<?php
require_once 'config.php';

echo "Testing logger...\n";
logDebug("TEST LOGGER ENTRY " . date('c'));
echo "Log called. Check debug.log.\n";
?>
