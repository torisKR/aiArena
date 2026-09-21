package com.toris.tokenfront.tokenfront

import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import androidx.credentials.*
import androidx.credentials.exceptions.*
import com.google.android.libraries.identity.googleid.GetSignInWithGoogleOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: MethodChannel.Result? = null
    private var signal: CancellationSignal? = null
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executor { handler.post(it) }
    private val deadline = Runnable { finishError("timeout") }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tokenfront/google_identity")
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "signIn" -> {
                    if (pending != null) { result.error("busy", null, null); return@setMethodCallHandler }
                    val clientId = call.argument<String>("serverClientId")
                    val nonce = call.argument<String>("nonce")
                    if (clientId == null || !Regex("^[0-9]+-[a-zA-Z0-9_-]+\\.apps\\.googleusercontent\\.com$").matches(clientId) ||
                        nonce == null || !Regex("^[A-Za-z0-9_-]{43}$").matches(nonce)) {
                        result.error("configuration", null, null); return@setMethodCallHandler
                    }
                    begin(result)
                    val operation = signal
                    try {
                        val option = GetSignInWithGoogleOption.Builder(clientId).setNonce(nonce).build()
                        val request = GetCredentialRequest.Builder().addCredentialOption(option).build()
                        CredentialManager.create(this).getCredentialAsync(this, request, operation, executor,
                            object : CredentialManagerCallback<GetCredentialResponse, GetCredentialException> {
                                override fun onResult(response: GetCredentialResponse) {
                                    if (signal !== operation) return
                                    try {
                                        val credential = response.credential
                                        if (credential !is CustomCredential || credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                                            finishError("invalid_credential"); return
                                        }
                                        val token = GoogleIdTokenCredential.createFrom(credential.data).idToken
                                        if (token.isBlank() || token.length > 16384) { finishError("invalid_credential"); return }
                                        finishSuccess(token)
                                    } catch (_: Exception) { finishError("invalid_credential") }
                                }
                                override fun onError(e: GetCredentialException) {
                                    if (signal !== operation) return
                                    finishError(when (e) {
                                        is GetCredentialCancellationException -> "canceled"
                                        is NoCredentialException -> "no_credential"
                                        is GetCredentialInterruptedException -> "interrupted"
                                        is GetCredentialUnsupportedException -> "unsupported"
                                        is GetCredentialProviderConfigurationException -> "configuration"
                                        else -> "provider_error"
                                    })
                                }
                            })
                    } catch (_: Exception) { finishError("provider_error") }
                }
                "clearCredentialState" -> {
                    finishError("canceled")
                    begin(result)
                    val operation = signal
                    try {
                        CredentialManager.create(this).clearCredentialStateAsync(ClearCredentialStateRequest(), operation, executor,
                            object : CredentialManagerCallback<Void?, ClearCredentialException> {
                                override fun onResult(response: Void?) { if (signal === operation) finishSuccess(null) }
                                override fun onError(e: ClearCredentialException) { if (signal === operation) finishError("clear_failed") }
                            })
                    } catch (_: Exception) { finishError("clear_failed") }
                }
                else -> result.notImplemented()
            }
        }
    }
    private fun begin(result: MethodChannel.Result) {
        pending = result
        signal = CancellationSignal()
        handler.postDelayed(deadline, 110000)
    }
    private fun finishSuccess(value: String?) {
        val result = pending
        pending = null
        signal = null
        handler.removeCallbacks(deadline)
        result?.success(value)
    }
    private fun finishError(code: String) {
        val result = pending
        val cancellation = signal
        pending = null
        signal = null
        handler.removeCallbacks(deadline)
        cancellation?.cancel()
        result?.error(code, null, null)
    }
    override fun onDestroy() {
        finishError("interrupted")
        channel?.setMethodCallHandler(null)
        channel = null
        super.onDestroy()
    }
}
