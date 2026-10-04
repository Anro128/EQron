package com.eqron.eqron

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.eqron/equalizer"
    private val TAG = "EQron:MainActivity"
    
    private val engine = EqualizerEngine.instance

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    engine.ensureStateLoaded(applicationContext)
                    engine.init(0)
                    result.success(null)
                }
                "setEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    engine.setEnabled(enabled)
                    if (enabled) {
                        engine.init(0)
                        EqualizerService.start(applicationContext)
                    } else {
                        EqualizerService.stop(applicationContext)
                    }
                    result.success(null)
                }
                "setBandLevel" -> {
                    val band = call.argument<Int>("band")
                    val level = call.argument<Int>("level")
                    if (band != null && level != null) {
                        engine.setBandLevel(band, level)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Band or level is null", null)
                    }
                }
                "setBandLevels" -> {
                    val levels = call.argument<List<Int>>("levels")
                    if (levels != null) {
                        engine.applyBandLevels(levels.toIntArray())
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Levels list is null", null)
                    }
                }
                "setBandCount" -> {
                    val count = call.argument<Int>("count")
                    if (count != null) {
                        engine.setBandCount(count)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Count is null", null)
                    }
                }
                "getBandLevelRange" -> {
                    val range = engine.getBandLevelRange()
                    if (range != null && range.size == 2) {
                        result.success(listOf(range[0].toInt(), range[1].toInt()))
                    } else {
                        result.success(listOf(-1500, 1500))
                    }
                }
                "getNumberOfBands" -> {
                    result.success(engine.getNumberOfBands().toInt())
                }
                "getCenterFrequencies" -> {
                    val freqs = engine.getCenterFrequencies().toList()
                    result.success(freqs)
                }
                "getPresetNames" -> {
                    // To be implemented: Get native preset names
                    result.success(emptyList<String>())
                }
                "setPreset" -> {
                    // To be implemented: apply native preset
                    result.success(null)
                }
                "setBassBoost" -> {
                    val strength = call.argument<Int>("strength") ?: 0
                    engine.setBassBoost(strength)
                    result.success(null)
                }
                "setVirtualizer" -> {
                    val strength = call.argument<Int>("strength") ?: 0
                    engine.setVirtualizer(strength)
                    result.success(null)
                }
                "setLoudness" -> {
                    val gain = call.argument<Int>("gain") ?: 0
                    engine.setLoudness(gain)
                    result.success(null)
                }
                "release" -> {
                    engine.release()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
