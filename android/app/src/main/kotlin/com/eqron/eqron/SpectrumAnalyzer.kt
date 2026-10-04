package com.eqron.eqron

import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import android.util.Log
import kotlin.math.ceil
import kotlin.math.hypot
import kotlin.math.log10
import kotlin.math.pow
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * Captures the audio output with android.media.audiofx.Visualizer and reduces
 * the FFT to log-spaced bands (50 Hz .. 16 kHz) for the UI.
 * Levels are normalized to 0..1 and are meant for display, not measurement.
 */
class SpectrumAnalyzer(private val onBands: (DoubleArray) -> Unit) {

    companion object {
        private const val TAG = "EQron:Spectrum"
        private const val BAND_COUNT = 28
        private const val MIN_HZ = 50.0
        private const val MAX_HZ = 16000.0
        private const val MAX_DB = 45.0 // 8-bit FFT magnitude tops out around 181
        private const val TILT_TOTAL = 0.22 // highs carry less energy; even out the display

        /** Width ratio between the edges of neighbouring log-spaced bands. */
        private val BAND_RATIO = (MAX_HZ / MIN_HZ).pow(1.0 / BAND_COUNT)
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var visualizer: Visualizer? = null

    private val listener = object : Visualizer.OnDataCaptureListener {
        override fun onWaveFormDataCapture(v: Visualizer?, waveform: ByteArray?, samplingRate: Int) {}

        override fun onFftDataCapture(v: Visualizer?, fft: ByteArray?, samplingRate: Int) {
            if (fft == null) return
            val bands = computeBands(fft, samplingRate)
            mainHandler.post { onBands(bands) }
        }
    }

    /** Tries each session in order; returns true as soon as one can be captured. */
    @Synchronized
    fun start(sessionIds: List<Int>): Boolean {
        stop()
        for (sessionId in sessionIds) {
            try {
                val v = Visualizer(sessionId)
                v.enabled = false
                v.captureSize = Visualizer.getCaptureSizeRange()[1]
                v.setDataCaptureListener(
                    listener,
                    Visualizer.getMaxCaptureRate() / 2,
                    false,
                    true
                )
                v.enabled = true
                visualizer = v
                Log.d(TAG, "Spectrum started on session $sessionId")
                return true
            } catch (e: Exception) {
                Log.w(TAG, "Visualizer unavailable on session $sessionId", e)
            }
        }
        return false
    }

    @Synchronized
    fun stop() {
        visualizer?.let {
            try {
                it.enabled = false
                it.release()
            } catch (e: Exception) {
                Log.w(TAG, "Error stopping visualizer", e)
            }
        }
        visualizer = null
    }

    private fun computeBands(fft: ByteArray, samplingRateMilliHz: Int): DoubleArray {
        val captureSize = fft.size
        val binHz = (samplingRateMilliHz / 1000.0) / captureSize
        val maxBin = captureSize / 2 - 1

        return DoubleArray(BAND_COUNT) { i ->
            val lo = MIN_HZ * BAND_RATIO.pow(i)
            val hi = lo * BAND_RATIO

            var firstBin = ceil(lo / binHz).toInt().coerceAtLeast(1)
            var lastBin = (ceil(hi / binHz).toInt() - 1).coerceAtMost(maxBin)
            if (firstBin > lastBin) {
                // Low bands are narrower than one FFT bin: borrow the nearest bin
                val nearest = (sqrt(lo * hi) / binHz).roundToInt().coerceIn(1, maxBin)
                firstBin = nearest
                lastBin = nearest
            }

            // fft[0] = DC, fft[1] = Nyquist, then (real, imaginary) pairs for bins 1..n/2-1
            var peak = 0.0
            for (k in firstBin..lastBin) {
                val magnitude = hypot(fft[2 * k].toDouble(), fft[2 * k + 1].toDouble())
                if (magnitude > peak) peak = magnitude
            }

            val db = 20.0 * log10(peak + 1.0)
            (db / MAX_DB + TILT_TOTAL * i / (BAND_COUNT - 1)).coerceIn(0.0, 1.0)
        }
    }
}
