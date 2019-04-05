#!/bin/bash

# Fix.
# https://github.com/1connect/nginx-config-formatter
~/.local/bin/nginxfmt.py ./content/nginx/*.conf ./content/nginx/app-layouts/*.conf ./content/nginx/conf.d/*.conf
