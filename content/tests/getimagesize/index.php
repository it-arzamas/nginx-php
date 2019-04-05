<?php

ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

var_dump(getimagesize('http://localhost/tests/getimagesize/banana.png'));
die();
