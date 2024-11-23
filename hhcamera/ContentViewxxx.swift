//import SwiftUI
//import AVFoundation
//import CoreImage
//import GPUImage
//
//
//
//enum FilterType: String, CaseIterable {
//    case none = "原始"
//    case sepia = "复古"
//    case mono = "黑白"
//    case vibrant = "鲜艳"
//}
//
//struct ContentView: View {
//    @StateObject private var camera = CameraModel()
//    @State private var selectedFilter: FilterType = .mono
//    
//    
//    
//    var body: some View {
//        ZStack {
//            // 相机预览
//            
//            
//            CameraPreviewView(camera: camera)
//                .padding(EdgeInsets.init(top: 44, leading: 16, bottom: 44, trailing: 16))
//                .edgesIgnoringSafeArea(.all)
//            
//            
//            VStack {
//                Spacer()
//                
//                // 滤镜选择器
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 20) {
//                        ForEach(FilterType.allCases, id: \.self) { filter in
//                            Button(action: {
//                                selectedFilter = filter
//                                camera.applyFilter(filter)
//                            }) {
//                                Text(filter.rawValue)
//                                    .foregroundColor(.white)
//                                    .padding(.horizontal, 20)
//                                    .padding(.vertical, 10)
//                                    .background(selectedFilter == filter ? Color.blue : Color.black.opacity(0.6))
//                                    .cornerRadius(10)
//                            }
//                        }
//                    }
//                    .padding()
//                }
//                .background(Color.black.opacity(0.3))
//                
//                // 拍照按钮
//                Button(action: {
//                    camera.capturePhoto()
//                }) {
//                    Circle()
//                        .fill(Color.orange)
//                        .frame(width: 70, height: 70)
//                        .padding()
//                }
//            }
//        }
//        .alert("错误", isPresented: $camera.alertError) {
//            Button("确定", role: .cancel) { }
//        } message: {
//            Text(camera.alertMessage)
//        }
//        .alert("保存成功", isPresented: $camera.showSuccessAlert) {
//            Button("确定", role: .cancel) { }
//        } message: {
//            Text("照片已保存到相册")
//        }.onAppear {
//            
//            //            DispatchQueue.main.asyncAfter(deadline: .now()){
//            //                camera.session.startRunning()
//            //                camera.isReady = true;
//            //            }
//            //
//            
//        }
//    }
//}
//
//// 相机预览视图
//struct CameraPreviewView: UIViewRepresentable {
//    @ObservedObject var camera: CameraModel
//    
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: UIScreen.main.bounds)
//        view.backgroundColor = UIColor.gray
//        
////        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
//        camera.preview =  AVCaptureVideoPreviewLayer()
//        camera.preview.frame = view.frame
//        camera.preview.videoGravity = .resizeAspectFill
//        view.layer.addSublayer(camera.preview)
//        
//        
//        //        let l  = CALayer.init()
//        //        l.frame = camera.preview.bounds
//        //        l.backgroundColor = CGColor.init(red: 255, green: 0, blue: 0, alpha: 0.5)
//        //        view.layer.addSublayer(l)
//        
////        let imageView = UIImageView()
////        imageView.frame = camera.preview.bounds;
////        imageView.backgroundColor = UIColor.yellow;
////        view.addSubview(imageView)
////        camera.previewImageView  = imageView
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        camera.preview.frame = uiView.frame
//        camera.displayLayer?.frame = uiView.frame
//    }
//}
//
//// 相机模型
//class CameraModel:NSObject, ObservableObject {
//    @Published var isTaken = false
//    @Published var alertError = false
//    @Published var alertMessage = ""
//    @Published var showSuccessAlert = false
//    @Published var isReady = false
//    
//    var session = AVCaptureSession()
//    var preview: AVCaptureVideoPreviewLayer!
//    
////    var previewImageView: UIImageView?
//    
//    private var output = AVCapturePhotoOutput()
//    private var filter: FilterType = .mono
//    
//    private let context = CIContext()
//    
//    private var videoOutput = AVCaptureVideoDataOutput()
//    var displayLayer: AVSampleBufferDisplayLayer?
//    
//    override init() {
//        super.init()
//        checkPermission()
//    }
//    
//    func checkPermission() {
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .authorized:
//            setupCamera()
//        case .notDetermined:
//            AVCaptureDevice.requestAccess(for: .video) { status in
//                if status {
//                    self.setupCamera()
//                }
//            }
//        default:
//            break
//        }
//    }
//    
//    func setupCamera() {
//        do {
//            session.beginConfiguration()
//            
//            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
//            let input = try AVCaptureDeviceInput(device: device)
//            
//            if session.canAddInput(input) {
//                session.addInput(input)
//            }
//            
//            if session.canAddOutput(output) {
//                session.addOutput(output)
//            }
//            
//            if session.canAddOutput(videoOutput) {
//                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//                session.addOutput(videoOutput)
//            }
//            
//            session.commitConfiguration()
//            
//            
//            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
//                self?.session.startRunning()
//                self?.isReady = true;
//            }
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
//    
//    func applyFilter(_ filterType: FilterType) {
//        self.filter = filterType
//    }
//    
//    func capturePhoto() {
//        let settings = AVCapturePhotoSettings()
//        output.capturePhoto(with: settings, delegate: self)
//    }
//    
//    private func savePhoto(_ image: UIImage) {
//        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
//    }
//    
//    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
//        DispatchQueue.main.async {
//            if let error = error {
//                self.alertError = true
//                self.alertMessage = "保存失败：\(error.localizedDescription)"
//            } else {
//                self.showSuccessAlert = true
//            }
//        }
//    }
//    
//    private func applyFilterToImage(_ image: UIImage, filter: FilterType) -> UIImage? {
//        guard let ciImage = CIImage(image: image) else { return nil }
//        
//        var filteredImage: CIImage?
//        
//        switch filter {
//        case .none:
//            return image
//            
//        case .sepia:
//            guard let sepiaFilter = CIFilter(name: "CISepiaTone") else { return nil }
//            sepiaFilter.setValue(ciImage, forKey: kCIInputImageKey)
//            sepiaFilter.setValue(0.8, forKey: kCIInputIntensityKey)
//            filteredImage = sepiaFilter.outputImage
//            
//        case .mono:
//            guard let monoFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
//            monoFilter.setValue(ciImage, forKey: kCIInputImageKey)
//            filteredImage = monoFilter.outputImage
//            
//        case .vibrant:
//            guard let vibrantFilter = CIFilter(name: "CIVibrance") else { return nil }
//            vibrantFilter.setValue(ciImage, forKey: kCIInputImageKey)
//            vibrantFilter.setValue(1.5, forKey: kCIInputAmountKey)
//            filteredImage = vibrantFilter.outputImage
//        }
//        
//        guard let outputImage = filteredImage,
//              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
//            return nil
//        }
//        
//        return UIImage(cgImage: cgImage)
//    }
//    
//    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
//        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
//        
//        var filteredImage: CIImage?
//        
//        switch filter {
//        case .none:
//            return sampleBuffer
//            
//        case .sepia:
//            guard let sepiaFilter = CIFilter(name: "CISepiaTone") else { return nil }
//            sepiaFilter.setValue(ciImage, forKey: kCIInputImageKey)
//            sepiaFilter.setValue(0.8, forKey: kCIInputIntensityKey)
//            filteredImage = sepiaFilter.outputImage
//            
//        case .mono:
//            guard let monoFilter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
//            monoFilter.setValue(ciImage, forKey: kCIInputImageKey)
//            filteredImage = monoFilter.outputImage
//            
//        case .vibrant:
//            guard let vibrantFilter = CIFilter(name: "CIVibrance") else { return nil }
//            vibrantFilter.setValue(ciImage, forKey: kCIInputImageKey)
//            vibrantFilter.setValue(1.5, forKey: kCIInputAmountKey)
//            filteredImage = vibrantFilter.outputImage
//        }
//        
//        guard let outputImage = filteredImage else { return nil }
//        
//        var pixelBuffer: CVPixelBuffer?
//        CVPixelBufferCreate(kCFAllocatorDefault,
//                            Int(outputImage.extent.width),
//                            Int(outputImage.extent.height),
//                            CVPixelBufferGetPixelFormatType(imageBuffer),
//                            nil,
//                            &pixelBuffer)
//        
//        guard let outputPixelBuffer = pixelBuffer else { return nil }
//        context.render(outputImage, to: outputPixelBuffer)
//        
//        var timing = CMSampleTimingInfo()
//        var formatDescription: CMFormatDescription?
//        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
//                                                     imageBuffer: outputPixelBuffer,
//                                                     formatDescriptionOut: &formatDescription)
//        
//        var outputSampleBuffer: CMSampleBuffer?
//        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
//                                                 imageBuffer: outputPixelBuffer,
//                                                 formatDescription: formatDescription!,
//                                                 sampleTiming: &timing,
//                                                 sampleBufferOut: &outputSampleBuffer)
//        
//        return outputSampleBuffer
//    }
//    
//    private func processVideoFrame2(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
//            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
//
//            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//
//            // 创建一个 CIFilter 对象，用于旋转视频帧
//            let transformFilter = CIFilter(name: "CIAffineTransform")!
//            transformFilter.setValue(ciImage, forKey: kCIInputImageKey)
//
//            // 计算旋转角度（顺时针 90 度）
//            let angle = CGFloat.pi / 2
//            let rotationTransform = CGAffineTransform(rotationAngle: angle)
//            transformFilter.setValue(rotationTransform, forKey: kCIInputTransformKey)
//
//            // 获取旋转后的 CIImage
//            guard let rotatedImage = transformFilter.outputImage else { return nil }
//
//            // 将 CIImage 转换为 CGImage
//            let context = CIContext(options: nil)
//            guard let cgImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else { return nil }
//
//            // 创建一个新的 CMSampleBuffer，包含旋转后的视频帧
//            var rotatedSampleBuffer: CMSampleBuffer?
//            let options: [String: Any] = [
//                kCVPixelBufferCGImageCompatibilityKey as String: true,
//                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
//                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
//            ]
////        CVPixelBufferPool.
////        CVPixelBufferPool(pixelBuffer, options:options)
////            let pixelBufferPool = CVPixelBufferPool( pixelBuffer, options: options)
////            pixelBufferPool?.getBuffer(withSize: rotatedImage.extent.size, allocator: kCFAllocatorDefault, outBuffer: &rotatedSampleBuffer)
//
//            if let rotatedSampleBuffer = rotatedSampleBuffer {
//                // 将旋转后的 CGImage 写入新的 CMSampleBuffer
//                CVPixelBufferLockBaseAddress(rotatedSampleBuffer.imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
//                let data = CVPixelBufferGetBaseAddress(rotatedSampleBuffer.imageBuffer!)
//                let context = CGContext(data: data, width: Int(rotatedImage.extent.width), height: Int(rotatedImage.extent.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(rotatedSampleBuffer.imageBuffer!), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
//                context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: rotatedImage.extent.width, height: rotatedImage.extent.height))
//                CVPixelBufferUnlockBaseAddress(rotatedSampleBuffer.imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
//
//                // 将旋转后的 CMSampleBuffer 传递给 AVSampleBufferDisplayLayer
////                sampleBufferDisplayLayer.enqueue(rotatedSampleBuffer)
//                return rotatedSampleBuffer
//            }
//        
//        return nil
//        
//        
//        
//        }
//}
//
//extension CameraModel:AVCapturePhotoCaptureDelegate {
//    
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        if let error = error {
//            DispatchQueue.main.async {
//                self.alertError = true
//                self.alertMessage = "拍照失败：\(error.localizedDescription)"
//            }
//            return
//        }
//        
//        guard let imageData = photo.fileDataRepresentation(),
//              let originalImage = UIImage(data: imageData) else {
//            DispatchQueue.main.async {
//                self.alertError = true
//                self.alertMessage = "照片处理失败"
//            }
//            return
//        }
//        
//        // 应用滤镜
//        if let filteredImage = applyFilterToImage(originalImage, filter: filter) {
//            savePhoto(filteredImage)
//        } else {
//            savePhoto(originalImage)
//        }
//    }
//}
//
//extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
////        guard let processedBuffer = processVideoFrame2(sampleBuffer) else { return }
//        
//       
//        
//        DispatchQueue.main.async {
//            if(self.isReady){
//                if self.displayLayer == nil {
//                    self.displayLayer = AVSampleBufferDisplayLayer()
//                    self.displayLayer?.videoGravity = .resizeAspect
//                    self.displayLayer?.backgroundColor = CGColor.init(red: 0, green: 255, blue: 0, alpha: 0.9)
//                    if let displayLayer = self.displayLayer {
//                        self.preview.insertSublayer(displayLayer, at: 0)
//                    }
//                }
//                
//                self.displayLayer?.frame = self.preview.frame
//                self.displayLayer?.videoGravity = .resizeAspect
//                
//                self.displayLayer?.enqueue(sampleBuffer)
//            }
//        }
//        
//        
//        
//        //        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        //
//        //        // 创建 CIImage
//        //        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        //
//        //        // 应用滤镜效果
//        //        let filter = CIFilter(name: "CISepiaTone")
//        //        filter?.setValue(ciImage, forKey: kCIInputImageKey)
//        //        filter?.setValue(0.5, forKey: kCIInputIntensityKey)
//        //
//        //        // 获取滤镜后的图像
//        //        guard let filteredImage = filter?.outputImage else { return }
//        //
//        //        // 将 CIImage 转换为 CGImage
//        //        let context = CIContext(options: nil)
//        //        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else { return }
//        //
//        //        // 在主线程上更新 UI
//        //        DispatchQueue.main.async {
//        //            self.previewImageView?.image = UIImage(cgImage: cgImage)
//        //
//        //        }
//    }
//}
