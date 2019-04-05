<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$handle = curl_init('https://api.github.com/user');
curl_setopt($handle, CURLOPT_RETURNTRANSFER, true);
$output = curl_exec($handle);
curl_close($handle);

echo $output;
die();
