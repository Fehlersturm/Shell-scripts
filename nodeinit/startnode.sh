#!/bin/bash
cd #/path/to/application/root
echo "$(date) Starting node listening on /tmp/node$1.sock" >> /var/log/node_console.log
NODE_ENV=production node app.js /tmp/node$1.sock >> /var/log/node_console.log

