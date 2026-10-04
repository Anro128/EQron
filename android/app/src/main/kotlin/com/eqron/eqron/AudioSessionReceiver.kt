package com.eqron.eqron

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.audiofx.AudioEffect
import android.util.Log

/**
 * BroadcastReceiver to listen for new audio sessions and apply the equalizer to them.
 * Talks to the process-wide engine directly, so it works without the UI running.
 */
class AudioSessionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "EQron:SessionReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val sessionId = intent.getIntExtra(AudioEffect.EXTRA_AUDIO_SESSION, -1)
        val packageName = intent.getStringExtra(AudioEffect.EXTRA_PACKAGE_NAME) ?: "unknown"

        Log.d(TAG, "Received action: $action, sessionId: $sessionId, package: $packageName")

        if (sessionId == -1) return

        val engine = EqualizerEngine.instance
        engine.ensureStateLoaded(context)

        when (action) {
            AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION -> {
                Log.d(TAG, "Audio session opened: $sessionId")
                engine.init(sessionId)
                if (engine.isEffectEnabled()) {
                    EqualizerService.start(context)
                }
            }
            AudioEffect.ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION -> {
                Log.d(TAG, "Audio session closed: $sessionId")
                engine.releaseSession(sessionId)
            }
        }
    }
}
