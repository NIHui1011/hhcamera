import SwiftUI
import AVFoundation
import GPUImage
import Photos

enum FilterType: String, CaseIterable {
    case none = "原始"
    case sepia = "复古"
    case mono = "黑白"
    case vibrant = "鲜艳"
    case sketch = "素描"
    case classicNeg = "富士CN"
    case acros = "富士AC"
}

struct ContentView: View {
    @StateObject private var camera = GPUImageCameraModel()
    @State private var selectedFilter: FilterType = .none
    
    var body: some View {
        ZStack {
            // GPU Image 相机预览
            GPUImagePreviewView(camera: camera)
                .edgesIgnoringSafeArea(.all)
                .background(Color.black)
            
            VStack {
                Spacer()
                
                // 滤镜选择器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                                camera.applyFilter(filter)
                            }) {
                                Text(filter.rawValue)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(selectedFilter == filter ? Color.blue : Color.black.opacity(0.6))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.3))
                
                // 拍照按钮
                Button(action: {
                    camera.capturePhoto()
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .padding()
                }
            }
        }
        .alert("错误", isPresented: $camera.alertError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(camera.alertMessage)
        }
        .alert("保存成功", isPresented: $camera.showSuccessAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("照片已保存到相册")
        }
    }
}

// GPUImage 相机预览视图
struct GPUImagePreviewView: UIViewRepresentable {
    @ObservedObject var camera: GPUImageCameraModel
    
    func makeUIView(context: Context) -> RenderView {
        let view = RenderView(frame: UIScreen.main.bounds)
        view.contentMode = .scaleAspectFill
        view.backgroundColor = .black
        camera.setupCamera(with: view)
        return view
    }
    
    func updateUIView(_ uiView: RenderView, context: Context) {
        uiView.frame = UIScreen.main.bounds
    }
}

class GPUImageCameraModel: ObservableObject {
    @Published var alertError = false
    @Published var alertMessage = ""
    @Published var showSuccessAlert = false
    
    private var camera: Camera!
    private var currentFilter: FilterType = .none
    private var metalView: RenderView?
    
    // 滤镜
    private var sepiaFilter: SepiaToneFilter!
    private var monoFilter: MonochromeFilter!
    private var vibrantFilter: SaturationAdjustment!
    private var sketchFilter: SketchFilter!
    private var classicNegFilter: ColorMatrixFilter!
    
    // 修改 ACROS 滤镜相关属性
    private var acrosFilter: ColorMatrixFilter!
    
    func setupCamera(with view: RenderView) {
        do {
            camera = try Camera(sessionPreset: .photo)
            //TODO： 跟随屏幕旋转
            camera.orientation = .landscapeRight
            
            
            metalView = view
            
            // 初始化滤镜
            sepiaFilter = SepiaToneFilter()
            monoFilter = MonochromeFilter()
            vibrantFilter = SaturationAdjustment()
            sketchFilter = SketchFilter()
            classicNegFilter = ColorMatrixFilter()
            
            // 设置颜色矩阵来模拟 Classic Neg 效果
            // 这些值是经过调试得到的近似值
            let colorMatrix: Matrix4x4 = Matrix4x4(
                rowMajorValues: [
                    1.1, -0.1, 0.05, 0.0,     // R
                    0.0, 1.0, 0.05, 0.0,      // G
                    -0.1, -0.05, 1.1, 0.0,    // B
                    0.0, 0.0, 0.0, 1.0        // A
                ]
            )
            classicNegFilter.colorMatrix = colorMatrix
            
            // 预先设置所有滤镜的参数
            sepiaFilter.intensity = 0.8
            monoFilter.intensity = 1.0
            monoFilter.color = Color(red: 0.6, green: 0.45, blue: 0.3, alpha: 1.0)
            vibrantFilter.saturation = 1.8
            
            // 初始化 ACROS 滤镜
            acrosFilter = ColorMatrixFilter()
            
            // 设置 ACROS 的颜色矩阵 - 调整后的矩阵以获得更好的黑白效果
            let acrosMatrix = Matrix4x4(
                rowMajorValues: [
                    0.35, 0.48, 0.07, 0.0,    // R - 调整红色通道权重
                    0.35, 0.48, 0.07, 0.0,    // G - 增加绿色通道权重
                    0.35, 0.48, 0.07, 0.0,    // B - 降低蓝色通道权重
                    0.0, -0.1, 0.0, 1.1       // A - 增加对比度
                ]
            )
            acrosFilter.colorMatrix = acrosMatrix
            
            // 设置默认输出
            camera --> metalView!
            
            DispatchQueue.global().async { [weak self] in
                self?.camera.startCapture()
            }
           
            
        } catch {
            alertError = true
            alertMessage = "相机初始化失败：\(error.localizedDescription)"
        }
    }
    
    func applyFilter(_ filter: FilterType) {
        guard let metalView = metalView else { return }
        
        // 停止捕获
//        camera.stopCapture()
        
        // 断开所有连接
        camera.removeAllTargets()
        sepiaFilter.removeAllTargets()
        monoFilter.removeAllTargets()
        vibrantFilter.removeAllTargets()
        sketchFilter.removeAllTargets()
        classicNegFilter.removeAllTargets()
        acrosFilter.removeAllTargets()  // 添加新滤镜的断开连接
        
        // 根据选择的滤镜类型设置新的连接
        switch filter {
        case .none:
            camera --> metalView
            
        case .sepia:
            camera --> sepiaFilter --> metalView
            
        case .mono:
            camera --> monoFilter --> metalView
            
        case .vibrant:
            camera --> vibrantFilter --> metalView
            
        case .sketch:
            camera --> sketchFilter --> metalView
        case .classicNeg:
            camera --> classicNegFilter --> metalView
        case .acros:
            camera --> acrosFilter --> metalView
        }
        
        currentFilter = filter
        
        // 重新开始捕获
//        camera.startCapture()
    }
    
    func capturePhoto() {
        guard let metalView = metalView else { return }
        
        // 创建图片输出对象
        let pictureOutput = PictureOutput()
        
        // 配置输出格式和回调
        pictureOutput.encodedImageFormat = .jpeg
        pictureOutput.imageAvailableCallback = { [weak self] image in
            guard let self = self else { return }
            
            // 保存照片到相册
           DispatchQueue.main.async {
                self.savePhoto(image)
           }
            
            // 恢复预览
//            DispatchQueue.main.async {
//                self.restorePreview()
//            }
        }
        
        // 断开所有现有连接
        camera.removeAllTargets()
        sepiaFilter.removeAllTargets()
        monoFilter.removeAllTargets()
        vibrantFilter.removeAllTargets()
        sketchFilter.removeAllTargets()
        classicNegFilter.removeAllTargets()
        acrosFilter.removeAllTargets()  // 添加新滤镜的断开连接
        
        // 根据当前滤镜设置拍照管道
        switch currentFilter {
        case .none:
            camera --> pictureOutput
        case .sepia:
            camera --> sepiaFilter --> pictureOutput
        case .mono:
            camera --> monoFilter --> pictureOutput
        case .vibrant:
            camera --> vibrantFilter --> pictureOutput
        case .sketch:
            camera --> sketchFilter --> pictureOutput
        case .classicNeg:
            camera --> classicNegFilter --> pictureOutput
        case .acros:
            camera --> acrosFilter --> pictureOutput
        }
        
        // 获取临时文件路径用于保存照片
        let tempDirPath = NSTemporaryDirectory()
        let filePath = (tempDirPath as NSString).appendingPathComponent("temp_photo.jpg")
        let fileURL = URL(fileURLWithPath: filePath)
        
        // 保存下一帧到文件
        pictureOutput.saveNextFrameToURL(fileURL, format: .jpeg)
        
        // 暂停捕获
//        camera.stopCapture()
        
        // 短暂延迟后恢复预览
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.restorePreview()
        }
    }
    
    private func restorePreview() {
//        camera.stopCapture()
        // 断开所有连接
        camera.removeAllTargets()
        sepiaFilter.removeAllTargets()
        monoFilter.removeAllTargets()
        vibrantFilter.removeAllTargets()
        sketchFilter.removeAllTargets()
        classicNegFilter.removeAllTargets()
        acrosFilter.removeAllTargets()  // 添加新滤镜的断开连接
        
        // 重新应用当前滤镜恢复预览
        guard let metalView = metalView else { return }
        
        switch currentFilter {
        case .none:
            camera --> metalView
        case .sepia:
            camera --> sepiaFilter --> metalView
        case .mono:
            camera --> monoFilter --> metalView
        case .vibrant:
            camera --> vibrantFilter --> metalView
        case .sketch:
            camera --> sketchFilter --> metalView
        case .classicNeg:
            camera --> classicNegFilter --> metalView
        case .acros:
            camera --> acrosFilter --> metalView
        default:
            // 其他现有的 case 保持不变...
            break
        }
        
        // 重新开始捕获
//        camera.startCapture()
    }
    
    private func savePhoto(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    // 创建一个图片资源请求
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self.showSuccessAlert = true
                        } else {
                            self.alertError = true
                            self.alertMessage = "保存失败：\(error?.localizedDescription ?? "未知错误")"
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.alertError = true
                    self.alertMessage = "没有相册访问权限"
                }
            }
        }
    }
    
    deinit {
        camera.stopCapture()
        camera.removeAllTargets()
        sepiaFilter.removeAllTargets()
        monoFilter.removeAllTargets()
        vibrantFilter.removeAllTargets()
        sketchFilter.removeAllTargets()
        classicNegFilter.removeAllTargets()
        acrosFilter.removeAllTargets()  // 添加新滤镜的清理
    }
}

