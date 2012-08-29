#!/bin/bash
perl -Mblib scripts/link-checker \
    --base='http://localhost/shlomif/homepage-local/' \
    --pre-skip '\.(?:js|txt)\z' \
    --before-insert-skip '/show\.cgi' \
    --before-insert-skip '/humour/fortunes/[^\.]+\z' \
    --before-insert-skip '/lecture/.*?\.tar\.gz+\z' \
    --before-insert-skip '/lm-solve/' \
    --before-insert-skip 'gringotts-shlomif.*?\.diff\z' \
    --before-insert-skip '/me/blogs/agg/'
