# Wireless Deployment Guide - ADB over WiFi

**Date:** October 18, 2025  
**Status:** Recommended Alternative to Shorebird

---

## 🎯 Why ADB WiFi Instead of Shorebird?

Shorebird is encountering compatibility issues:
- Custom Flutter version conflicts (3.35.6 vs 3.24.5)
- CardTheme API changes between versions
- speech_to_text plugin compilation errors with Shorebird's Flutter build

**ADB WiFi** is simpler, faster, and works with your existing setup!

---

## 📱 Setup ADB WiFi (One-Time Setup)

### Step 1: Connect via USB First
```bash
# Connect your phone via USB cable
adb devices
```

### Step 2: Enable WiFi Debugging
```bash
# Enable TCP/IP on port 5555
adb tcpip 5555
```

### Step 3: Find Your Phone's IP Address
On your Android phone:
1. Go to **Settings** → **About Phone** → **Status**
2. Find **IP Address** (e.g., `192.168.1.100`)

### Step 4: Connect via WiFi
```bash
# Replace with your phone's IP
adb connect 192.168.1.100:5555
```

### Step 5: Disconnect USB Cable
You can now unplug the USB cable! 🎉

---

## 🚀 Deploy Updates Wirelessly

### Standard Deploy (Full Build)
```bash
flutter run --release
```

### Hot Reload (During Development)
```bash
flutter run  # Then press 'r' for hot reload, 'R' for hot restart
```

### Install APK Wirelessly
```bash
# Build APK
flutter build apk --release

# Install via WiFi
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 💡 Pro Tips

### Keep WiFi Connection Active
```bash
# Check if still connected
adb devices

# Reconnect if needed
adb connect 192.168.1.100:5555
```

### Multiple Devices
```bash
# List all devices
adb devices

# Deploy to specific device
adb -s 192.168.1.100:5555 install app-release.apk
```

### Troubleshooting
```bash
# If connection drops
adb disconnect
adb connect 192.168.1.100:5555

# If port is busy
adb kill-server
adb start-server
```

---

## ⚡ Quick Deploy Workflow

1. Make code changes
2. Run: `flutter run --release`
3. App deploys wirelessly!
4. Test on your phone

---

## 📊 Comparison

| Feature | ADB WiFi | Shorebird OTA |
|---------|----------|---------------|
| Setup Time | 2 minutes | 15+ minutes |
| Compatibility | ✅ Works with any Flutter | ⚠️ Version conflicts |
| Speed | Fast (1-2 min) | Very Fast (10-30 sec) |
| Internet Required | No (local network) | Yes |
| App Store | Need Google Play | Skip store updates |
| Best For | Development & Testing | Production updates |

---

## 🎯 Current Status

✅ **Ready to Use:** ADB WiFi works with your current setup  
⚠️ **On Hold:** Shorebird (waiting for Flutter version compatibility)

---

## 🔧 Next Steps

1. Connect your phone via USB
2. Run: `adb tcpip 5555`
3. Find phone IP address
4. Run: `adb connect <IP>:5555`
5. Unplug USB
6. Run: `flutter run --release`

**You're ready for wireless deployment!** 🚀
