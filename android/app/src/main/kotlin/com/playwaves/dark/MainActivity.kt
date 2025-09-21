package com.playwaves.dark

import android.content.ComponentName
import android.content.pm.PackageManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "icon_changer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "changeIcon") {
                val alias = call.argument<String>("alias")
                changeIcon(alias)
                result.success(null)
            }
        }
    }

    private fun changeIcon(alias: String?) {
        val pm = applicationContext.packageManager
        val main = ComponentName(applicationContext, "com.playwaves.dark.MainActivity")
        val alias1 = ComponentName(applicationContext, "com.playwaves.dark.IconAlias1")
        val alias2 = ComponentName(applicationContext, "com.playwaves.dark.IconAlias2")
        val alias3 = ComponentName(applicationContext, "com.playwaves.dark.IconAlias3")
        // Disable all
        pm.setComponentEnabledSetting(main, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        pm.setComponentEnabledSetting(alias1, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        pm.setComponentEnabledSetting(alias2, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        pm.setComponentEnabledSetting(alias3, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        // Enable selected
        when(alias) {
            "IconAlias1" -> pm.setComponentEnabledSetting(alias1, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
            "IconAlias2" -> pm.setComponentEnabledSetting(alias2, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
            "IconAlias3" -> pm.setComponentEnabledSetting(alias3, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
            else -> pm.setComponentEnabledSetting(main, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
        }
        // Forcefully exit the app after icon change
        System.exit(0)
    }
}
