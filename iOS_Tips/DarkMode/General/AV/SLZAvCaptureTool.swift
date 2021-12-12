//
//  SLZAvCaptureTool.swift
//
//  Created by Zheng Li on 2021/11/9.
//  Copyright © 2021 Zas. All rights reserved.
//  翻译自:  https://github.com/wsl2ls/iOS_Tips/blob/master/iOS_Tips/DarkMode/General/AV/SLAvCaptureTool.h

import UIKit
import AVFoundation
import CoreMotion
///音视频捕获类型
enum SLZAvCaptureType{
    /// 音视频
    case SLZAvCaptureTypeAv
    /// 纯视频
    case SLZAvCaptureTypeVideo
    /// 纯音频
    case SLZAvCaptureTypeAudio
}

class SLZAvCaptureTool: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate{
// MARK: - life cycle
    override init() {
        super.init();
        self.videoSize = UIScreen.main.bounds.size;
    }
    init(with type: SLZAvCaptureType){
        super.init();
        self.videoSize = UIScreen.main.bounds.size;
        self.avCaptureType = type;
    }
    deinit{
        self.stopRunning();
    }
// MARK: - public properties
    /// 摄像头采集内容预览视图
    var preview: UIView?{
        didSet{
            if let view = preview{
                self.previewLayer.frame = view.bounds;
                view.layer.addSublayer(self.previewLayer);
            }
            else{
                self.previewLayer.removeFromSuperlayer();
            }
        }
    };
    /// 导出的视频宽高  默认设备宽高  已home键朝下为准
    var videoSize: CGSize?;
    /// 摄像头是否正在运行
    var isRunning = false;
    /// 摄像头方向 默认后置摄像头
    private (set) public var devicePosition: AVCaptureDevice.Position?;
    /// 闪光灯状态  默认是关闭的，即黑暗情况下拍照不打开闪光灯   （打开/关闭/自动）
    var flashMode: AVCaptureDevice.FlashMode?;
    /// 当前焦距    默认最小值1  最大值6
    var videoZoomFactor: CGFloat = 1.0{
        didSet{
            if (videoZoomFactor <= self.maxZoomFactor && videoZoomFactor >= self.minZoomFactor){
                do{
                    try self.videoInput!.device.lockForConfiguration();
                    self.videoInput!.device.videoZoomFactor = videoZoomFactor;
                    self.videoInput?.device.unlockForConfiguration();
                }
                catch{
                    print("failed");
                }
            }
        }
    };
    /// 设置previewLayer的图层填充方式
    var videoGravity: AVLayerVideoGravity?{
        didSet{
            if let gravity = self.videoGravity{
                self.previewLayer.videoGravity = gravity;
            }
        }
    }
    /// 捕获工具输出代理
    weak var delegate: SLZAvCaptureToolDelegate?;

// MARK: - private properties
    /// 采集会话
    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession();
        if session.canSetSessionPreset(.hd1280x720) {session.sessionPreset = .hd1280x720};
        if self.avCaptureType != .SLZAvCaptureTypeAudio{
            if session.canAddInput(self.videoInput!) {session.addInput(self.videoInput!)}
            if session.canAddOutput(self.capturePhotoOutput) {session.addOutput(self.capturePhotoOutput)};
            if session.canAddOutput(self.videoDataOutput) {session.addOutput(self.videoDataOutput)};
            
            let captureVideoConnection = self.videoDataOutput.connection(with: .video)!;
            if self.devicePosition == .front && captureVideoConnection.isVideoMirroringSupported{
                captureVideoConnection.isVideoMirrored = true;
            }
            captureVideoConnection.videoOrientation = .portrait;
        }
        
        if self.avCaptureType == .SLZAvCaptureTypeAudio || self.avCaptureType == .SLZAvCaptureTypeAv{
            if session.canAddInput(self.audioInput!) {session.addInput(self.audioInput!)}
            if session.canAddOutput(self.audioDataOutput) {session.addOutput(self.audioDataOutput)};
        }
        
        return session;
    }();
    /// 摄像头采集内容展示区域
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer.init(session: self.session);
        layer.videoGravity = .resizeAspect;
        return layer;
    }();
    //音频输入流
    private lazy var audioInput: AVCaptureDeviceInput? = {
        let audioCaptureDevice = AVCaptureDevice.default(for: .audio);
        do {
            let audioInput = try AVCaptureDeviceInput.init(device: audioCaptureDevice!)
            return audioInput;
        } catch let error{
            print(error.localizedDescription)
            return nil
        }
    }();
    //视频输入流
    private lazy var videoInput: AVCaptureDeviceInput? = {
        //添加一个视频输入设备  默认是后置摄像头
        if let videoCaptureDevice = self.getCameraDeviceWithPosition(.back){
            do {
                let videoInput = try AVCaptureDeviceInput.init(device: videoCaptureDevice)
                return videoInput;
            } catch let error{
                print(error.localizedDescription)
                return nil
            }
        }
        else{
            return nil;
        }
    }();
    //照片输出流
    private lazy var capturePhotoOutput: AVCapturePhotoOutput = {
        return AVCapturePhotoOutput.init();
    }();
    //视频数据帧输出流
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let _videoDataOutput = AVCaptureVideoDataOutput.init();
        _videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        return _videoDataOutput;
    }();
    //音频数据帧输出流
    private lazy var audioDataOutput: AVCaptureAudioDataOutput = {
        let _audioDataOutput = AVCaptureAudioDataOutput.init();
        _audioDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        return _audioDataOutput;
    }();
    //音视频数据流文件写入
    private var assetWriter: AVAssetWriter?;
    //写入视频文件
    private lazy var assetWriterVideoInput: AVAssetWriterInput? = {
        return self.getNewAssetWriterVideoInput();
    }();
    //写入音频文件
    private lazy var assetWriterAudioInput: AVAssetWriterInput? = {
        return self.getNewAssetWriterAudioInput();
    }();
    //视频写入配置
    private lazy var videoCompressionSettings: [String: Any] = {
        return [:];
    }();
    //音频写入配置
    private lazy var audioCompressionSettings: [String: Any] = {
        return [:];
    }();
    //是否能写入
    private var canWrite = false;
    //音视频文件输出路径
    private var outputFileURL: NSURL?{
        didSet{
            if let fileUrl = outputFileURL{
                if self.avCaptureType == .SLZAvCaptureTypeAudio{
                    do {
                        self.assetWriter = try AVAssetWriter.init(url: fileUrl as URL, fileType: .ac3)
                    } catch let error{
                        print(error.localizedDescription);
                    }
                }
                else{
                    do {
                        self.assetWriter = try AVAssetWriter.init(url: fileUrl as URL, fileType: .mp4)
                    } catch let error{
                        print(error.localizedDescription);
                    }
                }
            }
        }
    };
    //是否正在录制
    private var isRecording = false;
    //音视频捕获类型 默认 SLZAvCaptureTypeAv
    private var avCaptureType: SLZAvCaptureType = .SLZAvCaptureTypeAv;
    //拍摄录制时的手机方向
    private var shootingOrientation: UIDeviceOrientation = .portrait;
    //运动传感器  监测设备方向
    private var motionManager: CMMotionManager? = CMMotionManager.init();
    //最大缩放值 焦距
    private var maxZoomFactor: CGFloat{
        get{
            var maxZoomFactorInternal = self.videoInput!.device.activeFormat.videoMaxZoomFactor;
            if #available(iOS 11.0, *) {
                maxZoomFactorInternal = self.videoInput!.device.maxAvailableVideoZoomFactor;
            }
            if (maxZoomFactorInternal > 6) {
                maxZoomFactorInternal = 6.0;
            }
            return maxZoomFactorInternal;
        }
    }
    
    //最小缩放值 焦距
    private var minZoomFactor: CGFloat{
        get{
            var minZoomFactorInternal = 1.0;
            if #available(iOS 11.0, *) {
                minZoomFactorInternal = self.videoInput!.device.minAvailableVideoZoomFactor;
            }
            return minZoomFactorInternal;
        }
    }
}

// MARK: - public methods
extension SLZAvCaptureTool{
    ///启动捕获
    func startRunning(){
        if !self.session.isRunning{
            self.session.startRunning();
        }
        self.startUpdateDeviceDirection();
    }
    ///结束捕获
    func stopRunning(){
        if self.session.isRunning{
            self.session.stopRunning();
            self.stopUpdateDeviceDirection();
        }
    }
    /// 聚焦点  默认是连续聚焦模式  范围是在previewLayer上
    func focusAtPoint(_ focalPoint: CGPoint){
        //将UI坐标转化为摄像头坐标  (0,0) -> (1,1)
        let cameraPoint = self.previewLayer.captureDevicePointConverted(fromLayerPoint: focalPoint);
        
        let captureDevice = self.videoInput!.device;
        
        do{
            //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
            try captureDevice.lockForConfiguration();
            if captureDevice.isFocusModeSupported(.autoFocus){
                if captureDevice.isFocusPointOfInterestSupported{
                    captureDevice.focusPointOfInterest = cameraPoint;
                }
            }
            //曝光模式
            if captureDevice.isExposureModeSupported(.autoExpose){
                if captureDevice.isExposurePointOfInterestSupported{
                    captureDevice.exposurePointOfInterest = cameraPoint;
                }
                captureDevice.exposureMode = .autoExpose;
            }
            captureDevice.unlockForConfiguration();
        }
        catch{
            print("287 error");
        }
    }
    /// 切换前/后置摄像头
    func switchsCamera(devicePosition: AVCaptureDevice.Position){
        //当前设备方向
        if (self.devicePosition == devicePosition) {
            return;
        }
        do{
            let videoInput = try AVCaptureDeviceInput.init(device: self.getCameraDeviceWithPosition(devicePosition)!);
            
            //先开启配置，配置完成后提交配置改变
            self.session.beginConfiguration();
            //移除原有输入对象
            self.session.removeInput(self.videoInput!);
            //添加新的输入对象
            if self.session.canAddInput(videoInput){
                self.session.addInput(videoInput);
                self.videoInput = videoInput;
            }
            
            //视频输入对象发生了改变  视频输出的链接也要重新初始化
            let captureConnection = self.videoDataOutput.connection(with: .video)!;

            if (captureConnection.isVideoStabilizationSupported) {
                //视频稳定模式
                captureConnection.preferredVideoStabilizationMode = .auto;
            }
            if (self.devicePosition == .front && captureConnection.isVideoMirroringSupported) {
                captureConnection.isVideoMirrored = true;
            }
            captureConnection.videoOrientation = .portrait;
            //提交新的输入对象
            self.session.commitConfiguration();
        }
        catch{
            print("324 error");
        }
    }
    /// 输出图片, 执行拍照操作
    func outputPhoto(){
        //获得图片输出连接
        let captureConnection = self.capturePhotoOutput.connection(with: .video)!;
        // 设置是否为镜像，前置摄像头采集到的数据本来就是翻转的，这里设置为镜像把画面转回来
        if (self.devicePosition == .front && captureConnection.isVideoMirroringSupported) {
            captureConnection.isVideoMirrored = true;
        }
        if (self.shootingOrientation == .landscapeRight) {
            captureConnection.videoOrientation = .landscapeLeft;
        } else if (self.shootingOrientation == .landscapeLeft) {
            captureConnection.videoOrientation = .landscapeRight;
        } else if (self.shootingOrientation == .portraitUpsideDown) {
            captureConnection.videoOrientation = .portraitUpsideDown;
        } else {
            captureConnection.videoOrientation = .portrait;
        }
        //输出样式设置 AVVideoCodecKey:AVVideoCodecJPEG等
        let capturePhotoSettings = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg]);
        capturePhotoSettings.isHighResolutionPhotoEnabled = true; //高分辨率
        
        if self.flashMode != nil{
            capturePhotoSettings.flashMode = self.flashMode!;  //闪光灯 根据环境亮度自动决定是否打开闪光灯
        }
        self.capturePhotoOutput.capturePhoto(with: capturePhotoSettings, delegate: self);
    }
    
    /// 开始录制视频  默认输出MP4
    /// @param path 录制的音视频输出路径
    /// @param avRecordType 录制视频类型
    func startRecordVideoToOutputFileAtPath(_ path: String, recordType avCaptureType: SLZAvCaptureType){
        self.avCaptureType = avCaptureType;
        //移除重复文件
        if FileManager.default.fileExists(atPath: path){
            do{
                try FileManager.default.removeItem(atPath: path);
            }
            catch{
                print("file remove fail");
            }
        }

        self.outputFileURL = NSURL.init(fileURLWithPath: path);
        self.stopUpdateDeviceDirection();
        
        //获得视频输出连接
        let captureConnection = self.videoDataOutput.connection(with: .video)!;

        // 设置是否为镜像，前置摄像头采集到的数据本来就是翻转的，这里设置为镜像把画面转回来
        if (self.devicePosition == .front && captureConnection.isVideoMirroringSupported) {
            captureConnection.isVideoMirrored = true;
        }
        //这个API 每次开始录制时设置视频输出方向，会造成摄像头的短暂黑暗；切换摄像头时设置此属性没有较大的影响
        // captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        //由于上述原因，故采用在写入输出视频时调整方向
        
        if (self.shootingOrientation == .landscapeRight) {
            self.assetWriterVideoInput?.transform = CGAffineTransform(rotationAngle: .pi/2);
        } else if (self.shootingOrientation == .landscapeLeft) {
            self.assetWriterVideoInput?.transform = CGAffineTransform(rotationAngle: -.pi/2);
        } else if (self.shootingOrientation == .portraitUpsideDown) {
            self.assetWriterVideoInput?.transform = CGAffineTransform(rotationAngle: .pi);
        } else {
            self.assetWriterVideoInput?.transform = CGAffineTransform(rotationAngle: 0);
        }
        /// 重新录制时, 因为swift无法重新触发lazy load, 只能手动校验了
        if self.assetWriterVideoInput == nil{
            self.assetWriterVideoInput = self.getNewAssetWriterVideoInput();
        }
        if self.assetWriterAudioInput == nil{
            self.assetWriterAudioInput = self.getNewAssetWriterAudioInput();
        }
        guard let assetWriterSome = self.assetWriter, let videoWriterInput = self.assetWriterVideoInput, let audioWriterInput = self.assetWriterAudioInput else {return}
        
        if (assetWriterSome.canAdd(videoWriterInput)) {
            assetWriterSome.add(videoWriterInput);
        } else {
            print("视频写入失败");
        }
        if (assetWriterSome.canAdd(audioWriterInput) && self.avCaptureType == .SLZAvCaptureTypeAv) {
            assetWriterSome.add(audioWriterInput);
        } else {
            print("音频写入失败");
        }
        self.isRecording = true;
    }
    /// 结束录制视频
    func stopRecordVideo(){
        if (self.isRecording) {
            self.isRecording = false;
            if(self.assetWriter != nil && self.canWrite && self.assetWriter!.status != .unknown) {
                self.assetWriter!.finishWriting(completionHandler: { [weak self] in
                    if let delegateNew = self?.delegate, let this = self{
                        if delegateNew.responds(to: #selector(SLZAvCaptureToolDelegate.captureTool(captureTool:didFinishRecordingToOutputFileAtURL:error:))){
                            delegateNew.captureTool?(captureTool: this, didFinishRecordingToOutputFileAtURL: this.outputFileURL, error: this.assetWriter?.error)
                        }
                    }
                    self?.canWrite = false;
                    self?.assetWriter = nil;
                    self?.assetWriterAudioInput = nil;
                    self?.assetWriterVideoInput = nil;
                })
            }
        }
    }
    
    /// 开始录制音频 默认输出MP3
    /// @param path 录制的音频输出路径
    func startRecordAudioToOutputFileAtPath(_ path: String){
        self.avCaptureType = .SLZAvCaptureTypeAudio;
        //移除重复文件
        if FileManager.default.fileExists(atPath: path){
            do{
                try FileManager.default.removeItem(atPath: path);
            }
            catch{
                print("file remove fail");
            }
        }

        self.outputFileURL = NSURL.init(fileURLWithPath: path);
        self.stopUpdateDeviceDirection();
        
        self.session.beginConfiguration();
        self.session.removeOutput(self.videoDataOutput);
        self.session.commitConfiguration();
        
        /// 重新录制时, 因为swift无法重新触发lazy load, 只能手动校验了
        if self.assetWriterAudioInput == nil{
            self.assetWriterAudioInput = self.getNewAssetWriterAudioInput();
        }
        guard let assetWriterTemp = self.assetWriter, let audioInputWriter = self.assetWriterAudioInput else {return};
        
        if assetWriterTemp.canAdd(audioInputWriter){
            assetWriterTemp.add(audioInputWriter);
        }
        else{
            print("音频写入失败")
        }
        self.isRecording = true;
    }
    /// 结束录制音频
    func stopRecordAudio(){
        if self.isRecording{
            self.isRecording = false;
            guard let assetWriterSome = self.assetWriter else {return}
            
            if self.canWrite && (assetWriterSome.status != .unknown){
                assetWriterSome.finishWriting {[weak self] in
                    guard let delegateTemp = self?.delegate, let this = self else {return}
                    if delegateTemp.responds(to: #selector(SLZAvCaptureToolDelegate.captureTool(captureTool:didFinishRecordingToOutputFileAtURL:error:))){
                        DispatchQueue.main.async {
                            delegateTemp.captureTool?(captureTool: this, didFinishRecordingToOutputFileAtURL: this.outputFileURL, error: this.assetWriter?.error!)
                        }
                    }
                    this.canWrite = false;
                    this.assetWriter = nil;
                    this.assetWriterAudioInput = nil;
                    this.assetWriterVideoInput = nil;
                }
            }
        }
    }
}

// MARK: - private methods
extension SLZAvCaptureTool{
    //获取指定位置的摄像头
    private func getCameraDeviceWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice?{
        if #available(iOS 10.2, *) {
            let dissession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera], mediaType: .video, position: position);
            for device in dissession.devices{
                if device.position == position{
                    return device;
                }
            }
        }
        else{
            for device in AVCaptureDevice.devices(for: .video){
                if device.position == position{
                    return device;
                }
            }
        }
        return nil;
    }
    /// 获取AssetWriterVideoInput
    private func getNewAssetWriterVideoInput() -> AVAssetWriterInput{
        //写入视频大小
        let numPixels = self.videoSize!.width * UIScreen.main.scale * self.videoSize!.height * UIScreen.main.scale;
        //每像素比特
        let bitsPerPixel = 12.0;
        let bitsPerSecond = Int(numPixels * bitsPerPixel);
        // 码率和帧率设置
        let compressionProperties: [String: Any] = [
            AVVideoAverageBitRateKey: bitsPerSecond,
            AVVideoExpectedSourceFrameRateKey: 15,
            AVVideoMaxKeyFrameIntervalKey: 15,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264High40];

        let width = self.videoSize!.width * UIScreen.main.scale;
        let height = self.videoSize!.height * UIScreen.main.scale;
        //视频属性
        self.videoCompressionSettings = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: compressionProperties
        ];
        
        let _assetWriterVideoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: self.videoCompressionSettings);
        //expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
        _assetWriterVideoInput.expectsMediaDataInRealTime = true;
        
        return _assetWriterVideoInput;
    }
    
    /// 获取AssetWriterAudioInput
    private func getNewAssetWriterAudioInput() -> AVAssetWriterInput{
        self.audioCompressionSettings = [
            AVEncoderBitRatePerChannelKey: 28000,
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 22050
        ];
        
        let _assetWriterAudioInput = AVAssetWriterInput.init(mediaType: .audio, outputSettings: self.audioCompressionSettings);
        _assetWriterAudioInput.expectsMediaDataInRealTime = true;
        return _assetWriterAudioInput;
    }
}

extension SLZAvCaptureTool{
    ///开始监听设备方向
    private func startUpdateDeviceDirection() {
        guard let motionManager = self.motionManager else {return};
        
        if motionManager.isAccelerometerAvailable {
            //回调会一直调用,建议获取到就调用下面的停止方法，需要再重新开始，当然如果需求是实时不间断的话可以等离开页面之后再stop
            motionManager.accelerometerUpdateInterval = 1.0;
            
            motionManager.startAccelerometerUpdates(to: OperationQueue.current ?? OperationQueue.main) {[weak self] accelerometerData, error in
                if let accelerometerDataInternal = accelerometerData{
                    let x = accelerometerDataInternal.acceleration.x;
                    let y = accelerometerDataInternal.acceleration.y;
                    
                    if ((fabs(y) + 0.1) >= fabs(x)) {
                        if (y >= 0.1) {
                            //                    NSLog(@"Down");
                            if (self?.shootingOrientation == .portraitUpsideDown) {
                                return ;
                            }
                            self?.shootingOrientation = .portraitUpsideDown;
                        } else {
                            //                    NSLog(@"Portrait");
                            if (self?.shootingOrientation == .portrait) {
                                return ;
                            }
                            self?.shootingOrientation = .portrait;
                        }
                    } else {
                        if (x >= 0.1) {
                            //                    NSLog(@"Right");
                            if (self?.shootingOrientation == .landscapeRight) {
                                return ;
                            }
                            self?.shootingOrientation = .landscapeRight;
                        } else if (x <= 0.1) {
                            //                    NSLog(@"Left");
                            if (self?.shootingOrientation == .landscapeLeft) {
                                return ;
                            }
                            self?.shootingOrientation = .landscapeLeft;
                        } else  {
                            //                    NSLog(@"Portrait");
                            if (self?.shootingOrientation == .portrait) {
                                return ;
                            }
                            self?.shootingOrientation = .portrait;
                        }
                    }
                }
            }
        }
    }
    /// 停止监测方向
    private func stopUpdateDeviceDirection(){
        if let motionManager = self.motionManager{
            if motionManager.isAccelerometerActive{
                motionManager.stopAccelerometerUpdates();
                self.motionManager = nil;
            }
        }
    }
}

extension SLZAvCaptureTool{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation();
        let image = UIImage.init(data: imageData!);
        if let delegateNew = self.delegate, let imageNew = image{
            if delegateNew.responds(to: #selector(SLZAvCaptureToolDelegate.captureTool(captureTool:didOutputPhoto:error:))){
                delegateNew.captureTool?(captureTool: self, didOutputPhoto: imageNew, error: error)
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !self.isRecording{
            return;
        }
        if output == self.videoDataOutput{
            if let delegateNew = self.delegate{
                if delegateNew.responds(to: #selector(SLZAvCaptureToolDelegate.captureTool(captureTool:didOutputVideoSampleBuffer:fromConnection:))){
                    delegateNew.captureTool?(captureTool: self, didOutputVideoSampleBuffer: sampleBuffer, fromConnection: connection);
                }
            }
            self.writerVideoSampleBuffer(sampleBuffer, fromConnection: connection);
        }
        else if output == self.audioDataOutput{
            if let delegateNew = self.delegate{
                if delegateNew.responds(to: #selector(SLZAvCaptureToolDelegate.captureTool(captureTool:didOutputAudioSampleBuffer:fromConnection:))){
                    delegateNew.captureTool?(captureTool: self, didOutputAudioSampleBuffer: sampleBuffer, fromConnection: connection);
                }
            }
            self.writerAudioSampleBuffer(sampleBuffer, fromConnection: connection);
        }
    }
    
    private func writerVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromConnection connection: AVCaptureConnection){
        if !self.canWrite && (self.avCaptureType == .SLZAvCaptureTypeAv || self.avCaptureType == .SLZAvCaptureTypeVideo){
            self.assetWriter?.startWriting();
            self.assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
            self.canWrite = true;
        }
        guard let videoInputWriter = self.assetWriterVideoInput else {return};
        
        if videoInputWriter.isReadyForMoreMediaData{
            let isSuccess = videoInputWriter.append(sampleBuffer);
            if !isSuccess{
                print(self.assetWriter?.error?.localizedDescription as Any);
            }
        }
    }

    private func writerAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromConnection connection: AVCaptureConnection){
        if !self.canWrite && self.avCaptureType == .SLZAvCaptureTypeAudio{
            self.assetWriter?.startWriting();
            self.assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
            self.canWrite = true;
        }
        guard let audioInputWriter = self.assetWriterAudioInput else {return};
        if audioInputWriter.isReadyForMoreMediaData{
            let isSuccess = audioInputWriter.append(sampleBuffer);
            if !isSuccess{
                print(self.assetWriter?.error?.localizedDescription as Any);
            }
        }
    }
}
