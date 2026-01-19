#!/bin/bash

# Android StudioとXcodeの両方でアプリを同時に起動するスクリプト

cd "$(dirname "$0")"

echo "利用可能なデバイスを確認中..."
flutter devices

echo ""
echo "AndroidエミュレーターとiOSシミュレーターの両方でアプリを起動します..."
echo ""

# デバイスを検出（デバイスID/名前を取得）
ANDROID_DEVICE=$(flutter devices 2>/dev/null | grep -i "android" | head -1 | awk -F'•' '{print $2}' | xargs)
IOS_DEVICE=$(flutter devices 2>/dev/null | grep -i "iPhone" | head -1 | awk -F'•' '{print $1}' | awk '{print $1 " " $2}' | xargs)

# デバイスが見つからない場合の処理
if [ -z "$ANDROID_DEVICE" ]; then
    echo "⚠️  Androidエミュレーターが見つかりません。Androidエミュレーターを起動してください。"
    ANDROID_DEVICE=""
else
    echo "📱 Androidエミュレーターを検出: $ANDROID_DEVICE"
fi

if [ -z "$IOS_DEVICE" ]; then
    echo "⚠️  iOSシミュレーターが見つかりません。シミュレーターを起動してください。"
    IOS_DEVICE=""
else
    echo "🍎 iOSシミュレーターを検出: $IOS_DEVICE"
fi

echo ""

# Androidエミュレーターで実行（バックグラウンド）
if [ -n "$ANDROID_DEVICE" ]; then
    echo "📱 Androidエミュレーターで起動中..."
    flutter run -d "$ANDROID_DEVICE" &
    ANDROID_PID=$!
else
    ANDROID_PID=""
fi

# 少し待ってからiOSシミュレーターで実行
if [ -n "$IOS_DEVICE" ]; then
    sleep 2
    echo "🍎 iOSシミュレーターで起動中..."
    flutter run -d "$IOS_DEVICE" &
    IOS_PID=$!
else
    IOS_PID=""
fi

echo ""
if [ -n "$ANDROID_PID" ] || [ -n "$IOS_PID" ]; then
    echo "✅ アプリが起動しました！"
    [ -n "$ANDROID_PID" ] && echo "   AndroidプロセスID: $ANDROID_PID"
    [ -n "$IOS_PID" ] && echo "   iOSプロセスID: $IOS_PID"
    echo ""
    echo "終了するには、Ctrl+Cを押すか、以下のコマンドを実行してください:"
    [ -n "$ANDROID_PID" ] && [ -n "$IOS_PID" ] && echo "kill $ANDROID_PID $IOS_PID"
    [ -n "$ANDROID_PID" ] && [ -z "$IOS_PID" ] && echo "kill $ANDROID_PID"
    [ -z "$ANDROID_PID" ] && [ -n "$IOS_PID" ] && echo "kill $IOS_PID"
    
    # 両方のプロセスが終了するまで待機
    wait
else
    echo "❌ 起動可能なデバイスが見つかりませんでした。"
    exit 1
fi
