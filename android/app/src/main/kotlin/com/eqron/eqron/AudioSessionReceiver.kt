package com.eqron.eqron

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.audiofx.AudioEffect
import android.util.Log

/**
 * BroadcastReceiver to listen for new audio sessions and apply the equalizer to them.
 */
class AudioSessionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "EQron:SessionReceiver"
        var onSessionOpen: ((Int, String) -> Unit)? = null
        var onSessionClose: ((Int, String) -> Unit)? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val sessionId = intent.getIntExtra(AudioEffect.EXTRA_AUDIO_SESSION, -1)
        val packageName = intent.getStringExtra(AudioEffect.EXTRA_PACKAGE_NAME) ?: "unknown"

        Log.d(TAG, "Received action: $action, sessionId: $sessionId, package: $packageName")

        if (sessionId == -1) return

        when (action) {
            AudioEffect.ACTION_OPEN_AUDIO_EFFECT_CONTROL_SESSION -> {
                Log.d(TAG, "Audio session opened: $sessionId")
                onSessionOpen?.invoke(sessionId, packageName)
            }
            AudioEffect.ACTION_CLOSE_AUDIO_EFFECT_CONTROL_SESSION -> {
                Log.d(TAG, "Audio session closed: $sessionId")
                onSessionClose?.invoke(sessionId, packageName)
            }
        }
    }
}
