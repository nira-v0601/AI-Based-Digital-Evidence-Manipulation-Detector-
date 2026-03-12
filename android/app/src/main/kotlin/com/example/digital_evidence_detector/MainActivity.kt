package com.example.digital_evidence_detector

import android.Manifest
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Bundle
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.KeyStore
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import javax.crypto.KeyGenerator
import javax.crypto.Mac

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.evidence.detector/secure_capture"
    private var pendingResult: MethodChannel.Result? = null
    
    // Audio recording properties
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingThread: Thread? = null
    private var rawAudioFile: File? = null
    private val sampleRate = 44100
    private val channelConfig = AudioFormat.CHANNEL_IN_MONO
    private val audioFormat = AudioFormat.ENCODING_PCM_16BIT

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "captureSecureImage" -> {
                    pendingResult = result
                    checkPermissionsAndCaptureMode("image")
                }
                "startSecureAudio" -> {
                    pendingResult = result
                    checkPermissionsAndCaptureMode("audio")
                }
                "stopSecureAudio" -> {
                    pendingResult = result
                    stopAudioCapture()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkPermissionsAndCaptureMode(mode: String) {
        val permissionsNeeded = mutableListOf<String>()
        if (mode == "image" && ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            permissionsNeeded.add(Manifest.permission.CAMERA)
        }
        if (mode == "audio" && ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            permissionsNeeded.add(Manifest.permission.RECORD_AUDIO)
        }

        if (permissionsNeeded.isNotEmpty()) {
            val reqCode = if (mode == "image") 101 else 102
            ActivityCompat.requestPermissions(this, permissionsNeeded.toTypedArray(), reqCode)
        } else {
            if (mode == "image") startCameraCapture()
            if (mode == "audio") startAudioCapture()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        if (allGranted) {
            if (requestCode == 101) startCameraCapture()
            if (requestCode == 102) startAudioCapture()
        } else {
            pendingResult?.error("PERMISSION_DENIED", "Required permissions were not granted.", null)
            pendingResult = null
        }
    }

    // --- Image Capture Implementation ---
    private fun startCameraCapture() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            val imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY)
                .build()

            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            try {
                cameraProvider.unbindAll()
                cameraProvider.bindToLifecycle(this, cameraSelector, imageCapture)

                imageCapture.takePicture(ContextCompat.getMainExecutor(this), object : ImageCapture.OnImageCapturedCallback() {
                    override fun onCaptureSuccess(image: ImageProxy) {
                        processAndSaveImage(image)
                    }

                    override fun onError(exception: ImageCaptureException) {
                        pendingResult?.error("CAPTURE_FAILED", exception.message, null)
                        pendingResult = null
                        cameraProvider.unbindAll()
                    }
                })
            } catch (exc: Exception) {
                pendingResult?.error("CAMERA_ERROR", exc.message, null)
                pendingResult = null
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun processAndSaveImage(image: ImageProxy) {
        try {
            val buffer = image.planes[0].buffer
            val bytes = ByteArray(buffer.remaining())
            buffer.get(bytes)
            
            // Use maximum quality parameters, transform to Bitmap, re-save as 100% PNG (Lossless)
            val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            
            val outputDir = File(cacheDir, "secure_evidence")
            if (!outputDir.exists()) outputDir.mkdirs()
            
            val timestamp = Date()
            val isoTimestamp = getIsoTimestamp(timestamp)
            
            val timestampFormat = SimpleDateFormat("yyyyMMdd_HHmmssSSS", Locale.US)
            timestampFormat.timeZone = TimeZone.getTimeZone("UTC")
            val file = File(outputDir, "evidence_${timestampFormat.format(timestamp)}.png")
            
            val out = FileOutputStream(file)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            out.flush()
            out.close()
            
            image.close()

            // Generate Keystore SHA-256 HMAC Hash 
            val secureHash = generateSecureHash(file)

            val response = mapOf(
                "filePath" to file.absolutePath,
                "timestamp" to isoTimestamp,
                "secureHash" to secureHash
            )
            
            pendingResult?.success(response)
            pendingResult = null

            val cameraProvider = ProcessCameraProvider.getInstance(this@MainActivity).get()
            cameraProvider.unbindAll()
        } catch (e: Exception) {
            image.close()
            pendingResult?.error("SAVE_FAILED", e.message, null)
            pendingResult = null
        }
    }

    // --- Audio Capture Implementation ---
    private fun startAudioCapture() {
        if (isRecording) {
            pendingResult?.error("ALREADY_RECORDING", "Audio is already being recorded", null)
            pendingResult = null
            return
        }

        try {
            val bufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                return
            }
            audioRecord = AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, channelConfig, audioFormat, bufferSize)

            val outputDir = File(cacheDir, "secure_evidence")
            if (!outputDir.exists()) outputDir.mkdirs()
            
            val tempTimestampFormat = SimpleDateFormat("yyyyMMdd_HHmmssSSS", Locale.US)
            tempTimestampFormat.timeZone = TimeZone.getTimeZone("UTC")
            val rawFileName = "evidence_raw_${tempTimestampFormat.format(Date())}.raw"
            rawAudioFile = File(outputDir, rawFileName)

            audioRecord?.startRecording()
            isRecording = true
            
            pendingResult?.success(true)
            pendingResult = null

            recordingThread = Thread {
                writeAudioDataToFile(bufferSize)
            }
            recordingThread?.start()
            
        } catch (e: Exception) {
            pendingResult?.error("AUDIO_START_FAILED", e.message, null)
            pendingResult = null
        }
    }

    private fun writeAudioDataToFile(bufferSize: Int) {
        val data = ByteArray(bufferSize)
        val os = FileOutputStream(rawAudioFile)

        while (isRecording) {
            val read = audioRecord?.read(data, 0, bufferSize) ?: 0
            if (read > 0) {
                os.write(data, 0, read)
            }
        }
        os.close()
    }

    private fun stopAudioCapture() {
        if (!isRecording) {
            pendingResult?.error("NOT_RECORDING", "No active audio recording found", null)
            pendingResult = null
            return
        }

        isRecording = false
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        recordingThread = null

        val outputDir = File(cacheDir, "secure_evidence")
        val timestamp = Date()
        val isoTimestamp = getIsoTimestamp(timestamp)
        val timestampFormat = SimpleDateFormat("yyyyMMdd_HHmmssSSS", Locale.US)
        timestampFormat.timeZone = TimeZone.getTimeZone("UTC")
        val wavFile = File(outputDir, "evidence_${timestampFormat.format(timestamp)}.wav")

        try {
            copyRawToWavFile(rawAudioFile!!, wavFile)
            rawAudioFile?.delete() // Remove raw temp file

            // Generate Keystore SHA-256 HMAC Hash 
            val secureHash = generateSecureHash(wavFile)

            val response = mapOf(
                "filePath" to wavFile.absolutePath,
                "timestamp" to isoTimestamp,
                "secureHash" to secureHash
            )

            pendingResult?.success(response)
            pendingResult = null
        } catch (e: Exception) {
            pendingResult?.error("AUDIO_STOP_FAILED", e.message, null)
            pendingResult = null
        }
    }

    private fun copyRawToWavFile(rawFile: File, wavFile: File) {
        val rawData = ByteArray(rawFile.length().toInt())
        val isStream = FileInputStream(rawFile)
        isStream.read(rawData)
        isStream.close()

        val os = FileOutputStream(wavFile)
        writeWavHeader(os, rawData.size.toLong())
        os.write(rawData)
        os.close()
    }

    private fun writeWavHeader(out: FileOutputStream, totalAudioLen: Long) {
        val totalDataLen = totalAudioLen + 36
        val sampleRate = 44100L
        val channels = 1
        val byteRate = sampleRate * channels * 2 // 2 bytes per sample for 16-bit
        
        val header = ByteArray(44)
        header[0] = 'R'.code.toByte()  // RIFF/WAVE header
        header[1] = 'I'.code.toByte()
        header[2] = 'F'.code.toByte()
        header[3] = 'F'.code.toByte()
        header[4] = (totalDataLen and 0xffL).toByte()
        header[5] = (totalDataLen shr 8 and 0xffL).toByte()
        header[6] = (totalDataLen shr 16 and 0xffL).toByte()
        header[7] = (totalDataLen shr 24 and 0xffL).toByte()
        header[8] = 'W'.code.toByte()
        header[9] = 'A'.code.toByte()
        header[10] = 'V'.code.toByte()
        header[11] = 'E'.code.toByte()
        header[12] = 'f'.code.toByte()  // 'fmt ' chunk
        header[13] = 'm'.code.toByte()
        header[14] = 't'.code.toByte()
        header[15] = ' '.code.toByte()
        header[16] = 16  // 4 bytes: size of 'fmt ' chunk
        header[17] = 0
        header[18] = 0
        header[19] = 0
        header[20] = 1  // format = 1 (PCM)
        header[21] = 0
        header[22] = channels.toByte()
        header[23] = 0
        header[24] = (sampleRate and 0xffL).toByte()
        header[25] = (sampleRate shr 8 and 0xffL).toByte()
        header[26] = (sampleRate shr 16 and 0xffL).toByte()
        header[27] = (sampleRate shr 24 and 0xffL).toByte()
        header[28] = (byteRate and 0xffL).toByte()
        header[29] = (byteRate shr 8 and 0xffL).toByte()
        header[30] = (byteRate shr 16 and 0xffL).toByte()
        header[31] = (byteRate shr 24 and 0xffL).toByte()
        header[32] = (channels * 2).toByte()  // block align
        header[33] = 0
        header[34] = 16  // bits per sample
        header[35] = 0
        header[36] = 'd'.code.toByte()  // 'data' chunk
        header[37] = 'a'.code.toByte()
        header[38] = 't'.code.toByte()
        header[39] = 'a'.code.toByte()
        header[40] = (totalAudioLen and 0xffL).toByte()
        header[41] = (totalAudioLen shr 8 and 0xffL).toByte()
        header[42] = (totalAudioLen shr 16 and 0xffL).toByte()
        header[43] = (totalAudioLen shr 24 and 0xffL).toByte()

        out.write(header, 0, 44)
    }

    // --- Utilities ---
    private fun getIsoTimestamp(date: Date): String {
        val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        isoFormat.timeZone = TimeZone.getTimeZone("UTC")
        return isoFormat.format(date)
    }

    private fun generateSecureHash(file: File): String {
        val keyAlias = "EvidenceSecureKey"
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)

        if (!keyStore.containsAlias(keyAlias)) {
            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA256, "AndroidKeyStore")
            keyGenerator.init(
                KeyGenParameterSpec.Builder(keyAlias, KeyProperties.PURPOSE_SIGN)
                    .build()
            )
            keyGenerator.generateKey()
        }

        val secretKey = keyStore.getKey(keyAlias, null)
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(secretKey)

        val fis = FileInputStream(file)
        val buffer = ByteArray(8192)
        var read: Int
        while (fis.read(buffer).also { read = it } != -1) {
            mac.update(buffer, 0, read)
        }
        fis.close()

        val macResult = mac.doFinal()
        return macResult.joinToString("") { "%02x".format(it) }
    }
}
