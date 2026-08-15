#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - PROFESSIONAL WORKFLOW SCRIPT
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_YEL='\033[0;33m'; C_END='\033[0m'
WORKDIR="$HOME/mirror_scorpion_v3"

log() { echo -e "${C_CYN}[MS-WORKFLOW]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }

mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

case "${1:-help}" in
    sync)
        log "جاري جلب التعديلات من GitHub..."
        git pull origin main
        ok "تم تحديث المستودع بنجاح"
        ;;
    clean)
        log "جاري تنظيف الملفات المؤقتة للبناء..."
        rm -rf .dart_tool/ build/
        ok "تم التنظيف بنجاح"
        ;;
    check)
        log "حالة الملفات والمستودع الحالية:"
        git status -s
        ;;
    deploy)
        log "جاري تحضير التعديلات للنشر..."
        git add .
        echo -e "${C_YEL}أدخل رسالة الوصف (Commit Message):${C_END}"
        read -r msg
        git commit -m "${msg:-update scorpion}" || echo "لا يوجد تغييرات جديدة للرفع"
        git push origin main
        ok "تم الرفع بنجاح يا تامر! 🦂🚀"
        ;;
    *)
        echo -e "${C_YEL}الاستخدام:${C_END} ./ms_workflow_v3.sh [sync | clean | check | deploy]"
        echo " - sync   : جلب آخر التحديثات من GitHub"
        echo " - clean  : تنظيف كاش وبناء Dart/Flutter"
        echo " - check  : فحص التغييرات والملفات"
        echo " - deploy : رفع وتحديث المشروع فوراً"
        ;;
esac
