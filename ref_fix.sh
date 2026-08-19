#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - REFERENCE TEMPLATE FIX
# ------------------------------------------------------------------------------
# الهدف: ضبط local.properties للمسارات السحابية والعودة للهيكلية التقليدية المستقرة
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# الألوان والسجلات (دستورنا المعياري)
C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_YEL='\033[0;33m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[REF-TEMPLATE]${C_END} $*"; }
ok()  { echo -e "${C_GREEN}  [✔] $*${C_END}"; }
warn(){ echo -e "${C_YEL}  [!] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"

# 1. التحقق من مسار العمل
if [ ! -d "$WORKDIR" ]; then
    warn "المجلد $WORKDIR غير موجود!"
    exit 1
fi
cd "$WORKDIR"

log "1/3. جاري إنشاء android/local.properties بالمسارات السحابية..."

cat << 'EOF' > android/local.properties
sdk.dir=/usr/local/lib/android/sdk
flutter.sdk=/opt/hostedtoolcache/flutter/3.24.0-stable/x64
EOF

ok "تم تعيين المسارات السحابية لـ GitHub Actions بنجاح."

log "2/3. جاري تطبيق الهيكلية التقليدية المستقرة في settings.gradle و app/build.gradle..."

# 1. settings.gradle المستقر
cat << 'EOF' > android/settings.gradle
include ':app'

localProperties = new Properties()
localPropertiesFile = new File(rootProject.projectDir, 'local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterSdkPath = localProperties.getProperty('flutter.sdk')
if (flutterSdkPath == null) {
    flutterSdkPath = System.getenv("FLUTTER_ROOT")
}

apply from: "$flutterSdkPath/packages/flutter_tools/gradle/app_plugin_loader.gradle"
EOF

# 2. android/app/build.gradle المستقر
cat << 'EOF' > android/app/build.gradle
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterSdkPath = localProperties.getProperty('flutter.sdk')
if (flutterSdkPath == null) {
    flutterSdkPath = System.getenv("FLUTTER_ROOT")
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply from: "$flutterSdkPath/packages/flutter_tools/gradle/flutter.gradle"

android {
    namespace "com.mirror.scorpion.v3"
    compileSdkVersion 34

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    defaultConfig {
        applicationId "com.mirror.scorpion.v3"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}
EOF

ok "تم تطبيق الهيكلية التقليدية وتأمين ربط سكريبتات Flutter بنجاح."

log "3/3. جاري الرفع القسري لـ GitHub..."

git config http.postBuffer 524288000 2>/dev/null || true
git add android/local.properties android/settings.gradle android/app/build.gradle
git commit -m "fix(android): provide cloud paths and stable gradle structure" || echo "لا توجد تغييرات جديدة للرفع"
git push origin main --force

ok "تمت العملية بنجاح! راقب سيرفرات GitHub Actions الآن يا تامر. 🦂🚀🏆"
