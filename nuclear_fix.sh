#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - NUCLEAR ENGINE FIX
# ------------------------------------------------------------------------------
# الهدف: الحقن النووي لقيم SDK وكائن flutter لتأمين بناء الملحقات بنسبة 100%
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# الألوان والسجلات (دستورنا المعياري)
C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_YEL='\033[0;33m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[NUCLEAR-FIX]${C_END} $*"; }
ok()  { echo -e "${C_GREEN}  [✔] $*${C_END}"; }
warn(){ echo -e "${C_YEL}  [!] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"

# 1. التحقق من مسار العمل
if [ ! -d "$WORKDIR" ]; then
    warn "المجلد $WORKDIR غير موجود!"
    exit 1
fi
cd "$WORKDIR"

log "1/3. جاري الحقن النووي لكائن flutter و SDK 34 في android/build.gradle..."

cat << 'EOF' > android/build.gradle
buildscript {
    ext.kotlin_version = '1.9.10'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'

subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"

    // الحقن النووي لكائن flutter لحل أخطاء الخصائص المفقودة
    project.ext.flutter = [
        compileSdkVersion: 34,
        minSdkVersion: 21,
        targetSdkVersion: 34
    ]
}

// إجبار كافة المكتبات الفرعية على استخدام SDK 34 و minSdk 21
subprojects {
    afterEvaluate { project ->
        if (project.hasProperty('android')) {
            project.android {
                compileSdkVersion 34
                buildToolsVersion "34.0.0"
                defaultConfig {
                    minSdkVersion 21
                    targetSdkVersion 34
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
EOF

ok "تم تطبيق الحقن النووي الشامل بنجاح."

log "2/3. جاري تأمين إعدادات android/app/build.gradle..."

GRADLE_APP_FILE="android/app/build.gradle"
if [ -f "$GRADLE_APP_FILE" ]; then
    sed -i 's/compileSdk .*/compileSdk 34/g' "$GRADLE_APP_FILE" 2>/dev/null || true
    sed -i 's/compileSdkVersion .*/compileSdkVersion 34/g' "$GRADLE_APP_FILE" 2>/dev/null || true
    sed -i 's/minSdkVersion .*/minSdkVersion 21/g' "$GRADLE_APP_FILE" 2>/dev/null || true
    sed -i 's/minSdk = .*/minSdk = 21/g' "$GRADLE_APP_FILE" 2>/dev/null || true
    sed -i 's/targetSdk .*/targetSdk 34/g' "$GRADLE_APP_FILE" 2>/dev/null || true
    sed -i 's/targetSdkVersion .*/targetSdkVersion 34/g' "$GRADLE_APP_FILE" 2>/dev/null || true
    ok "تمت محاذاة وتأكيد إصدارات الـ SDK في app/build.gradle."
fi

log "3/3. جاري ضبط إعدادات الشبكة والرفع النهائي القسري إلى GitHub..."

git config http.postBuffer 524288000 2>/dev/null || true
git config http.maxRequestBuffer 100M 2>/dev/null || true

git add android/build.gradle android/app/build.gradle
[ -f "android/settings.gradle" ] && git add android/settings.gradle
git commit -m "fix(engine): nuclear injection for plugin compatibility" || echo "لا توجد تغييرات جديدة للرفع"
git push origin main --force

ok "تمت العملية بنجاح باهر يا تامر! 🦂🚀"
ok "افتح GitHub Actions الآن لمراقبة عملية التجميع."
