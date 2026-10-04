package com.eqron.eqron

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.eqron/equalizer"
    private val SPECTRUM_CHANNEL = "com.eqron/spectrum"
    private val TAG = "EQron:MainActivity"
    private val REQUEST_RECORD_AUDIO = 2

    private val engine = EqualizerEngine.instance

    private var spectrumSink: EventChannel.EventSink? = null
    private val spectrum = SpectrumAnalyzer { bands -> spectrumSink?.success(bands.toList()) }
    private var pendingSpectrumResult: MethodChannel.Result? = null

    private fun startSpectrum(): String {
        // Never attach to the global session 0: an effect there forces the whole
        // output through the effect chain and can make audio stutter on some
        // devices. Only capture a player's own session, newest first.
        val sessions = engine.activeSessionIds().filter { it != 0 }.reversed()
        if (sessions.isEmpty()) return "no_session"
        return if (spectrum.start(sessions)) "started" else "unavailable"
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_RECORD_AUDIO) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingSpectrumResult?.success(if (granted) startSpectrum() else "permission_denied")
            pendingSpectrumResult = null
        }
    }

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

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SPECTRUM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    spectrumSink = events
                }

                override fun onCancel(arguments: Any?) {
                    spectrumSink = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startSpectrum" -> {
                    if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                        result.success(startSpectrum())
                    } else {
                        pendingSpectrumResult?.success("permission_denied")
                        pendingSpectrumResult = result
                        requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_RECORD_AUDIO)
                    }
                }
                "stopSpectrum" -> {
                    spectrum.stop()
                    result.success(null)
                }
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

    override fun onDestroy() {
        // Effects stay alive in EqualizerService; only the UI-driven spectrum stops.
        spectrum.stop()
        super.onDestroy()
    }
}
