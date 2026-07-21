package kr.hehehe.hehe

import android.content.pm.ApplicationInfo
import com.navercorp.nid.NidOAuth
import com.navercorp.nid.core.data.datastore.NidOAuthInitializingCallback
import com.navercorp.nid.oauth.util.NidOAuthCallback
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val NAVER_AUTH_CHANNEL = "kr.hehehe.hehe/naver_auth"
    }

    private var isNaverInitialized = false
    private var naverLoginResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NAVER_AUTH_CHANNEL,
        ).setMethodCallHandler(::handleNaverAuthCall)
    }

    private fun handleNaverAuthCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initializeNaver(call, result)
            "login" -> loginWithNaver(result)
            else -> result.notImplemented()
        }
    }

    private fun initializeNaver(call: MethodCall, result: MethodChannel.Result) {
        val clientId = call.argument<String>("clientId")
        val clientSecret = call.argument<String>("clientSecret")
        val clientName = call.argument<String>("clientName")
        if (clientId.isNullOrBlank() || clientSecret.isNullOrBlank() || clientName.isNullOrBlank()) {
            result.error("missing_configuration", "Naver OAuth configuration is missing.", null)
            return
        }

        val isDebuggable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        NidOAuth.setLogEnabled(isDebuggable)
        NidOAuth.initialize(
            applicationContext,
            clientId,
            clientSecret,
            clientName,
            object : NidOAuthInitializingCallback {
                override fun onSuccess() {
                    isNaverInitialized = true
                    result.success(true)
                }

                override fun onFailure(e: Exception) {
                    isNaverInitialized = false
                    result.error("initialize_failed", e.javaClass.simpleName, null)
                }
            },
        )
    }

    private fun loginWithNaver(result: MethodChannel.Result) {
        if (!isNaverInitialized) {
            result.error("not_initialized", "Naver OAuth SDK is not initialized.", null)
            return
        }
        if (naverLoginResult != null) {
            result.error("login_in_progress", "Naver login is already in progress.", null)
            return
        }

        naverLoginResult = result
        NidOAuth.requestLogin(
            this,
            object : NidOAuthCallback {
                override fun onSuccess() {
                    val accessToken = NidOAuth.getAccessToken()
                    if (accessToken.isNullOrBlank()) {
                        finishNaverLogin(
                            mapOf("errorCode" to "empty_access_token"),
                        )
                        return
                    }
                    finishNaverLogin(mapOf("accessToken" to accessToken))
                }

                override fun onFailure(errorCode: String, errorDesc: String) {
                    finishNaverLogin(
                        mapOf(
                            "errorCode" to errorCode,
                            "errorMessage" to errorDesc,
                            "cancelled" to isUserCancellation(errorCode, errorDesc),
                        ),
                    )
                }
            },
        )
    }

    private fun finishNaverLogin(payload: Map<String, Any>) {
        val pendingResult = naverLoginResult ?: return
        naverLoginResult = null
        pendingResult.success(payload)
    }

    private fun isUserCancellation(errorCode: String, errorDesc: String): Boolean {
        return errorCode.equals("user_cancel", ignoreCase = true) ||
            errorDesc.contains("cancel", ignoreCase = true)
    }
}
