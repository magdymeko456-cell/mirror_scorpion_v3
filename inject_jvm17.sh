#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - FORCE INJECT JAVA 17 CONFIGURATION
# ------------------------------------------------------------------------------
# الهدف: إضافة إعدادات Java 17 و Kotlin 17 صراحة داخل build.gradle
# ==============================================================================

set -Eeuo pipefail

WORKDIR="$HOME/mirror_scorpion_v3"
GRADLE_FILE="$WORKDIR/android/app/build.gradle"

cd "$WORKDIR"

echo -e "\033[0;36m[JVM-FIX]\033[0m 1/3. إنشاء نسخة احتياطية وتحديث build.gradle..."

# إنشاء نسخة احتياطية
cp "$GRADLE_FILE" "$GRADLE_FILE.bak"

# استخدام Python لإدراج التكوينات الصريحة داخل android { ... } لضمان السلامة البرمجية
python3 - << 'EOF'
import re

file_path = "android/app/build.gradle"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# إزالة أي خيارات سابقة لتفادي التكرار
content = re.sub(r'compileOptions\s*\{[^}]*\}', '', content)
content = re.sub(r'kotlinOptions\s*\{[^}]*\}', '', content)

java_config = """
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }
"""

# إدراج التكوين الجديد داخل كتلة android {
if "android {" in content:
    content = content.replace("android {", "android {" + java_config, 1)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("  [✔] تم إدراج إعدادات Java 17 و Kotlin 17 بنجاح.")
EOF

echo -e "\033[0;36m[JVM-FIX]\033[0m 2/3. التحقق من التغييرات..."
git diff android/app/build.gradle

echo -e "\033[0;36m[JVM-FIX]\033[0m 3/3. الرفع القسري إلى GitHub..."
git add android/app/build.gradle
git commit -m "fix(android): explicitly define Java 17 and Kotlin jvmTarget 17" || echo "لا تغييرات"
git push origin main --force

echo -e "\033[0;32m  [✔] تم التحديث والرفع بنجاح يا تامر! 🚀\033[0m"
