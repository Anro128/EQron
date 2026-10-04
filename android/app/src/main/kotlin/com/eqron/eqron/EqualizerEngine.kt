package com.eqron.eqron

import android.content.Context
import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
import org.json.JSONObject
import kotlin.math.abs

/**
 * Core engine to manage system-wide audio equalization and Dolby-style enhancements.
 */
class EqualizerEngine {

    private val TAG = "EQron"
    private val equalizers = ConcurrentHashMap<Int, Equalizer>()
    private val bassBoosts = ConcurrentHashMap<Int, BassBoost>()
    private val virtualizers = ConcurrentHashMap<Int, Virtualizer>()
    private val loudnessEnhancers = ConcurrentHashMap<Int, LoudnessEnhancer>()
    private val appliedLevels = ConcurrentHashMap<Int, ShortArray>()

    private var isEnabled = false
    private var currentBandCount = 5
    private var bassBoostStrength: Short = 0 // 0 to 1000
    private var virtualizerStrength: Short = 0 // 0 to 1000
    private var loudnessGain: Int = 0 // 0 to 1000 mB
    
    // Store requested custom levels before they are interpolated and applied
    private var customBandLevels = IntArray(15) { 0 }
    
    @Volatile
    private var stateLoaded = false

    companion object {
        /** Process-wide engine, shared by the activity, the receiver and the foreground service. */
        val instance: EqualizerEngine by lazy { EqualizerEngine() }

        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val APP_STATE_KEY = "flutter.app_state"

        val FREQ_MAP_3 = intArrayOf(60, 1000, 14000)
        val FREQ_MAP_5 = intArrayOf(60, 230, 910, 3600, 14000)
        val FREQ_MAP_7 = intArrayOf(60, 170, 400, 1000, 2400, 6000, 14000)
        val FREQ_MAP_10 = intArrayOf(31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000)
        val FREQ_MAP_15 = intArrayOf(25, 40, 63, 100, 160, 250, 400, 630, 1000, 1600, 2500, 4000, 6300, 10000, 16000)
    }

    fun isEffectEnabled(): Boolean = isEnabled

    /**
     * Restores the last state saved by the Flutter UI so the engine works
     * even when the app UI is not running. Runs once per process.
     */
    @Synchronized
    fun ensureStateLoaded(context: Context) {
        if (stateLoaded) return
        stateLoaded = true
        try {
            val prefs = context.applicationContext.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val json = prefs.getString(APP_STATE_KEY, null) ?: return
            val obj = JSONObject(json)
            val bandCount = obj.optInt("bandCount", 5)
            val gains = obj.optJSONArray("currentGains")
            setBandCount(bandCount)
            applyBandLevels(IntArray(bandCount) { gains?.optDouble(it, 0.0)?.toInt() ?: 0 })
            setBassBoost(obj.optInt("bassBoost", 0))
            setVirtualizer(obj.optInt("virtualizer", 0))
            setLoudness(obj.optInt("loudness", 0))
            setEnabled(obj.optBoolean("isEnabled", false))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restore saved state", e)
        }
    }

    /**
     * Initializes Audio Effects for the given session ID.
     */
    @Synchronized
    fun init(sessionId: Int) {
        try {
            if (!equalizers.containsKey(sessionId)) {
                val eq = Equalizer(0, sessionId)
                equalizers[sessionId] = eq
                applyAllCustomBandsToNative()
                Log.d(TAG, "Initialized Equalizer for session: $sessionId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Equalizer for session $sessionId", e)
        }

        try {
            if (!bassBoosts.containsKey(sessionId)) {
                val bb = BassBoost(0, sessionId)
                if (bb.strengthSupported) {
                    bb.setStrength(bassBoostStrength)
                }
                bassBoosts[sessionId] = bb
                Log.d(TAG, "Initialized BassBoost for session: $sessionId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize BassBoost for session $sessionId", e)
        }

        try {
            if (!virtualizers.containsKey(sessionId)) {
                val virt = Virtualizer(0, sessionId)
                if (virt.strengthSupported) {
                    virt.setStrength(virtualizerStrength)
                }
                virtualizers[sessionId] = virt
                Log.d(TAG, "Initialized Virtualizer for session: $sessionId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Virtualizer for session $sessionId", e)
        }

        try {
            if (!loudnessEnhancers.containsKey(sessionId)) {
                val le = LoudnessEnhancer(sessionId)
                le.setTargetGain(loudnessGain)
                loudnessEnhancers[sessionId] = le
                Log.d(TAG, "Initialized LoudnessEnhancer for session: $sessionId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize LoudnessEnhancer for session $sessionId", e)
        }

        applyEnabledState()
    }

    /**
     * Enable or disable audio effects globally.
     */
    @Synchronized
    fun setEnabled(enabled: Boolean) {
        isEnabled = enabled
        applyEnabledState()
    }

    /**
     * Session 0 is the global mix. If a player has its own session, the global
     * effects are switched off so the same audio isn't equalized twice.
     */
    private fun hasAppSession(): Boolean = equalizers.keys.any { it != 0 }

    private fun shouldRun(sessionId: Int): Boolean =
        isEnabled && !(sessionId == 0 && hasAppSession())

    /**
     * Applies the on/off state per effect. Bass boost, virtualizer and loudness
     * only run while their strength is above zero, since an enabled effect at
     * zero strength can still color the signal on some chipsets.
     */
    @Synchronized
    private fun applyEnabledState() {
        equalizers.forEach { (id, e) -> try { e.enabled = shouldRun(id) } catch (ex: Exception) {} }
        bassBoosts.forEach { (id, e) -> try { e.enabled = shouldRun(id) && bassBoostStrength > 0 } catch (ex: Exception) {} }
        virtualizers.forEach { (id, e) -> try { e.enabled = shouldRun(id) && virtualizerStrength > 0 } catch (ex: Exception) {} }
        loudnessEnhancers.forEach { (id, e) -> try { e.enabled = shouldRun(id) && loudnessGain > 0 } catch (ex: Exception) {} }
    }

    /**
     * Sets Bass Boost strength (0 to 1000).
     */
    fun setBassBoost(strength: Int) {
        bassBoostStrength = strength.coerceIn(0, 1000).toShort()
        bassBoosts.values.forEach {
            try {
                if (it.strengthSupported) {
                    it.setStrength(bassBoostStrength)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error setting BassBoost strength", e)
            }
        }
        applyEnabledState()
    }

    /**
     * Sets 3D Virtualizer strength (0 to 1000).
     */
    fun setVirtualizer(strength: Int) {
        virtualizerStrength = strength.coerceIn(0, 1000).toShort()
        virtualizers.values.forEach {
            try {
                if (it.strengthSupported) {
                    it.setStrength(virtualizerStrength)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error setting Virtualizer strength", e)
            }
        }
        applyEnabledState()
    }

    /**
     * Sets Loudness / Sound Clarity target gain (0 to 1000 mB).
     */
    fun setLoudness(gain: Int) {
        loudnessGain = gain.coerceIn(0, 1000)
        loudnessEnhancers.values.forEach {
            try {
                it.setTargetGain(loudnessGain)
            } catch (e: Exception) {
                Log.e(TAG, "Error setting Loudness gain", e)
            }
        }
        applyEnabledState()
    }

    /**
     * Get level range [min, max] in millibels.
     */
    fun getBandLevelRange(): ShortArray? {
        return equalizers.values.firstOrNull()?.bandLevelRange ?: shortArrayOf(-1500, 1500)
    }

    /**
     * Returns the number of bands supported by the native Equalizer.
     */
    fun getNumberOfBands(): Short {
        return equalizers.values.firstOrNull()?.numberOfBands ?: 5
    }

    /**
     * Gets the center frequencies of the currently configured custom band count.
     */
    fun getCenterFrequencies(): IntArray {
        return when (currentBandCount) {
            3 -> FREQ_MAP_3
            5 -> FREQ_MAP_5
            7 -> FREQ_MAP_7
            10 -> FREQ_MAP_10
            15 -> FREQ_MAP_15
            else -> FREQ_MAP_5
        }
    }

    fun setBandCount(count: Int) {
        currentBandCount = count
        customBandLevels = IntArray(count) { 0 }
        rebuildWeightCache()
        applyAllCustomBandsToNative()
    }

    /**
     * Sets the level for a custom band.
     */
    fun setBandLevel(band: Int, level: Int) {
        if (band in 0 until currentBandCount) {
            customBandLevels[band] = level
            applyAllCustomBandsToNative()
        }
    }

    /**
     * Apply an array of custom band levels.
     */
    fun applyBandLevels(levels: IntArray) {
        if (levels.size == currentBandCount) {
            customBandLevels = levels.copyOf()
            applyAllCustomBandsToNative()
        } else {
            Log.e(TAG, "Invalid band levels size: expected $currentBandCount, got ${levels.size}")
        }
    }

    @Volatile
    private var cachedWeights: Array<DoubleArray>? = null
    @Volatile
    private var cachedNativeBands: Int = 0

    private fun rebuildWeightCache() {
        if (equalizers.isEmpty()) return
        try {
            val eq = equalizers.values.first()
            val nativeBands = eq.numberOfBands.toInt()
            if (nativeBands <= 0) return

            val customFreqs = getCenterFrequencies()
            val weights = Array(nativeBands) { DoubleArray(customFreqs.size) }

            for (i in 0 until nativeBands) {
                val nFreq = eq.getCenterFreq(i.toShort()) / 1000.0 // Hz
                if (nFreq <= 0) continue
                val logNFreq = Math.log10(nFreq)
                for (j in customFreqs.indices) {
                    val cFreq = customFreqs[j].toDouble()
                    val logCFreq = Math.log10(cFreq)
                    val logDist = abs(logNFreq - logCFreq)
                    weights[i][j] = 1.0 / (logDist * logDist + 0.05)
                }
            }
            cachedNativeBands = nativeBands
            cachedWeights = weights
        } catch (e: Exception) {
            Log.e(TAG, "Error rebuilding weight cache", e)
        }
    }

    /**
     * Interpolates custom band configuration into the native equalizer bands
     * using smooth pre-calculated log-frequency weighting.
     */
    @Synchronized
    private fun applyAllCustomBandsToNative() {
        if (equalizers.isEmpty()) return

        val eq = equalizers.values.first()
        val nativeBands = eq.numberOfBands.toInt()
        if (nativeBands <= 0) return

        val range = getBandLevelRange() ?: shortArrayOf(-1500, 1500)
        val minLevel = range[0].toInt()
        val maxLevel = range[1].toInt()

        var weights = cachedWeights
        if (weights == null || cachedNativeBands != nativeBands || weights.isEmpty() || weights[0].size != customBandLevels.size) {
            rebuildWeightCache()
            weights = cachedWeights
        }

        val nativeLevels = ShortArray(nativeBands) { 0 }

        if (weights != null && weights.size == nativeBands) {
            for (i in 0 until nativeBands) {
                var totalWeight = 0.0
                var weightedGainSum = 0.0
                val row = weights[i]
                for (j in customBandLevels.indices) {
                    if (j < row.size) {
                        val w = row[j]
                        weightedGainSum += customBandLevels[j] * w
                        totalWeight += w
                    }
                }

                val interpolatedGain = if (totalWeight > 0) (weightedGainSum / totalWeight) else 0.0
                val clampedGain = interpolatedGain.toInt().coerceIn(minLevel, maxLevel)
                nativeLevels[i] = clampedGain.toShort()
            }
        }

        equalizers.forEach { (sessionId, instance) ->
            try {
                // Only touch bands whose level actually changed; rewriting every
                // band on each slider tick causes clicks and extra IPC load.
                val previous = appliedLevels[sessionId]
                for (i in 0 until nativeBands) {
                    if (previous == null || previous.size != nativeBands || previous[i] != nativeLevels[i]) {
                        instance.setBandLevel(i.toShort(), nativeLevels[i])
                    }
                }
                appliedLevels[sessionId] = nativeLevels.copyOf()
            } catch (e: Exception) {
                Log.e(TAG, "Error applying native levels", e)
            }
        }
    }

    /**
     * Releases audio effects for a given session.
     */
    fun releaseSession(sessionId: Int) {
        try {
            equalizers.remove(sessionId)?.release()
            bassBoosts.remove(sessionId)?.release()
            virtualizers.remove(sessionId)?.release()
            loudnessEnhancers.remove(sessionId)?.release()
            appliedLevels.remove(sessionId)
            applyEnabledState()
            Log.d(TAG, "Released audio effects for session: $sessionId")
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing audio effects for session $sessionId", e)
        }
    }

    /**
     * Releases all audio effect instances.
     */
    fun release() {
        equalizers.forEach { (_, eq) -> try { eq.release() } catch (e: Exception) {} }
        bassBoosts.forEach { (_, bb) -> try { bb.release() } catch (e: Exception) {} }
        virtualizers.forEach { (_, virt) -> try { virt.release() } catch (e: Exception) {} }
        loudnessEnhancers.forEach { (_, le) -> try { le.release() } catch (e: Exception) {} }
        
        equalizers.clear()
        bassBoosts.clear()
        virtualizers.clear()
        loudnessEnhancers.clear()
        appliedLevels.clear()
    }
}
