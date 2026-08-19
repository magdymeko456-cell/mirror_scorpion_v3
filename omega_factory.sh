#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - SCORPION OMEGA FACTORY
# ------------------------------------------------------------------------------
# الهدف: تطبيق الهيكلية الحديثة (Declarative Gradle) وتأمين الربط مع Flutter SDK
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# الألوان والسجلات (دستورنا المعياري)
C_GREEN='\033[0;32m'; C_CYN='\033[0;36m'; C_YEL='\033[0;33m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[OMEGA-FACTORY]${C_END} $*"; }
ok()  { echo -e "${C_GREEN}  [✔] $*${C_END}"; }
warn(){ echo -e "${C_YEL}  [!] $*${C_END}"; }

WORKDIR="$HOME/mirror_scorpion_v3"

# 1. التحقق من مسار العمل
if [ ! -d "$WORKDIR" ]; then
    warn "المجلد $WORKDIR غير موجود!"
    exit 1
fi
cd "$WORKDIR"

log "1/3. جاري تحديث android/settings.gradle للهيكلية الحديثة..."

cat << 'EOF' > android/settings.gradle
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        def file = new File(rootProject.projectDir, "local.properties")
        if (file.exists()) {
            file.withReader('UTF-8') { reader -> properties.load(reader) }
        }
        def sdkPath = properties.getProperty("flutter.sdk")
        assert sdkPath != null : "flutter.sdk not set in local.properties"
        return sdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.1.0" apply false
    id "org.jetbrains.kotlin.android" version "1.8.22" apply false
}

include ":app"
EOF

ok "تم تحديث settings.gradle بالربط الحديث بنجاح."

log "2/3. جاري ضبط android/app/build.gradle وإعدادات Android..."

cat << 'EOF' > android/app/build.gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.mirror.scorpion.v3"
    compileSdk 34

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
        versionCode 1
        versionName "1.0.0"
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

# تحديث android/build.gradle الرئيسي ليكون نقيًا ومتوافقًا مع النظام الحديث
cat << 'EOF' > android/build.gradle
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
EOF

ok "تم ضبط app/build.gradle و build.gradle بأسلوب التصريح الحديث."

log "3/3. جاري الرفع النهائي لـ GitHub..."

git add android/settings.gradle android/build.gradle android/app/build.gradle
git commit -m "fix(android): implement modern declarative gradle structure" || echo "لا توجد تغييرات جديدة للرفع"

# ضبط الشبكة لتفادي أخطاء RPC أثناء الرفع
git config http.postBuffer 524288000 2>/dev/null || true
git push origin main

ok "تمت العملية بنجاح! راقب GitHub Actions الآن يا تامر. 🦂🚀🏆"

