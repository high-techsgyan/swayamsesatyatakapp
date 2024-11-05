// VideoPlayerActivity.kt
package com.swayamsesatyatak.achintya

import android.net.Uri
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.ui.PlayerView

class VideoPlayerActivity : AppCompatActivity() {
    private lateinit var player: ExoPlayer
    private lateinit var playerView: PlayerView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_video_player)

        playerView = findViewById(R.id.player_view)

        // Get videoId from the intent
        val videoId = intent.getStringExtra("VIDEO_ID")
        val videoUrl = "https://www.youtube.com/watch?v=$videoId" // Construct YouTube URL

        setupPlayer(videoUrl)
    }

    private fun setupPlayer(videoUrl: String?) {
        player = ExoPlayer.Builder(this).build()
        playerView.player = player

        // Convert YouTube URL to a direct stream link if needed or use a library to extract the direct URL
        val mediaItem = MediaItem.fromUri(Uri.parse(videoUrl))
        player.setMediaItem(mediaItem)
        player.prepare()
        player.play()
    }

    override fun onStop() {
        super.onStop()
        player.release()
    }
}
