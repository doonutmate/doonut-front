import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:day1/widgets/atoms/flash_change_button.dart';
import 'package:day1/widgets/atoms/flip_button.dart';
import 'package:day1/widgets/atoms/reshoot_text_button.dart';
import 'package:day1/widgets/atoms/shutter_button.dart';
import 'package:day1/widgets/atoms/store_text_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import '../../constants/size.dart';
import '../../widgets/atoms/cancel_text_button.dart';
import '../../widgets/atoms/day1_camera.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen(List<CameraDescription> this.cameras, {super.key});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  String formatDate = "";
  bool isFrontCamera = false;
  File? responseImage;

  @override
  void initState() {
    super.initState();
    setCamera(isFrontCamera);
  }

  @override
  void dispose() {
    // 카메라 컨트롤러 해제
    controller.dispose();
    super.dispose();
  }

  //카메라 설정하는 함수
  void setCamera(bool isFront) {
    controller = CameraController(
        isFront ? widget.cameras[1] : widget.cameras[0], ResolutionPreset.max,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.bgra8888);

    _initializeControllerFuture = controller.initialize().then((_) {
      // 카메라가 작동되지 않을 경우
      if (!this.mounted) {
        print("이니셜라이즈 실패");
        return;
      }
      controller.setFlashMode(FlashMode.off);
      // 카메라가 작동될 경우
      setState(() {
        // 코드 작성
      });
    })
        // 카메라 오류 시
        .catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print("CameraController Error : CameraAccessDenied");
            // Handle access errors here.
            break;
          default:
            print("CameraController Error");
            // Handle other errors here.
            break;
        }
      }
    });
  }

  //void setSkeletonImage()

  //사진 촬영하는 함수
  Future<void> _takePicture() async {
    if (!controller.value.isInitialized || controller == null) {
      return;
    }
    try {
      // 사진 촬영
      final file = await controller.takePicture();

      // 이미지 용량 압축
      final XFile? _reduceFile;
      _reduceFile = await compressFile(file);

      // 이미지를 카메라 화면에 맞게 crop
      final File cropFile;
      if (_reduceFile != null) {
        cropFile = await cropImage(_reduceFile);

        setState(() {
          responseImage = File(cropFile.path);
        });
      }
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  //사진 사이즈 조절 함수
  /*Future<File?> resizeImage(XFile _image) async {
    late final img.Image resizedImage;
    final path = _image.path;
    final bytes = await File(path).readAsBytes();
    final img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      resizedImage =
          img.copyResize(image, width: targetWidth, height: targetHeight);

      String tempPath = (await getTemporaryDirectory()).path;
      var now = new DateTime.now();
      formatDate = DateFormat('yyMMdd_HH:mm:ss').format(now);
      final tempFile = File('$tempPath/${formatDate}_resized_image.jpg');

      return tempFile.writeAsBytes(img.encodeJpg(resizedImage));
    } else {
      return null;
    }
  }*/

  //찍은 사진을 카메라 화면 크기대로 자르는 함수
  Future<File> cropImage(XFile _imageFile) async {
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(_imageFile.path);
    var cropSize = min(properties.width!, properties.height!);
    int offsetX = (properties.width! - cropSize) ~/ 2;
    int offsetY = (properties.height! - cropSize) ~/ 2;
    var cropImageFile = await FlutterNativeImage.cropImage(
        _imageFile.path, offsetX, offsetY, cropSize, cropSize);

    return cropImageFile;
  }

  //사진 용량 압축하는 함수
  Future<XFile?> compressFile(XFile file) async {
    var fileFromImage = File(file.path);
    var basename = path.basenameWithoutExtension(fileFromImage.path);
    var pathString =
        fileFromImage.path.split(path.basename(fileFromImage.path))[0];

    var pathStringWithExtension = "$pathString${basename}_image.jpg";
    var result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      pathStringWithExtension,
      quality: 5,
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: cameraScreenAppbarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                //카메라 화면을 보여줄 때는 취소 버튼만 있고, 사진찍고 나서는 다시찍기 버튼과 저장버튼이 있다.
                children: responseImage == null
                    ? [
                        CancelTextButton(),
                      ]
                    : [
                        ReshootTextButton(
                          func: () {
                            setState(() {
                              responseImage = null;
                            });
                          },
                        ),
                        Spacer(),
                        StoreTextButton()
                      ],
              ),
            ),
            // 카메라 화면 가로 세로 비율을 1대1로 고정
            AspectRatio(
              aspectRatio: 1,
              // 서버에서 응답받은 이미지가 있을 경우 이미지를 화면에 보여주고 없으면 카메라 화면을 보여준다
              child: responseImage != null
                  ? Image.file(responseImage!)
                  : Day1Camera(
                      initializeControllerFuture: _initializeControllerFuture,
                      controller: controller),
            ),
            Expanded(flex: 1, child: SizedBox()),
            Padding(
              padding: screenHorizontalMargin,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 플래시 on/off 버튼
                  FlashChangeButton(
                    controller: controller,
                    responseImage: responseImage,
                  ),
                  //사진촬영 버튼
                  ShutterButton(
                    shutterFunc: _takePicture,
                    responseImage: responseImage,
                  ),

                  //카메라 전면/후면 전환 버튼
                  FlipButton(
                    func: setCamera,
                    responseImage: responseImage,
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
