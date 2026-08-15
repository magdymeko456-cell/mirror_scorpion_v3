#!/bin/bash
# fix_stage1_const.sh — إصلاح خطأ const في document_screen.dart + رفع
set -euo pipefail

REPO="magdymeko456-cell/mirror_scorpion-mirror_scorpion_v2"
BRANCH="main"

cd "$HOME/mirror_scorpion_translate_version_2" || { echo "✗ المجلد غير موجود"; exit 1; }
echo "✓ نعمل داخل: $(pwd)"

TOKEN="$(tr -d '\r\n' < "$HOME/.ms_gh_token" 2>/dev/null || true)"
if [[ -z "$TOKEN" || "$TOKEN" == *"XXXXXXXX"* ]]; then
  echo "✗ التوكن غير صالح في ~/.ms_gh_token"; exit 1
fi
HTTP="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 -H "Authorization: Bearer ${TOKEN}" https://api.github.com/user)"
[[ "$HTTP" != "200" ]] && { echo "✗ التوكن مرفوض (HTTP $HTTP)"; exit 1; }
echo "✓ التوكن سليم"

git fetch origin "$BRANCH" 2>/dev/null || git fetch origin
git reset --hard "origin/$BRANCH"
git clean -fdq -e clean_failed_runs.sh -e git_sync.sh -e cleanup_builds.sh \
  -e translation_voice_tool.py -e step2_stories.sh -e .core_completion_status \
  -e .safe_build_android || true
echo "✓ HEAD: $(git rev-parse --short HEAD)"

# ── إصلاح سطر const المكسور ──
python3 - <<'PY'
p = 'lib/features/card1_translation/document_screen.dart'
s = open(p, encoding='utf-8').read()
# استبدال السطر المكسور: استيفاء خريطة داخل const غير مسموح في Dart
bad = "const Text('الترجمة (${'$_langs'[0]}):', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),"
good = "const Text('الترجمة:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),"
if bad in s:
    s = s.replace(bad, good)
    print('  ✓ أُصلح سطر const المكسور')
else:
    print('  ⚠ السطر المكسور غير موجود — ربما أُصلح مسبقاً أو اختلف النص')
open(p, 'w', encoding='utf-8').write(s)
PY

# ── إزالة الحقل غير المستخدم (تحذير فقط لكن نظافة) ──
sed -i '/bool _showTranslatedDoc = false;/d' lib/features/card1_translation/document_screen.dart 2>/dev/null || true
sed -i "s/_showTranslatedDoc = false;//g" lib/features/card1_translation/document_screen.dart 2>/dev/null || true

# ── تحقق سريع: لا بقايا استيفاء خريطة في const ──
if grep -q "\${'\$_langs" lib/features/card1_translation/document_screen.dart; then
  echo "✗ ما زال هناك استيفاء خريطة — تحقق يدوياً"
  grep -n "_langs" lib/features/card1_translation/document_screen.dart | head -5
  exit 1
fi
echo "✓ لا استيفاء خريطة في const"

git add -A
if git diff --cached --quiet; then
  echo "لا تغييرات — لم يُرفع شيء"
else
  git -c user.name="Mirror Scorpion CI" \
      -c user.email="ci@mirror-scorpion.local" \
      commit -m "fix(stage1): إصلاح استيفاء خريطة داخل const في document_screen (خطأ ترجمة Dart)"
  git push "https://x-access-token:${TOKEN}@github.com/${REPO}.git" HEAD:"$BRANCH"
  echo "✓ تم الرفع — بناء جديد بدأ"
fi
