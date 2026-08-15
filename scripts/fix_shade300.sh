#!/bin/bash
# fix_shade300.sh v2 — إصلاح const TextStyle مع shadeXXX + رفع (مصحح: import re)
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

# ── [1] إصلاح شامل: كل const TextStyle فيه shadeXXX / withOpacity عبر lib/ بالكامل ──
python3 - <<'PY'
import os, re

fixed_total = 0
for root, _, files in os.walk('lib'):
    for f in files:
        if not f.endswith('.dart'):
            continue
        fp = os.path.join(root, f)
        data = open(fp, encoding='utf-8', errors='ignore').read()
        orig = data
        data, a = re.subn(
            r'const TextStyle\(color: Colors\.\w+\.shade\d+',
            lambda m: m.group(0).replace('const TextStyle(', 'TextStyle(', 1),
            data)
        data, b = re.subn(
            r'const TextStyle\(color: Colors\.\w+\.withOpacity',
            lambda m: m.group(0).replace('const TextStyle(', 'TextStyle(', 1),
            data)
        if data != orig:
            open(fp, 'w', encoding='utf-8').write(data)
            print(f'  {fp}: أُصلح {a + b}')
            fixed_total += a + b
print(f'  الإجمالي: {fixed_total} موضع const غير قانوني أُصلح')
PY

# ── [2] تنظيف الحقول غير المستخدمة في document_screen (يمنع تحذير analyzer) ──
python3 - <<'PY'
import re
p = 'lib/features/card1_translation/document_screen.dart'
s = open(p, encoding='utf-8').read()
s = re.sub(r'^\s*bool _showOriginal = true;\s*$', '', s, flags=re.M)
s = re.sub(r'^\s*bool _showTranslatedDoc = false;\s*$', '', s, flags=re.M)
open(p, 'w', encoding='utf-8').write(s)
print('  ✓ تنظيف الحقول غير المستخدمة')
PY

# ── [3] تحقق نهائي: لا const مع shade/withOpacity متبقٍ ──
if grep -rn "const TextStyle(color: Colors\..*\(shade\|withOpacity\)" lib/ 2>/dev/null; then
  echo "✗ ما زالت هناك مواضع مكسورة — تحقق يدوياً أعلاه"
  exit 1
fi
echo "✓ لا مواضع const مكسورة في lib/"

git add -A
if git diff --cached --quiet; then
  echo "لا تغييرات — لم يُرفع شيء"
else
  git -c user.name="Mirror Scorpion CI" \
      -c user.email="ci@mirror-scorpion.local" \
      commit -m "fix(stage1): إزالة const من TextStyle مع shadeXXX — خطأ ترجمة Dart (MaterialColor ليست const)"
  git push "https://x-access-token:${TOKEN}@github.com/${REPO}.git" HEAD:"$BRANCH"
  echo "✓ تم الرفع — بناء جديد بدأ"
fi
