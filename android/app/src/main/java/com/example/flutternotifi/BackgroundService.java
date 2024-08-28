package com.example.flutternotifi;

import android.annotation.TargetApi;
import android.app.job.JobParameters;
import android.app.job.JobService;
import android.content.Intent;
import android.media.MediaPlayer;
import android.os.Build;
import android.util.Log;

@TargetApi(Build.VERSION_CODES.LOLLIPOP)
public class BackgroundService extends JobService {

    private static final String TAG = "BackgroundService";
    private MediaPlayer mediaPlayer;

    @Override
    public boolean onStartJob(JobParameters params) {
        Log.d(TAG, "Job started");

        // Initialize and start playing the song
        mediaPlayer = MediaPlayer.create(this, R.raw.song);
        mediaPlayer.setLooping(false);
        mediaPlayer.start();

        return true;
    }

    @Override
    public boolean onStopJob(JobParameters params) {
        Log.d(TAG, "Job stopped");

        if (mediaPlayer != null) {
            if (mediaPlayer.isPlaying()) {
                mediaPlayer.stop();
            }
            mediaPlayer.release();
            mediaPlayer = null;
        }

        return false;
    }
}
