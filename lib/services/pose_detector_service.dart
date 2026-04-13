import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum PullUpState { idle, hanging, goingUp, atTop, goingDown, completed }

class PoseDetectorService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.stream,
    ),
  );

  PullUpState _state = PullUpState.idle;
  int _count = 0;
  DateTime? _lastCountTime;
  double? _hangingNoseY;

  int get count => _count;
  PullUpState get state => _state;

  final StreamController<int> _countController =
      StreamController<int>.broadcast();
  Stream<int> get countStream => _countController.stream;

  bool _isProcessing = false;

  Future<void> processImage(CameraImage image, InputImageRotation rotation) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image, rotation);
      if (inputImage == null) return;

      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) return;

      _processPose(poses.first);
    } catch (_) {
      // silently ignore errors during pose detection
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image, InputImageRotation rotation) {
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _processPose(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    // Filter by confidence
    if (nose == null || nose.likelihood < 0.7) return;
    if (leftWrist == null || rightWrist == null) return;
    if (leftWrist.likelihood < 0.7 || rightWrist.likelihood < 0.7) return;

    final noseY = nose.y;
    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final avgShoulderY = leftShoulder != null && rightShoulder != null
        ? (leftShoulder.y + rightShoulder.y) / 2
        : null;

    const threshold = 30.0;

    switch (_state) {
      case PullUpState.idle:
        // Detect hanging: wrists are above shoulders
        if (avgShoulderY != null && avgWristY < avgShoulderY) {
          _state = PullUpState.hanging;
          _hangingNoseY = noseY;
        }
        break;

      case PullUpState.hanging:
        // Update hanging nose position baseline
        _hangingNoseY = noseY;
        // Detect going up: nose Y decreasing (moving up in pixel coords)
        if (noseY < avgWristY * 1.3) {
          _state = PullUpState.goingUp;
        }
        break;

      case PullUpState.goingUp:
        // At top: nose Y <= wrist Y (chin over bar)
        if (noseY <= avgWristY + threshold) {
          _state = PullUpState.atTop;
        }
        break;

      case PullUpState.atTop:
        // Going down: nose Y increasing
        if (noseY > avgWristY + threshold) {
          _state = PullUpState.goingDown;
        }
        break;

      case PullUpState.goingDown:
        // Completed: nose back near hanging position
        if (_hangingNoseY != null &&
            noseY >= _hangingNoseY! - threshold) {
          final now = DateTime.now();
          if (_lastCountTime == null ||
              now.difference(_lastCountTime!).inMilliseconds >= 1000) {
            _count++;
            _lastCountTime = now;
            _countController.add(_count);
          }
          _state = PullUpState.hanging;
          _hangingNoseY = noseY;
        }
        break;

      case PullUpState.completed:
        break;
    }
  }

  void incrementManual() {
    _count++;
    _countController.add(_count);
  }

  void decrementManual() {
    if (_count > 0) {
      _count--;
      _countController.add(_count);
    }
  }

  void resetCount() {
    _count = 0;
    _state = PullUpState.idle;
    _hangingNoseY = null;
    _lastCountTime = null;
  }

  Future<void> dispose() async {
    await _poseDetector.close();
    await _countController.close();
  }
}
