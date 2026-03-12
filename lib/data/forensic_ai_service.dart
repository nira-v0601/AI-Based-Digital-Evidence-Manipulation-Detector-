import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ForensicAIService {
  Interpreter? _interpreter;
  bool _isInit = false;

  /// Initializes the TFLite interpreter by loading the manipulation detector model.
  Future<void> initialize() async {
    if (_isInit) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/manipulation_detector.tflite');
      _isInit = true;
      print('ForensicAIService: TFLite model loaded successfully.');
    } catch (e) {
      print('ForensicAIService Initialization Error: Failed to load TFLite model: $e');
    }
  }

  /// Closes the interpreter to release resources.
  void dispose() {
    _interpreter?.close();
    _isInit = false;
  }

  /// Analyzes the given image file using the initialized TFLite model.
  /// Reads the image, converts it into a Float32List tensor shaped [1, 224, 224, 3],
  /// normalizes pixel values to [0.0, 1.0], and runs inference.
  /// 
  /// Returns a confidence score between 0.0 and 1.0, where 1.0 strongly indicates manipulation.
  /// If the model fails or processing encounters an error, returns null.
  /// Analyzes the given image file.
  /// Combines 6 sub-scores: Metadata, ELA, Noise, Copy-Move, Lighting, AI Signature.
  Future<double?> analyzeImage(String filePath) async {
    if (!_isInit || _interpreter == null) {
      print('ForensicAIService Error: Interpreter is not initialized.');
      // Attempt generic initialization
      await initialize();
      if (!_isInit || _interpreter == null) return null;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }
      final rawBytes = await file.readAsBytes();
      
      // 1. Metadata Extraction (15%)
      double metaScore = _analyzeMetadata(rawBytes);

      img.Image? originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) return null;

      // 2. Error Level Analysis (ELA) (25%)
      double elaScore = _analyzeELA(originalImage);

      // 3. Noise Pattern Consistency Check (20%)
      double noiseScore = _analyzeNoiseConsistency(originalImage);

      // 4. Copy-Move Forgery Detection (15%)
      double copyMoveScore = _analyzeCopyMove(originalImage);

      // 5. Lighting and Shadow Consistency (10%)
      double lightingScore = _analyzeLightingConsistency(originalImage);

      // 6. AI Generated Image Detection (15%)
      double aiScore = await _runTFLiteInference(originalImage);

      // Combine scores with weights
      double finalConfidence = (metaScore * 0.15) + (elaScore * 0.25) + (noiseScore * 0.20) + (copyMoveScore * 0.15) + (lightingScore * 0.10) + (aiScore * 0.15);

      if (finalConfidence < 0.0) finalConfidence = 0.0;
      if (finalConfidence > 1.0) finalConfidence = 1.0;

      print('ForensicAIService: Multi-layered Analysis Complete.');
      print('Meta: $metaScore, ELA: $elaScore, Noise: $noiseScore, CopyMove: $copyMoveScore, Lighting: $lightingScore, AI: $aiScore');
      print('Final Confidence: $finalConfidence');
      
      return finalConfidence;
    } catch (e, stackTrace) {
      print('ForensicAIService Execution Error:  $e');
      print('Stacktrace: $stackTrace');
      return null;
    }
  }

  double _analyzeMetadata(List<int> imageBytes) {
    try {
      final exifFile = img.decodeImage(Uint8List.fromList(imageBytes));
      if (exifFile == null || !exifFile.hasExif) return 0.0;
      
      final softwareList = ['photoshop', 'gimp', 'snapseed', 'lightroom', 'canva', 'pixelmator', 'affinity'];
      // A rudimentary dart/image EXIF metadata check - extracting raw strings might be necessary if strict EXIF is mapped.
      // We will perform a basic byte-search for common software signatures as a highly effective baseline.
      String rawString = String.fromCharCodes(imageBytes.take(2048)); // Check just the headers
      String lowerStr = rawString.toLowerCase();
      
      for (String software in softwareList) {
        if (lowerStr.contains(software)) {
          return 1.0; // Found editing software footprint
        }
      }
      return 0.1; // Baseline if EXIF is present but clean
    } catch (e) {
      return 0.2; // Invalid metadata structure
    }
  }

  double _analyzeELA(img.Image image) {
    // Recompress image at 85 quality
    List<int> compressed = img.encodeJpg(image, quality: 85);
    img.Image? recompressedImage = img.decodeJpg(Uint8List.fromList(compressed));
    if (recompressedImage == null) return 0.0;

    double maxDiff = 0;
    double totalDiff = 0;
    int samples = 0;

    // Sample every 5th pixel for speed
    for (int y = 0; y < image.height; y += 5) {
      for (int x = 0; x < image.width; x += 5) {
        img.Pixel p1 = image.getPixelSafe(x, y);
        img.Pixel p2 = recompressedImage.getPixelSafe(x, y);
        
        double diff = ((p1.r - p2.r).abs() + (p1.g - p2.g).abs() + (p1.b - p2.b).abs()) / 3.0;
        totalDiff += diff;
        if (diff > maxDiff) maxDiff = diff;
        samples++;
      }
    }
    
    double avgDiff = samples > 0 ? (totalDiff / samples) : 0;
    
    // An unusually high variance or maxDiff compared to avgDiff implies edited regions
    double elaAnomaly = 0.0;
    if (maxDiff > avgDiff * 4) { 
      elaAnomaly = ((maxDiff - avgDiff * 4) / 50.0).clamp(0.0, 1.0);
    }
    return elaAnomaly;
  }

  double _analyzeNoiseConsistency(img.Image image) {
    // Determine luminance variance in 32x32 blocks
    int blockSize = 32;
    List<double> blockVariances = [];
    
    for (int y = 0; y < image.height - blockSize; y += blockSize) {
      for (int x = 0; x < image.width - blockSize; x += blockSize) {
        List<double> luminosities = [];
        for (int by = 0; by < blockSize; by++) {
          for (int bx = 0; bx < blockSize; bx++) {
             img.Pixel p = image.getPixelSafe(x + bx, y + by);
             // Standard relative luminance
             double lum = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
             luminosities.add(lum);
          }
        }
        
        double mean = luminosities.reduce((a, b) => a + b) / luminosities.length;
        double variance = luminosities.map((l) => (l - mean) * (l - mean)).reduce((a, b) => a + b) / luminosities.length;
        blockVariances.add(variance);
      }
    }
    
    if (blockVariances.isEmpty) return 0.0;
    
    double meanVar = blockVariances.reduce((a, b) => a + b) / blockVariances.length;
    double varOfVars = blockVariances.map((v) => (v - meanVar) * (v - meanVar)).reduce((a, b) => a + b) / blockVariances.length;
    
    // High varOfVars means some blocks have huge noise and others are perfectly smooth (edited).
    double noiseAnomaly = (varOfVars / 5000.0).clamp(0.0, 1.0);
    return noiseAnomaly;
  }

  double _analyzeCopyMove(img.Image image) {
    // Highly simplified spatial pattern hash collision check
    int blockSize = 64;
    Map<int, int> hashes = {};
    int clonesDetected = 0;
    int totalBlocks = 0;

    img.Image resized = img.copyResize(image, width: 256, height: 256); // Normalize down to find macro copies
    
    for (int y = 0; y <= resized.height - blockSize; y += 32) {
      for (int x = 0; x <= resized.width - blockSize; x += 32) {
        int rSum = 0, gSum = 0, bSum = 0;
        for (int by = 0; by < blockSize; by += 4) {
          for (int bx = 0; bx < blockSize; bx += 4) {
            img.Pixel p = resized.getPixelSafe(x + bx, y + by);
            rSum += (p.r / 32).floor(); // Quantize to ignore slight noise
            gSum += (p.g / 32).floor();
            bSum += (p.b / 32).floor();
          }
        }
        // Create an integer hash of the quantized block
        int hash = (rSum << 16) | (gSum << 8) | bSum;
        totalBlocks++;
        
        if (hashes.containsKey(hash)) {
          clonesDetected++;
        } else {
          hashes[hash] = 1;
        }
      }
    }
    
    if (totalBlocks == 0) return 0.0;
    double cloneRatio = (clonesDetected / totalBlocks);
    
    return (cloneRatio * 5.0).clamp(0.0, 1.0); 
  }

  double _analyzeLightingConsistency(img.Image image) {
    // Computes top vs bottom, left vs right lum gradients
    double leftLum = 0, rightLum = 0, topLum = 0, bottomLum = 0;
    
    img.Image resized = img.copyResize(image, width: 128, height: 128); // Fast spatial analysis
    
    int halfW = resized.width ~/ 2;
    int halfH = resized.height ~/ 2;

    for (int y = 0; y < resized.height; y += 2) {
      for (int x = 0; x < resized.width; x += 2) {
        img.Pixel p = resized.getPixelSafe(x, y);
        double lum = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
        
        if (x < halfW) {
             leftLum += lum; 
        } else {
             rightLum += lum;
        }
        if (y < halfH) {
             topLum += lum;
        } else {
             bottomLum += lum;
        }
      }
    }

    double diffX = (leftLum - rightLum).abs() / (leftLum + rightLum + 1);
    double diffY = (topLum - bottomLum).abs() / (topLum + bottomLum + 1);
    
    // Very extreme lighting gradients often indicate flash or compositing.
    double maxGradient = diffX > diffY ? diffX : diffY;
    
    return (maxGradient * 1.5).clamp(0.0, 1.0);
  }

  Future<double> _runTFLiteInference(img.Image originalImage) async {
    try {
      img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224, interpolation: img.Interpolation.linear);

      var inputTensor = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          img.Pixel pixel = resizedImage.getPixelSafe(x, y);
          inputTensor[pixelIndex++] = pixel.r / 255.0; 
          inputTensor[pixelIndex++] = pixel.g / 255.0; 
          inputTensor[pixelIndex++] = pixel.b / 255.0; 
        }
      }

      var input = inputTensor.reshape([1, 224, 224, 3]);
      var output = List.generate(1, (_) => List.filled(1, 0.0));

      _interpreter!.run(input, output);

      double aiConfidenceScore = output[0][0];
      return aiConfidenceScore.clamp(0.0, 1.0);
    } catch (_) {
      return 0.0; // Fallback
    }
  }
}
