#!/bin/bash

LOG_FILE="build_output.log"

flutter build apk --release --split-per-abi --verbose 2>&1 | tee "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ -f "$LOG_FILE" ] && [ -n "${STAGING_TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${STAGING_TELEGRAM_CHAT_ID:-}" ]; then
  curl -s -X POST "https://api.telegram.org/bot${STAGING_TELEGRAM_BOT_TOKEN}/sendDocument" \
    -F "chat_id=${STAGING_TELEGRAM_CHAT_ID}" \
    -F "document=@${LOG_FILE}" \
    -F caption="Build log: ${GITHUB_REPOSITORY} (${GITHUB_SHA})"
fi

exit $EXIT_CODE
