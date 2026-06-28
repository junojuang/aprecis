package com.aprecis.ui.lesson

import android.annotation.SuppressLint
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Bookmark
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.unit.dp
import com.aprecis.ui.theme.PaperBg
import java.net.URL
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun WebLessonScreen(
    paperId: String,
    title: String,
    url: String,
    isSaved: Boolean,
    onClose: () -> Unit,
    onDone: () -> Unit,
    onMarkDone: () -> Unit,
    onToggleSaved: () -> Unit,
    onInteraction: (String) -> Unit,
) {
    val context = LocalContext.current
    var progress by remember(url) { mutableFloatStateOf(0f) }
    var canGoBack by remember(url) { mutableStateOf(false) }
    var webViewRef by remember(url) { mutableStateOf<WebView?>(null) }
    var isLoading by remember(url) { mutableStateOf(true) }
    var errorMessage by remember(url) { mutableStateOf<String?>(null) }
    var bundleHtml by remember(url) { mutableStateOf<String?>(null) }
    var loadedHtmlForUrl by remember(url) { mutableStateOf<String?>(null) }
    var reloadToken by remember(url) { mutableIntStateOf(0) }

    LaunchedEffect(url, reloadToken) {
        isLoading = true
        errorMessage = null
        loadedHtmlForUrl = null
        bundleHtml = runCatching {
            withContext(Dispatchers.IO) {
                URL(url).readText()
            }
        }.fold(
            onSuccess = { html -> html },
            onFailure = { error ->
                isLoading = false
                errorMessage = error.message ?: "Could not load this lesson."
                null
            },
        )
    }

    BackHandler {
        val webView = webViewRef
        if (webView?.canGoBack() == true) {
            webView.goBack()
        } else {
            onClose()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PaperBg),
    ) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = {
                WebView(context).apply {
                    webViewRef = this
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    settings.mediaPlaybackRequiresUserGesture = false
                    settings.loadsImagesAutomatically = true
                    settings.useWideViewPort = false
                    settings.setSupportZoom(false)
                    setBackgroundColor(android.graphics.Color.TRANSPARENT)
                    addJavascriptInterface(
                        AprecisBridge(
                            context = context,
                            paperId = paperId,
                            onClose = onClose,
                            onDone = onDone,
                            onMarkDone = onMarkDone,
                            onInteraction = onInteraction,
                        ),
                        "AndroidAprecis",
                    )
                    webChromeClient = object : WebChromeClient() {
                        override fun onProgressChanged(view: WebView?, newProgress: Int) {
                            progress = newProgress / 100f
                        }
                    }
                    webViewClient = object : WebViewClient() {
                        override fun onPageStarted(view: WebView, startedUrl: String?, favicon: android.graphics.Bitmap?) {
                            isLoading = true
                            errorMessage = null
                            view.evaluateJavascript(androidBridgeScript(), null)
                        }

                        override fun onPageFinished(view: WebView, loadedUrl: String?) {
                            canGoBack = view.canGoBack()
                            isLoading = false
                            view.evaluateJavascript(androidBridgeScript(), null)
                        }

                        override fun onReceivedError(
                            view: WebView,
                            request: WebResourceRequest,
                            error: WebResourceError,
                        ) {
                            if (request.isForMainFrame) {
                                isLoading = false
                                errorMessage = error.description?.toString() ?: "Could not load this lesson."
                            }
                        }

                        override fun shouldOverrideUrlLoading(
                            view: WebView,
                            request: WebResourceRequest,
                        ): Boolean {
                            val target = request.url.toString()
                            return if (target.startsWith("http") && !sameBundleUrl(url, target)) {
                                openUrl(context, target)
                                true
                            } else {
                                false
                            }
                        }
                    }
                }
            },
            update = { webView ->
                val html = bundleHtml
                if (html != null && loadedHtmlForUrl != url) {
                    loadedHtmlForUrl = url
                    progress = 0.1f
                    webView.loadDataWithBaseURL(
                        url,
                        html,
                        "text/html",
                        "UTF-8",
                        url,
                    )
                }
                canGoBack = webView.canGoBack()
            },
        )

        if (progress in 0.01f..0.99f) {
            LinearProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxWidth())
        }

        if (isLoading) {
            CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
        }

        errorMessage?.let { message ->
            LessonLoadError(
                title = title,
                message = message,
                onClose = onClose,
                onRetry = {
                    errorMessage = null
                    isLoading = true
                    loadedHtmlForUrl = null
                    bundleHtml = null
                    reloadToken += 1
                },
            )
        }

        FloatingActionButton(
            onClick = onToggleSaved,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(18.dp)
                .size(48.dp),
            shape = CircleShape,
            containerColor = MaterialTheme.colorScheme.surface,
            contentColor = MaterialTheme.colorScheme.primary,
        ) {
            Icon(
                if (isSaved) Icons.Outlined.Bookmark else Icons.Outlined.BookmarkBorder,
                contentDescription = if (isSaved) "Unsave" else "Save",
            )
        }
    }
}

@Composable
private fun LessonLoadError(
    title: String,
    message: String,
    onClose: () -> Unit,
    onRetry: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(PaperBg)
            .padding(24.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(title, style = MaterialTheme.typography.titleMedium)
            Text(message, color = MaterialTheme.colorScheme.onSurfaceVariant)
            TextButton(onClick = onRetry) { Text("Retry") }
            TextButton(onClick = onClose) { Text("Close") }
        }
    }
}

private class AprecisBridge(
    private val context: Context,
    private val paperId: String,
    private val onClose: () -> Unit,
    private val onDone: () -> Unit,
    private val onMarkDone: () -> Unit,
    private val onInteraction: (String) -> Unit,
) {
    private val mainHandler = Handler(Looper.getMainLooper())

    @JavascriptInterface
    fun close(@Suppress("UNUSED_PARAMETER") body: String?) {
        mainHandler.post(onClose)
    }

    @JavascriptInterface
    fun finish(@Suppress("UNUSED_PARAMETER") body: String?) {
        mainHandler.post(onDone)
    }

    @JavascriptInterface
    fun markDone(@Suppress("UNUSED_PARAMETER") body: String?) {
        mainHandler.post(onMarkDone)
    }

    @JavascriptInterface
    fun haptic(body: String?) {
        mainHandler.post { vibrate(context, body) }
    }

    @JavascriptInterface
    fun openOriginal(body: String?) {
        val target = Regex(""""url"\s*:\s*"([^"]+)"""").find(body.orEmpty())?.groupValues?.getOrNull(1)
        mainHandler.post { openUrl(context, target ?: "") }
    }

    @JavascriptInterface
    fun select(body: String?) {
        haptic(body)
    }

    @JavascriptInterface
    fun success(body: String?) {
        haptic(body)
        mainHandler.post { onInteraction("lesson_success") }
    }

    @JavascriptInterface
    fun interaction(body: String?) {
        val action = Regex(""""action"\s*:\s*"([^"]+)"""").find(body.orEmpty())?.groupValues?.getOrNull(1)
        mainHandler.post { onInteraction(action ?: "web_interaction") }
    }

    @JavascriptInterface
    fun progress(body: String?) {
        val value = Regex(""""progress"\s*:\s*([0-9.]+)""").find(body.orEmpty())?.groupValues?.getOrNull(1)
        mainHandler.post { onInteraction("progress:${value ?: "unknown"}") }
    }

    @JavascriptInterface
    fun log(message: String?) {
        android.util.Log.d("AprecisWebLesson", "$paperId: ${message.orEmpty()}")
    }
}

private fun androidBridgeScript(): String = """
    (function() {
      if (window.__aprecisAndroidBridgeInstalled) return;
      window.__aprecisAndroidBridgeInstalled = true;
      function send(name, body) {
        try {
          var payload = JSON.stringify(body || {});
          if (window.AndroidAprecis && typeof window.AndroidAprecis[name] === 'function') {
            window.AndroidAprecis[name](payload);
          }
        } catch (e) {
          if (window.AndroidAprecis && window.AndroidAprecis.log) {
            window.AndroidAprecis.log(String(e));
          }
        }
      }
      window.webkit = window.webkit || {};
      window.webkit.messageHandlers = window.webkit.messageHandlers || {};
      ["close","finish","markDone","haptic","openOriginal","select","success","interaction","progress"].forEach(function(name) {
        window.webkit.messageHandlers[name] = {
          postMessage: function(body) { send(name, body); }
        };
      });
      if (window.Aprecis) {
        window.Aprecis._s = function(name, body) { send(name, body); };
      }
      var meta=document.querySelector('meta[name=viewport]');
      if(!meta){meta=document.createElement('meta');meta.name='viewport';document.head.appendChild(meta);}
      meta.content='width=device-width, initial-scale=1, viewport-fit=cover';
      if(!document.getElementById('aprecis-android-safe-area')){
        var s=document.createElement('style');
        s.id='aprecis-android-safe-area';
        s.textContent='html,body{min-height:100dvh;height:100%;}'
          + '.advance{padding-bottom:calc(26px + env(safe-area-inset-bottom,0px))!important;}'
          + '.chrome{padding-top:calc(8px + env(safe-area-inset-top,0px))!important;}';
        document.head.appendChild(s);
      }
      function reportProgress(){
        try{
          var frac=null;
          var count=document.getElementById('count');
          if(count){
            var m=count.textContent.match(/(\d+)\s*\/\s*(\d+)/);
            if(m){var n=+m[1],total=+m[2];frac=total>1?(n-1)/(total-1):(n>=1?1:0);}
          }
          if(frac===null){
            var all=document.querySelectorAll('.rail .seg, .progress .dot');
            if(all.length>1){
              var on=document.querySelectorAll('.rail .seg.on, .progress .dot.on').length;
              frac=(on-1)/(all.length-1);
            }
          }
          if(frac===null)return;
          frac=Math.max(0,Math.min(1,frac));
          window.webkit.messageHandlers.progress.postMessage({progress:frac});
        }catch(e){}
      }
      var count=document.getElementById('count');
      if(count)new MutationObserver(reportProgress).observe(count,{childList:true,characterData:true,subtree:true});
      var rail=document.querySelector('.rail')||document.querySelector('.progress');
      if(rail)new MutationObserver(reportProgress).observe(rail,{attributes:true,subtree:true,attributeFilter:['class']});
      reportProgress();
    })();
""".trimIndent()

private fun openUrl(context: Context, url: String): Boolean {
    if (!url.startsWith("http")) return false
    return try {
        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        true
    } catch (_: ActivityNotFoundException) {
        false
    }
}

private fun sameBundleUrl(original: String, target: String): Boolean {
    val originalUri = Uri.parse(original.substringBefore("?"))
    val targetUri = Uri.parse(target.substringBefore("?"))
    return originalUri.scheme == targetUri.scheme &&
        originalUri.host == targetUri.host &&
        originalUri.path == targetUri.path
}

private fun vibrate(context: Context, body: String?) {
    val duration = if (body.orEmpty().contains("success")) 35L else 18L
    val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
        manager.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE))
    } else {
        @Suppress("DEPRECATION")
        vibrator.vibrate(duration)
    }
}
