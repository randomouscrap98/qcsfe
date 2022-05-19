#!/bin/sh
# Use this to host the website locally, navigate to http://localhost:8080/
PORT=8080
echo "Hosting website at http://localhost:${PORT}"
busybox httpd -f -v -c hostlocal.conf -p ${PORT}
