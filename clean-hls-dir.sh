#!/bin/sh

# I experienced an error where .ts and .m3u8 files were being deleted prematurely.
# Resulting in a playback error.
# Fix:
#   set hls_cleanup to off in nginx.conf
# To keep the directory clean use this script which will be called every 2 minutes
# and delete every content of hls directory.
echo "cleaning hls directory..!"
rm -r  $HLS_DIR/*