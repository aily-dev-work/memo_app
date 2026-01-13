#!/bin/zsh
# JDK 17のJAVA_HOME設定スクリプト

# .zshrcファイルを作成または更新
if [ ! -f ~/.zshrc ]; then
    touch ~/.zshrc
fi

# JAVA_HOME設定を追加（既存の設定をチェック）
if ! grep -q "JAVA_HOME.*openjdk@17" ~/.zshrc; then
    echo "" >> ~/.zshrc
    echo "# Java 17設定" >> ~/.zshrc
    echo "export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home" >> ~/.zshrc
    echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> ~/.zshrc
    echo "設定を追加しました"
else
    echo "既に設定されています"
fi

# 現在のシェルに適用
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"

echo "JAVA_HOME: $JAVA_HOME"
echo "Java version:"
$JAVA_HOME/bin/java -version
