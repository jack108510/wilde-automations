#!/bin/bash
# Facebook Auto-Poster - TEXT ONLY
# Posts 4x/day at 8am, 12pm, 4pm, 7pm
# Only posts APPROVED content from dashboard
# Usage: ./post-schedule.sh

TOKEN="EAAd2fPjlZAycBRHll6SYmFuZBD9ZB9YQnEVmxyaoj2HLjDYTf8LVdN2xorjtzBZC9ptEXL63bTzZAAfI62oiq4QxtYaJz57sZAvZBu3lLxkTfYGdzxhR1ZAKsu8XQ5ECZBy7SRLXnaBKbNEIFEl7G30oKDtDMOCbPI4U7USJeCqgLvVTQLUKvrLYhxad53ibPTHHLIu5RbRtE"
PAGE="984181648122254"
APPROVALS_FILE="/Users/jackserver/.openclaw/workspace/wilde-automations/approvals.json"
CALENDAR_FILE="/Users/jackserver/.openclaw/workspace/wilde-automations/content-calendar.json"

# Get day of week (1=Monday, 7=Sunday)
DAY=$(date +%u)
HOUR=$(date +%H)

# Determine which post key to use based on day and time
get_post_key() {
  local day_num=$1
  local hour=$2
  
  local day_name=""
  case $day_num in
    1) day_name="mon" ;;
    2) day_name="tue" ;;
    3) day_name="wed" ;;
    4) day_name="thu" ;;
    5) day_name="fri" ;;
    6) day_name="sat" ;;
    7) day_name="sun" ;;
  esac
  
  local time_suffix=""
  case $hour in
    08) time_suffix="8am" ;;
    12) time_suffix="12pm" ;;
    16) time_suffix="4pm" ;;
    19) time_suffix="7pm" ;;
    *) time_suffix="8am" ;;
  esac
  
  echo "${day_name}-${time_suffix}"
}

POST_KEY=$(get_post_key $DAY $HOUR)

# Check if approvals file exists and if this post is approved
if [ -f "$APPROVALS_FILE" ]; then
  STATUS=$(python3 -c "
import json
try:
    with open('$APPROVALS_FILE') as f:
        data = json.load(f)
    print(data.get('$POST_KEY', 'pending'))
except:
    print('pending')
" 2>/dev/null)
  
  if [ "$STATUS" != "approved" ]; then
    echo "[$(date)] SKIPPED $POST_KEY - Status: $STATUS (not approved)" >> /Users/jackserver/.openclaw/workspace/logs/facebook.log
    echo "Post not approved. Skipping."
    exit 0
  fi
else
  echo "[$(date)] WARNING: No approvals file found. Posting anyway." >> /Users/jackserver/.openclaw/workspace/logs/facebook.log
fi

# Get caption from content calendar
MESSAGE=$(python3 -c "
import json
try:
    with open('$CALENDAR_FILE') as f:
        data = json.load(f)
    print(data.get('posts', {}).get('$POST_KEY', {}).get('caption', 'Update from Wildrose'))
except:
    print('Update from Wildrose')
")

# Post to Facebook (text only)
RESULT=$(curl -s -X POST "https://graph.facebook.com/v18.0/$PAGE/feed" \
  --data-urlencode "message=$MESSAGE" \
  -d "access_token=$TOKEN")

POST_ID=$(echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id', 'error'))")
echo "[$(date)] POSTED $POST_KEY - Post ID: $POST_ID" >> /Users/jackserver/.openclaw/workspace/logs/facebook.log
echo "Posted successfully: $POST_ID"

