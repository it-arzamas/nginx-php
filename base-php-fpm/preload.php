<?php

function _preload($preload, string $pattern = '/\.php$/', array $ignore = []): void
{
    if (is_array($preload)) {
        foreach ($preload as $path) {
            _preload($path, $pattern, $ignore);
        }
    } elseif (is_string($preload)) {
        $path = $preload;
        if (!in_array($path, $ignore, true)) {
            if (is_dir($path)) {
                if ($dh = opendir($path)) {
                    while (($file = readdir($dh)) !== false) {
                        if ($file !== '.' && $file !== '..') {
                            _preload($path . '/' . $file, $pattern, $ignore);
                        }
                    }
                    closedir($dh);
                }
            } elseif (is_file($path) && preg_match($pattern, $path) && !opcache_compile_file($path)) {
                trigger_error('Preloading Failed', E_USER_ERROR);
            }
        }
    }
}

$path = '/var/www/ZendFramework/library';
set_include_path(get_include_path() . PATH_SEPARATOR . realpath($path));
_preload([$path]);
