#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - GET REPO ACTIONS LINK (Clean Version)
# ==============================================================================

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "خطأ: أنت لست داخل مجلد مشروع git!"
    exit 1
fi

# جلب رابط المستودع وتنظيفه من التوكن (ghp_...)
REMOTE_URL=$(git remote get-url origin | sed -e 's/https:\/\/.*@/https:\/\//')

# تحويل الرابط إلى رابط المتصفح
ACTIONS_LINK=$(echo "$REMOTE_URL" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/\.git$//' -e 's/$/\/actions/')

echo "--------------------------------------------------"
echo "رابط الـ Actions الخاص بمشروعك هو:"
echo "$ACTIONS_LINK"
echo "--------------------------------------------------"
