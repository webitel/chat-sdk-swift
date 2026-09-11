#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift test --filter "uploadFile_success|uploadFile_cancel|downloadFile_success_afterUpload|downloadFile_cancel|sendMessage_withUploadedAttachment_success"
