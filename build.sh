#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="DeepSeekMenuBar"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

echo "=== Building DeepSeek 工具箱 ==="

# Step 1: Build WebUI if exists
if [ -d "$PROJECT_DIR/WebUI" ]; then
    echo ""
    echo "[1/4] Building WebUI..."
    cd "$PROJECT_DIR/WebUI"
    if [ -f "package.json" ]; then
        npm install --silent
        npm run build
        echo "  WebUI build complete (single-file output)."
    else
        echo "  No package.json found in WebUI, skipping."
    fi
    cd "$PROJECT_DIR"
else
    echo ""
    echo "[1/4] WebUI directory not found, skipping."
fi

# Step 2: Build Swift executable
echo ""
echo "[2/4] Building Swift executable..."
cd "$PROJECT_DIR"
swift build -c release --product "$APP_NAME" --disable-sandbox
EXECUTABLE_PATH="$BUILD_DIR/release/$APP_NAME"
echo "  Swift build complete: $EXECUTABLE_PATH"

# Step 3: Create .app bundle structure
echo ""
echo "[3/4] Creating .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$EXECUTABLE_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Generate and copy app icon
 echo "  Generating app icon..."
 if [ -f "$PROJECT_DIR/Resources/deepseek-whale.png" ]; then
     swift "$PROJECT_DIR/gen_icon.swift" "$PROJECT_DIR/Resources/deepseek-whale.png" "$PROJECT_DIR/Resources"
 else
     swift "$PROJECT_DIR/gen_icon.swift" "$PROJECT_DIR/Resources"
 fi
if [ -f "$PROJECT_DIR/Resources/app.icns" ]; then
    cp "$PROJECT_DIR/Resources/app.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "  App icon copied."
fi

# Copy WebUI dist if exists
if [ -d "$PROJECT_DIR/WebUI/dist" ]; then
    cp -r "$PROJECT_DIR/WebUI/dist" "$APP_BUNDLE/Contents/Resources/dist"
    echo "  WebUI dist copied."
fi

# Copy Assets if exists
if [ -d "$PROJECT_DIR/Resources/Assets.xcassets" ]; then
    cp -r "$PROJECT_DIR/Resources/Assets.xcassets" "$APP_BUNDLE/Contents/Resources/Assets.xcassets"
fi

echo "  .app bundle created at: $APP_BUNDLE"

# Step 4: Code sign (if available)
echo ""
echo "[4/4] Code signing..."
if command -v codesign &> /dev/null; then
    codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true
    echo "  Code signing complete (ad-hoc)."
else
    echo "  codesign not found, skipping."
fi

echo ""
echo "=== Build Complete ==="
echo "App: $APP_BUNDLE"
echo ""
echo "To run: open \"$APP_BUNDLE\""
