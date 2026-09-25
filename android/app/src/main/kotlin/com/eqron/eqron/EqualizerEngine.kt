package com.eqron.eqron

import android.media.audiofx.BassBoost
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.media.audiofx.Virtualizer
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
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
    
    private var isEnabled = false
    private var currentBandCount = 5
    private var bassBoostStrength: Short = 0 // 0 to 1000
    private var virtualizerStrength: Short = 0 // 0 to 1000
    private var loudnessGain: Int = 0 // 0 to 1000 mB
    
    // Store requested custom levels before they are interpolated and applied
    private var customBandLevels = IntArray(15) { 0 }
    
    companion object {
        val FREQ_MAP_3 = intArrayOf(60, 1000, 14000)
        val FREQ_MAP_5 = intArrayOf(60, 230, 910, 3600, 14000)
        val FREQ_MAP_7 = intArrayOf(60, 170, 400, 1000, 2400, 6000, 14000)
        val FREQ_MAP_10 = intArrayOf(31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000)
        val FREQ_MAP_15 = intArrayOf(25, 40, 63, 100, 160, 250, 400, 630, 1000, 1600, 2500, 4000, 6300, 10000, 16000)
    }

    /**
     * Initializes Audio Effects for the given session ID.
     */
    fun init(sessionId: Int) {
        try {
            if (!equalizers.containsKey(sessionId)) {
                val eq = Equalizer(0, sessionId)
                eq.enabled = isEnabled
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
                bb.enabled = isEnabled
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
                virt.enabled = isEnabled
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
                le.enabled = isEnabled
                le.setTargetGain(loudnessGain)
                loudnessEnhancers[sessionId] = le
                Log.d(TAG, "Initialized LoudnessEnhancer for session: $sessionId")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize LoudnessEnhancer for session $sessionId", e)
        }
    }

    /**
     * Enable or disable audio effects globally.
     */
    fun setEnabled(enabled: Boolean) {
        isEnabled = enabled
        equalizers.values.forEach { try { it.enabled = enabled } catch (e: Exception) {} }
        bassBoosts.values.forEach { try { it.enabled = enabled } catch (e: Exception) {} }
        virtualizers.values.forEach { try { it.enabled = enabled } catch (e: Exception) {} }
        loudnessEnhancers.values.forEach { try { it.enabled = enabled } catch (e: Exception) {} }
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

        equalizers.values.forEach { instance ->
            try {
                for (i in 0 until nativeBands) {
                    instance.setBandLevel(i.toShort(), nativeLevels[i])
                }
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
    }
}
