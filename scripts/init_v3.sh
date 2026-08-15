#!/bin/bash
# ==============================================================================
# Mirror Scorpion v3 - Clean Foundation & GitHub Initialization
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

C_GREEN='\033[0;32m'; C_RED='\033[0;31m'; C_CYN='\033[0;36m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[INIT-V3]${C_END} $*"; }
ok() { echo -e "${C_GREEN}  [✔] $*${C_END}"; }
err() { echo -e "${C_RED}  [✘] $*${C_END}"; }

V3_DIR="$HOME/mirror_scorpion_v3"
TOKEN_FILE="$HOME/.ms_gh_token"

log "إنشاء وتجهيز هيكل المشروع الجديد في: $V3_DIR"

rm -rf "$V3_DIR"
mkdir -p "$V3_DIR"
cd "$V3_DIR"

# 1. إنشاء pubspec.yaml حديث ونظيف
cat << 'EOPUB' > pubspec.yaml
name: mirror_scorpion_v3
description: "Mirror Scorpion v3 - حيث تُصنع البدايات بنقاء واستقرار"
publish_to: 'none'
version: 1.3.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.5+1
  http: ^1.6.0
  shared_preferences: ^2.5.5
  path_provider: ^2.1.6
  flutter_tts: ^4.2.5
  sqflite: ^2.4.3
  intl: ^0.20.2
  permission_handler: ^13.0.0
  speech_to_text: ^7.0.0
  image_picker: ^1.2.3
  webview_flutter: ^4.10.0
  file_picker: ^8.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/
EOPUB
ok "تم إنشاء pubspec.yaml بأحدث الإصدارات المتوافقة"

# 2. إنشاء الهيكل الهندسي للمجلدات
mkdir -p lib/core/theme lib/core/services lib/core/widgets
mkdir -p lib/features/home lib/features/translation lib/features/dialogue lib/features/documents lib/features/stories lib/features/games lib/features/settings
mkdir -p assets/data assets/images android ios

# 3. إنشاء نقطة الانطلاق الرئيسية lib/main.dart
cat << 'EOMAIN' > lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MirrorScorpionApp());
}

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirror Scorpion v3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            '🦂 Mirror Scorpion v3\nClean & Stable Foundation',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
EOMAIN
ok "تم إنشاء نقطة الانطلاق lib/main.dart"

# 4. تهيئة Git والرفع الأولي للمستودع الجديد
log "إعداد المستودع المحلي والربط مع GitHub..."

git init
git branch -M main
git config --global user.name "Tamer Eldosoky"
git config --global user.email "dosoky.server@gmail.com"

if [ -f "$TOKEN_FILE" ]; then
    GH_TOKEN=$(cat "$TOKEN_FILE" | tr -d '\r\n')
    AUTH_REPO_URL="https://${GH_TOKEN}@github.com/magdymeko456-cell/mirror_scorpion_v3.git"
    git remote add origin "$AUTH_REPO_URL" 2>/dev/null || git remote set-url origin "$AUTH_REPO_URL"
fi

# إنشاء ملف .gitignore
cat << 'EOGIT' > .gitignore
.dart_tool/
.build/
.pub/
build/
EOGIT

git add .
git commit -m "feat(init): baseline foundation for Mirror Scorpion v3"

log "جاري رفع البداية النظيفة إلى المستودع السحابي..."
git push -u origin main --force || err "يرجى التأكد من إنشاء المستودع mirror_scorpion_v3 على حساب GitHub"

ok "تم تجهيز ورفع الأساس النظيف لمشروع mirror_scorpion_v3 بنجاح!"
