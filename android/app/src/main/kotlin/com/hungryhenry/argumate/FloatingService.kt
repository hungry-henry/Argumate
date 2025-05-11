package com.hungryhenry.argumate

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.*
import android.widget.TextView
import android.widget.Toast

class FloatingService : Service() {
    companion object {
        const val SCREENSHOT_REQUEST_CODE = 2001
    }

    private lateinit var windowManager: WindowManager
    private lateinit var params: WindowManager.LayoutParams
    private var floatingView: View? = null
    private var projectionManager: MediaProjectionManager? = null

    override fun onCreate() {
        super.onCreate()
        projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        floatingView = LayoutInflater.from(this)
            .inflate(R.layout.floating_window, null)

        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 100; y = 300
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        windowManager.addView(floatingView, params)

        // 拖拽支持（略，同上文）
        setupDrag(floatingView!!)

        // 按钮绑定
        floatingView!!.findViewById<ImageButton>(R.id.btn_close)
            .setOnClickListener { stopSelf() }

        floatingView!!.findViewById<ImageButton>(R.id.btn_screenshot)
            .setOnClickListener { requestScreenshotPermission() }
    }

    private fun requestScreenshotPermission() {
        // 1. 启动透明 Activity 用于申请截屏权限
        val intent = Intent(this, ScreenshotPermissionActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
        // Service 保持悬浮窗，Activity 获取完 result 后会回调并执行截屏
    }

    override fun onDestroy() {
        super.onDestroy()
        floatingView?.let { windowManager.removeView(it) }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
