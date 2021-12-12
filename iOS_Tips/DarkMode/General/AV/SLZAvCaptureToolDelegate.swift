//
//  SLZAvCaptureToolDelegate.swift
//
//  Created by Zheng Li on 2021/11/9.
//  Copyright © 2021 Zas. All rights reserved.
//  翻译自:  https://github.com/wsl2ls/iOS_Tips/blob/master/iOS_Tips/DarkMode/General/AV/SLAvCaptureTool.h

import UIKit
import CoreMedia
import AVFoundation

@objc protocol SLZAvCaptureToolDelegate: NSObjectProtocol {
    ///  完成拍照 ，返回image
    /// @param image 输出的图片
    /// @param error 错误信息
    @objc optional func captureTool(captureTool: SLZAvCaptureTool, didOutputPhoto image: UIImage?, error: Error?);
    
    ///  完成音视频录制，返回临时文件地址
    /// @param outputFileURL 文件地址
    /// @param error 错误信息
    @objc optional func captureTool(captureTool: SLZAvCaptureTool, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL?, error: Error?);
    
    /// 实时输出采集的音视频样本  提供对外接口 方便自定义处理
    /// @param captureTool captureTool
    /// @param sampleBuffer 样本缓冲
    /// @param connection 输入和输出之前的连接
    @objc optional func captureTool(captureTool: SLZAvCaptureTool, didOutputVideoSampleBuffer sampleBuffer: CMSampleBuffer, fromConnection connection: AVCaptureConnection);
    
    @objc optional func captureTool(captureTool: SLZAvCaptureTool, didOutputAudioSampleBuffer sampleBuffer: CMSampleBuffer, fromConnection connection: AVCaptureConnection);
    
}
