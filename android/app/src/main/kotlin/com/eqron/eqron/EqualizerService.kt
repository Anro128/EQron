package com.eqron.eqron

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * Foreground service that keeps the process alive so audio effects stay
 * attached after the UI is closed.
 */
class EqualizerService : Service() {

    companion object {
        private const val TAG = "EQron:Service"
        private const val CHANNEL_ID = "eqron_equalizer"
        private const val NOTIFICATION_ID = 1
        private const val ACTION_REPOST = "com.eqron.eqron.action.REPOST_NOTIFICATION"

        fun start(context: Context) {
            try {
                context.startForegroundService(Intent(context, EqualizerService::class.java))
            } catch (e: Exception) {
                Log.e(TAG, "Unable to start foreground service", e)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, EqualizerService::class.java))
        }
    }

    override fun onCreate() {
        super.onCreate()
        val engine = EqualizerEngine.instance
        engine.ensureStateLoaded(this)
        engine.init(0)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Also reached when the user swipes the notification away on Android 14+,
        // where ongoing foreground notifications became dismissible: post it again.
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_STICKY
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "EQron Equalizer", NotificationManager.IMPORTANCE_LOW)
        )

        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Fires when the notification is dismissed; brings it right back
        val repost = PendingIntent.getService(
            this,
            1,
            Intent(this, EqualizerService::class.java).setAction(ACTION_REPOST),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher)
            .setContentTitle("EQron aktif")
            .setContentText("Equalizer sedang berjalan")
            .setContentIntent(openApp)
            .setDeleteIntent(repost)
            .setOngoing(true)
            .setAutoCancel(false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }

        return builder.build()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
