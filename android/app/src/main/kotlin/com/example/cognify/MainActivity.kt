package com.example.cognify

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterActivity() {

    private val CHANNEL = "mental_health_prediction"
    private lateinit var mentalHealthPredictor: MentalHealthPredictor

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize the predictor
        mentalHealthPredictor = MentalHealthPredictor(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "predict" -> {
                    try {
                        val responses = call.argument<List<Int>>("responses")
                        if (responses == null) {
                            result.error("INVALID_ARGUMENT", "Responses cannot be null", null)
                            return@setMethodCallHandler
                        }

                        if (responses.size != 25) {
                            result.error("INVALID_ARGUMENT", "Expected 25 responses, got ${responses.size}", null)
                            return@setMethodCallHandler
                        }

                        val responsesArray = responses.toIntArray()
                        val prediction = mentalHealthPredictor.predict(responsesArray)
                        result.success(prediction)

                    } catch (e: Exception) {
                        result.error("PREDICTION_ERROR", "Error during prediction: ${e.message}", null)
                    }
                }

                "testModel" -> {
                    try {
                        // Test with normal case (matching your Python example)
                        val normalResponses = intArrayOf(0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,4,4,4,4,4,0,0,0,3)
                        val normalResult = mentalHealthPredictor.predict(normalResponses)

                        // Test with depressed case (matching your Python example)
                        val depressedResponses = intArrayOf(3,3,2,3,3,2,3,2,2,3,3,2,3,3,2,3,0,1,1,0,1,3,3,3,0)
                        val depressedResult = mentalHealthPredictor.predict(depressedResponses)

                        val testResults = mapOf(
                            "normal_case" to normalResult,
                            "depressed_case" to depressedResult
                        )

                        result.success(testResults)

                    } catch (e: Exception) {
                        result.error("TEST_ERROR", "Error during testing: ${e.message}", null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::mentalHealthPredictor.isInitialized) {
            mentalHealthPredictor.close()
        }
    }
}