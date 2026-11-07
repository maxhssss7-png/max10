#!/usr/bin/env bash
# يبني تطبيق Rose لأندرويد (APK) — يفتح https://maxhssss7-png.github.io/max/sh.html
set -euo pipefail
rm -rf p && mkdir -p p && cd p
mkdir -p app/src/main/java/com/husain/rose app/src/main/assets app/src/main/res/values app/src/main/res/xml
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do mkdir -p app/src/main/res/mipmap-$d; done

cat > settings.gradle <<'ROSE_EOF'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = "Rose"
include ':app'
ROSE_EOF

cat > build.gradle <<'ROSE_EOF'
plugins { id 'com.android.application' version '8.5.2' apply false }
ROSE_EOF

cat > gradle.properties <<'ROSE_EOF'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
ROSE_EOF

cat > app/build.gradle <<'ROSE_EOF'
plugins { id 'com.android.application' }
android {
    namespace 'com.husain.rose'
    compileSdk 34
    defaultConfig {
        applicationId "com.husain.rose"
        minSdk 23
        targetSdk 34
        versionCode((System.getenv("GITHUB_RUN_NUMBER") ?: "1").toInteger())
        versionName "1." + (System.getenv("GITHUB_RUN_NUMBER") ?: "1")
    }
    signingConfigs {
        rose {
            storeFile file('rose.jks')
            storePassword 'rose2026key'
            keyAlias 'rose'
            keyPassword 'rose2026key'
        }
    }
    buildTypes {
        debug { signingConfig signingConfigs.rose }
        release { minifyEnabled false; signingConfig signingConfigs.rose }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
dependencies {
    implementation 'androidx.webkit:webkit:1.11.0'
    implementation 'androidx.core:core:1.13.1'
}
ROSE_EOF

cat > app/src/main/AndroidManifest.xml <<'ROSE_EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <queries>
        <intent><action android:name="android.speech.RecognitionService" /></intent>
        <intent><action android:name="android.intent.action.TTS_SERVICE" /></intent>
    </queries>
    <application
        android:label="Rose"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher"
        android:supportsRtl="true"
        android:theme="@style/Rose">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait"
            android:configChanges="orientation|screenSize|keyboardHidden|uiMode"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="com.husain.rose.files"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
</manifest>
ROSE_EOF

cat > app/src/main/res/values/styles.xml <<'ROSE_EOF'
<resources>
    <color name="rose_bg">#0f1216</color>
    <style name="Rose" parent="@android:style/Theme.Material.NoActionBar">
        <item name="android:windowBackground">@color/rose_bg</item>
        <item name="android:statusBarColor">@color/rose_bg</item>
        <item name="android:navigationBarColor">@color/rose_bg</item>
    </style>
</resources>
ROSE_EOF

cat > app/src/main/res/xml/file_paths.xml <<'ROSE_EOF'
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <cache-path name="share" path="share/" />
</paths>
ROSE_EOF

cat > app/src/main/assets/bridge.js <<'ROSE_EOF'
(function () {
  // جسر Rose: يربط الصفحة بخصائص أندرويد (الصوت، الميكروفون، الخروج)
  if (window.__roseBridge) return;
  window.__roseBridge = 1;
  try { Object.defineProperty(navigator, "standalone", { get: function () { return true; } }); } catch (e) {}
  var N = window.RoseNative;
  if (!N) return;

  // النطق: صوت أندرويد بدل صوت المتصفح
  function U(t) { this.text = t || ""; this.lang = "ar"; this.rate = 1; this.voice = null; }
  window.SpeechSynthesisUtterance = U;
  var syn = {
    speaking: false, pending: false, paused: false, onvoiceschanged: null,
    getVoices: function () { return [{ lang: "ar-SA", name: "Android", default: true, localService: true, voiceURI: "android" }]; },
    speak: function (u) { try { N.speak(String(u.text || ""), +u.rate || 1); } catch (e) {} },
    cancel: function () { try { N.stop(); } catch (e) {} },
    pause: function () {}, resume: function () {},
    addEventListener: function () {}, removeEventListener: function () {}
  };
  try { Object.defineProperty(window, "speechSynthesis", { value: syn, configurable: true, writable: true }); }
  catch (e) { window.speechSynthesis = syn; }

  // البحث الصوتي: ميكروفون أندرويد
  function SR() { this.lang = "ar-IQ"; this.interimResults = false; this.maxAlternatives = 1;
    this.onstart = null; this.onresult = null; this.onerror = null; this.onend = null; }
  SR.prototype.start = function () { window.__roseSR = this; N.listen(this.lang || "ar-IQ"); };
  SR.prototype.stop = function () { N.stopListen(); };
  SR.prototype.abort = function () { N.stopListen(); this._end(); };
  SR.prototype._start = function () { if (this.onstart) this.onstart(); };
  SR.prototype._result = function (t) {
    var r = [{ transcript: t, confidence: 1 }]; r.isFinal = true;
    if (this.onresult) this.onresult({ results: [r] }); this._end();
  };
  SR.prototype._err = function (c) { if (this.onerror) this.onerror({ error: c }); this._end(); };
  SR.prototype._end = function () { if (window.__roseSR === this) window.__roseSR = null; if (this.onend) this.onend(); };
  window.SpeechRecognition = window.webkitSpeechRecognition = SR;

  // زر «خروج» داخل التطبيق يغلق التطبيق فعلاً
  window.close = function () { try { N.exit(); } catch (e) {} };
})();
ROSE_EOF

cat > app/src/main/java/com/husain/rose/MainActivity.java <<'ROSE_EOF'
package com.husain.rose;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.view.Window;
import android.webkit.GeolocationPermissions;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.webkit.WebViewCompat;
import androidx.webkit.WebViewFeature;

import org.json.JSONObject;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Locale;

public class MainActivity extends Activity {
    static final String URL = "https://maxhssss7-png.github.io/max/sh.html";
    static final String HOST = "maxhssss7-png.github.io";
    static final int REQ_LOC = 1, REQ_MIC = 2;

    WebView web;
    TextToSpeech tts;
    boolean ttsReady = false;
    SpeechRecognizer recognizer;
    GeolocationPermissions.Callback geoCallback;
    String geoOrigin;
    String bridgeJs = "";
    String pendingLang = "ar-IQ";

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        Window w = getWindow();
        w.setStatusBarColor(Color.parseColor("#0f1216"));
        w.setNavigationBarColor(Color.parseColor("#0f1216"));

        bridgeJs = readAsset("bridge.js");
        web = new WebView(this);
        web.setBackgroundColor(Color.parseColor("#0f1216"));
        setContentView(web);

        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setGeolocationEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setUserAgentString(s.getUserAgentString() + " RoseApp/1.0");

        web.addJavascriptInterface(new Bridge(), "RoseNative");
        final boolean docStart = WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT);
        if (docStart) {
            WebViewCompat.addDocumentStartJavaScript(web, bridgeJs, Collections.singleton("https://" + HOST));
        }

        web.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri u = request.getUrl();
                if (HOST.equals(u.getHost())) return false;
                try { startActivity(new Intent(Intent.ACTION_VIEW, u)); } catch (Exception e) { }
                return true;
            }

            @Override
            public void onPageStarted(WebView view, String url, Bitmap favicon) {
                if (!docStart) view.evaluateJavascript(bridgeJs, null);
            }
        });

        web.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback) {
                if (has(Manifest.permission.ACCESS_FINE_LOCATION)) {
                    callback.invoke(origin, true, true);
                    return;
                }
                geoCallback = callback;
                geoOrigin = origin;
                requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION}, REQ_LOC);
            }
        });

        tts = new TextToSpeech(this, status -> {
            if (status == TextToSpeech.SUCCESS) {
                tts.setLanguage(new Locale("ar"));
                ttsReady = true;
            }
        });

        if (state != null) web.restoreState(state);
        else {
            // نطلب الصفحة جديدة من GitHub في كل تشغيل، بدل النسخة المحفوظة في الهاتف
            java.util.Map<String, String> noCache = new java.util.HashMap<>();
            noCache.put("Cache-Control", "no-cache");
            noCache.put("Pragma", "no-cache");
            web.loadUrl(URL + "?t=" + System.currentTimeMillis(), noCache);
        }
    }

    String readAsset(String name) {
        try (InputStream in = getAssets().open(name)) {
            byte[] buf = new byte[in.available()];
            int read = 0;
            while (read < buf.length) {
                int k = in.read(buf, read, buf.length - read);
                if (k < 0) break;
                read += k;
            }
            return new String(buf, 0, read, StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "";
        }
    }

    boolean has(String permission) {
        return checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED;
    }

    void js(final String code) {
        runOnUiThread(() -> web.evaluateJavascript(code, null));
    }

    @Override
    public void onRequestPermissionsResult(int code, String[] permissions, int[] results) {
        boolean ok = results.length > 0 && results[0] == PackageManager.PERMISSION_GRANTED;
        if (code == REQ_LOC && geoCallback != null) {
            geoCallback.invoke(geoOrigin, ok, ok);
            geoCallback = null;
        }
        if (code == REQ_MIC) {
            if (ok) startListening(pendingLang);
            else js("window.__roseSR&&window.__roseSR._err('not-allowed')");
        }
    }

    void startListening(final String lang) {
        runOnUiThread(() -> {
            if (!SpeechRecognizer.isRecognitionAvailable(this)) {
                js("window.__roseSR&&window.__roseSR._err('not-available')");
                return;
            }
            if (recognizer == null) {
                recognizer = SpeechRecognizer.createSpeechRecognizer(this);
                recognizer.setRecognitionListener(new RecognitionListener() {
                    @Override public void onReadyForSpeech(Bundle params) { js("window.__roseSR&&window.__roseSR._start()"); }
                    @Override public void onBeginningOfSpeech() { }
                    @Override public void onRmsChanged(float rmsdB) { }
                    @Override public void onBufferReceived(byte[] buffer) { }
                    @Override public void onEndOfSpeech() { }
                    @Override public void onPartialResults(Bundle partialResults) { }
                    @Override public void onEvent(int eventType, Bundle params) { }
                    @Override public void onError(int error) {
                        String c = (error == SpeechRecognizer.ERROR_NO_MATCH || error == SpeechRecognizer.ERROR_SPEECH_TIMEOUT) ? "no-speech" : "error";
                        js("window.__roseSR&&window.__roseSR._err('" + c + "')");
                    }
                    @Override public void onResults(Bundle results) {
                        ArrayList<String> list = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
                        String text = (list != null && !list.isEmpty()) ? list.get(0) : "";
                        js("window.__roseSR&&window.__roseSR._result(" + JSONObject.quote(text) + ")");
                    }
                });
            }
            Intent i = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
            i.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
            i.putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang);
            recognizer.startListening(i);
        });
    }

    class Bridge {
        @JavascriptInterface
        public void speak(String text, float rate) {
            if (!ttsReady) return;
            tts.setSpeechRate(rate);
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "rose");
        }

        @JavascriptInterface
        public void stop() {
            if (tts != null) tts.stop();
        }

        @JavascriptInterface
        public void listen(String lang) {
            pendingLang = (lang == null || lang.isEmpty()) ? "ar-IQ" : lang;
            if (has(Manifest.permission.RECORD_AUDIO)) startListening(pendingLang);
            else runOnUiThread(() -> requestPermissions(new String[]{Manifest.permission.RECORD_AUDIO}, REQ_MIC));
        }

        @JavascriptInterface
        public void stopListen() {
            runOnUiThread(() -> { if (recognizer != null) recognizer.stopListening(); });
        }

        // مشاركة ملف التطبيق نفسه (Rose.apk) عبر واتساب أو تيليجرام أو غيرها
        @JavascriptInterface
        public void shareApp() {
            new Thread(() -> {
                try {
                    java.io.File src = new java.io.File(getApplicationInfo().sourceDir);
                    java.io.File dir = new java.io.File(getCacheDir(), "share");
                    dir.mkdirs();
                    java.io.File out = new java.io.File(dir, "Rose.apk");
                    try (InputStream in = new java.io.FileInputStream(src);
                         java.io.OutputStream os = new java.io.FileOutputStream(out)) {
                        byte[] buf = new byte[65536];
                        int n;
                        while ((n = in.read(buf)) > 0) os.write(buf, 0, n);
                    }
                    final Uri uri = androidx.core.content.FileProvider.getUriForFile(MainActivity.this, getPackageName() + ".files", out);
                    runOnUiThread(() -> {
                        Intent i = new Intent(Intent.ACTION_SEND);
                        i.setType("application/vnd.android.package-archive");
                        i.putExtra(Intent.EXTRA_STREAM, uri);
                        i.putExtra(Intent.EXTRA_TEXT, "تطبيق Rose للخرائط والتوجيه في العراق");
                        i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                        startActivity(Intent.createChooser(i, "شارك Rose عبر"));
                    });
                } catch (Exception e) {
                    js("window.__roseToast&&window.__roseToast('تعذّرت مشاركة التطبيق')");
                }
            }).start();
        }

        @JavascriptInterface
        public void exit() {
            runOnUiThread(() -> finish());
        }
    }

    @Override
    public void onBackPressed() {
        if (web.canGoBack()) web.goBack();
        else super.onBackPressed();
    }

    @Override
    protected void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        web.saveState(out);
    }

    @Override
    protected void onDestroy() {
        if (tts != null) tts.shutdown();
        if (recognizer != null) recognizer.destroy();
        web.destroy();
        super.onDestroy();
    }
}
ROSE_EOF

echo "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" | base64 -d > ic.png
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do cp ic.png app/src/main/res/mipmap-$d/ic_launcher.png; done
rm ic.png
echo "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" | base64 -d > app/rose.jks

gradle assembleDebug --no-daemon --stacktrace
cp app/build/outputs/apk/debug/app-debug.apk ../Rose.apk
echo "تم بناء Rose.apk"
