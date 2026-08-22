#!/bin/bash
set -Eeuo pipefail

TARGET_DIR="$HOME/mirror_scorpion_v3"
TEMP_CLONE="$HOME/old_mirror_base_temp"

echo "=== بدء عملية دمج الأساس الناجح ==="

# تنظيف المجلد المؤقت إذا كان موجوداً
rm -rf "$TEMP_CLONE"

# جلب الكود الناجح من المستودع القديم
git clone --depth 1 https://github.com/magdymeko456-cell/mirror_scorpion_translate_version_2.git "$TEMP_CLONE"

# التأكد من وجود المجلد الهدف
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# نسخ ملفات الإعدادات و workflows والكود الرئيسي
echo "1. نسخ ملفات البناء و Workflows الناجحة..."
mkdir -p .github/workflows
cp -rf "$TEMP_CLONE/.github/workflows/"* .github/workflows/

echo "2. تحديث هيكل المشروع والكود..."
cp -rf "$TEMP_CLONE/lib" ./ 2>/dev/null || true
cp -rf "$TEMP_CLONE/android" ./ 2>/dev/null || true
cp -f "$TEMP_CLONE/pubspec.yaml" ./ 2>/dev/null || true

# تنظيف المؤقت
rm -rf "$TEMP_CLONE"

echo "✔ تم دمج كود الأساس الناجح بنجاح!"
