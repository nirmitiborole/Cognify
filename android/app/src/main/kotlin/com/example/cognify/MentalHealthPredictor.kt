package com.example.cognify

import android.content.Context
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import kotlin.math.max
import kotlin.math.round

class MentalHealthPredictor(private val context: Context) {

    private var depressionModel: Interpreter? = null
    private var anxietyModel: Interpreter? = null

    // Scaler parameters from your trained Python model
    private val featureMeans = floatArrayOf(
        1.95131086f, 2.08988764f, 2.1011236f, 1.99625468f, 2.06367041f, 1.83146067f, 2.03745318f, 1.8576779f, 1.97003745f, // PHQ-9 questions (q1-q9)
        1.917603f, 2.082397f, 2.0411985f, 1.94756554f, 2.01498127f, 1.917603f, 2.05243446f, // GAD-7 questions (q10-q16)
        2.65543071f, 2.44569288f, 2.41198502f, 2.43071161f, 2.49812734f, // WHO-5 questions (q17-q21)
        1.97003745f, 2.10486891f, 1.84644195f, 1.93632959f, // Social functioning questions (q22-q25)
        1.26997233f, // dep_anx_ratio
        20.29962547f, // wellbeing_social_sum
        31.87265918f // total_distress
    )

    private val featureStds = floatArrayOf(
        1.4304959f, 1.39802254f, 1.36058709f, 1.44952046f, 1.44294435f, 1.42136682f, 1.44256517f, 1.34441801f, 1.40326038f, // PHQ-9 questions (q1-q9)
        1.39042642f, 1.36596849f, 1.44376072f, 1.42643044f, 1.43516572f, 1.47156222f, 1.39724973f, // GAD-7 questions (q10-q16)
        1.73561463f, 1.63295021f, 1.70335827f, 1.71517589f, 1.61076559f, // WHO-5 questions (q17-q21)
        1.42445245f, 1.39965709f, 1.50741503f, 1.44812626f, // Social functioning questions (q22-q25)
        0.44126218f, // dep_anx_ratio
        4.21519898f, // wellbeing_social_sum
        5.70881125f // total_distress
    )

    init {
        loadModels()
    }

    private fun loadModels() {
        try {
            depressionModel = Interpreter(loadModelFile("depression_model.tflite"))
            anxietyModel = Interpreter(loadModelFile("anxiety_model.tflite"))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun loadModelFile(filename: String): MappedByteBuffer {
        val assetFileDescriptor = context.assets.openFd(filename)
        val inputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = assetFileDescriptor.startOffset
        val declaredLength = assetFileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }

    fun predict(responses: IntArray): Map<String, Any> {
        if (responses.size != 25) {
            throw IllegalArgumentException("Expected 25 responses, got ${responses.size}")
        }

        // Calculate component scores
        val depressionScore = responses.sliceArray(0..8).sum() // q1_phq to q9_phq
        val anxietyScore = responses.sliceArray(9..15).sum() // q10_gad to q16_gad
        val wellbeingScore = responses.sliceArray(16..20).sum() // q17_who5 to q21_who5
        val socialFunctioningScore = responses.sliceArray(21..24).sum() // q22_life to q25_life

        // Calculate engineered features
        val depAnxRatio = depressionScore.toFloat() / (anxietyScore + 1).toFloat()
        val wellbeingSocialSum = wellbeingScore + socialFunctioningScore
        val totalDistress = depressionScore + anxietyScore

        // Prepare input features (original 25 + 3 engineered = 28 features)
        val features = FloatArray(28)

        // Copy original responses
        for (i in responses.indices) {
            features[i] = responses[i].toFloat()
        }

        // Add engineered features
        features[25] = depAnxRatio
        features[26] = wellbeingSocialSum.toFloat()
        features[27] = totalDistress.toFloat()

        // Apply StandardScaler normalization
        val featuresScaled = FloatArray(28)
        for (i in features.indices) {
            featuresScaled[i] = (features[i] - featureMeans[i]) / featureStds[i]
        }

        // Prepare input buffer for TFLite
        val inputBuffer = ByteBuffer.allocateDirect(28 * 4).order(ByteOrder.nativeOrder())
        for (feature in featuresScaled) {
            inputBuffer.putFloat(feature)
        }

        // Prepare output buffers
        val depressionOutput = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder())
        val anxietyOutput = ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder())

        // Run inference
        inputBuffer.rewind()
        depressionModel?.run(inputBuffer, depressionOutput)

        inputBuffer.rewind()
        anxietyModel?.run(inputBuffer, anxietyOutput)

        // Extract probabilities
        depressionOutput.rewind()
        val depressionProbability = depressionOutput.float * 100

        anxietyOutput.rewind()
        val anxietyProbability = anxietyOutput.float * 100

        // Calculate wellness components (matching Python logic)
        val depressionWellness = max(0.0, (36 - depressionScore).toDouble() / 36.0 * 100.0)
        val anxietyWellness = max(0.0, (28 - anxietyScore).toDouble() / 28.0 * 100.0)
        val wellbeingWellness = (wellbeingScore.toDouble() / 25.0) * 100.0
        val socialWellness = (socialFunctioningScore.toDouble() / 16.0) * 100.0

        // Calculate comprehensive score (matching Python weights)
        val comprehensiveScore = (
                depressionWellness * 0.30 +
                        anxietyWellness * 0.30 +
                        wellbeingWellness * 0.25 +
                        socialWellness * 0.15
                )

        return mapOf(
            // Main results
            "comprehensive_score" to round(comprehensiveScore * 100) / 100,
            "depression_probability" to round(depressionProbability * 100) / 100,
            "anxiety_probability" to round(anxietyProbability * 100) / 100,

            // Component scores
            "depression_score" to depressionScore,
            "anxiety_score" to anxietyScore,
            "wellbeing_score" to wellbeingScore,
            "social_functioning_score" to socialFunctioningScore,

            // Wellness components
            "depression_wellness" to round(depressionWellness * 100) / 100,
            "anxiety_wellness" to round(anxietyWellness * 100) / 100,
            "wellbeing_wellness" to round(wellbeingWellness * 100) / 100,
            "social_wellness" to round(socialWellness * 100) / 100,

            // Engineered features
            "dep_anx_ratio" to round(depAnxRatio * 100) / 100,
            "wellbeing_social_sum" to wellbeingSocialSum,
            "total_distress" to totalDistress
        )
    }

    fun close() {
        depressionModel?.close()
        anxietyModel?.close()
    }
}