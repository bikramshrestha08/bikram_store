package com.leotech.bwcapp

import android.app.NotificationManager
import android.content.Context
import android.widget.Toast
import androidx.annotation.NonNull
import com.recheng.superpay.callback.OnPayResultListener
import com.recheng.superpay.enums.PayWay
import com.recheng.superpay.pay.ChengPay
import com.recheng.superpay.pay.PayParams
import com.recheng.superpay.utils.LogUtil
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterFragmentActivity() {
    private val SUPAY_CHANNEL = "supay"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val supayMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SUPAY_CHANNEL)
        supayMethodChannel.setMethodCallHandler {
            // Note: this method is invoked on the main thread.
            call, result ->
            if (call.method.equals("onSupayPay")) {
                onSupayPay(call.argument("gateWay")!!, call.argument("payInfo")!!, supayMethodChannel)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun onSupayPay(gateWay: String, payInfo: String, supayMethodChannel: MethodChannel) {
        val payBuilder = PayParams.Builder(this@MainActivity)
        when (gateWay) {
            "WechatPay" -> {
                payBuilder.payWay(PayWay.WechatPay)
                //微信支付包名签名必须和官网一致  请注意!!!
                payBuilder.wechatAppID("wx90dacd7c010a7b77")
            }
            "AliPay" -> payBuilder.payWay(PayWay.AliPay)
        }
        val payParams = payBuilder.payInfo(payInfo).build()
        ChengPay.newInstance(payParams).doPay(object : OnPayResultListener {
            override fun onPaySuccess(payWay: PayWay) {
                invokeFlutterMethod(supayMethodChannel, "paySuccess", "支付成功 $payWay")
                LogUtil.i("支付成功 $payWay")
//                Toast.makeText(this@MainActivity, "支付成功 $payWay", Toast.LENGTH_LONG).show()
            }

            override fun onPayCancel(payWay: PayWay) {
                invokeFlutterMethod(supayMethodChannel, "payCancel", "支付失败 $payWay")
                LogUtil.i("支付取消 $payWay")
//                Toast.makeText(this@MainActivity, "支付取消 $payWay", Toast.LENGTH_LONG).show()
            }

            override fun onPayFailure(payWay: PayWay, errCode: Int) {
                invokeFlutterMethod(supayMethodChannel, "payFailure", "支付失败 $payWay$errCode")
                LogUtil.i("支付失败 $payWay$errCode")
//                Toast.makeText(this@MainActivity, "支付失败 $payWay$errCode", Toast.LENGTH_LONG).show()
            }
        })
    }
    private fun invokeFlutterMethod(supayMethodChannel: MethodChannel, flutterMethod: String, message: String) {
        supayMethodChannel.invokeMethod(flutterMethod, message, object : MethodChannel.Result {
                override fun success(o: Any?) {
//                    Toast.makeText(this@MainActivity, o.toString(), Toast.LENGTH_LONG).show()
                }
                override fun error(s: String, s1: String?, o: Any?) {}
                override fun notImplemented() {}
            })
    }

    override fun onResume() {
        super.onResume()

        // Removing All Notifications
        cancelAllNotifications()
    }

    private fun cancelAllNotifications() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancelAll()
    }

}