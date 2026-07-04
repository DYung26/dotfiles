#!/usr/bin/env bash
cd /home/dyung/Projects/mcp-servers/src/filesystem-remote

exec env PORT=3333 \
    /home/dyung/.nvm/versions/node/v22.21.0/bin/node dist/index.js streamableHttp /home/dyung
