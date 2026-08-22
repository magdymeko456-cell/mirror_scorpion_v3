#!/bin/bash
set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v3"

./sync_base.sh

cd "$WORKDIR"

echo "=== الرفع النهائي للمستودع الحالي ==="
git config http.postBuffer 524288000 2>/dev/null || true
git add -A
git commit -m "refactor: sync code and workflow base from successful build #49" || echo "لا يوجد تغييرات جديدة"
git push origin main --force

echo "🚀 تم جعل البناء الناجح هو الأساس للمستودع الحالي بنجاح! راقب الـ Actions الآن."
