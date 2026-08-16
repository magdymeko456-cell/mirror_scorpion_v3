#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - WORKFLOW RUNS CLEANER
# ------------------------------------------------------------------------------
# الهدف: تنظيف وسجل محاولات البناء الفاشلة والملغاة من GitHub Actions
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# الألوان والسجلات
C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_YEL='\033[0;33m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[CLEANER]${C_END} $*"; }
ok()  { echo -e "${C_GREEN}  [✔] $*${C_END}"; }
warn(){ echo -e "${C_YEL}  [!] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"
cd "$WORKDIR" || exit 1

log "بدء الفحص عن محاولات البناء غير الناجحة..."

# جلب معرفات المحاولات الفاشلة والملغاة
FAILED_RUNS=$(gh run list --limit 1000 --json databaseId,conclusion --jq '.[] | select(.conclusion=="failure" or .conclusion=="startup_failure" or .conclusion=="cancelled") | .databaseId' 2>/dev/null || true)

if [ -z "$FAILED_RUNS" ]; then
    ok "المستودع نظيف تماماً! لا توجد محاولات فاشلة لحذفها يا تامر. 🦂"
    exit 0
fi

log "جاري حذف عمليات البناء الفاشلة تلقائياً..."

for RUN_ID in $FAILED_RUNS; do
    log "حذف المحاولة رقم: $RUN_ID ..."
    gh run delete "$RUN_ID" --confirm 2>/dev/null || true
done

ok "تم تنظيف المستودع بنجاح وتفريغ السجلات القديمة! 🦂🚀"
