//import SwiftUI
//import AVFoundation
//import CoreImage
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
//    @State private var selectedFilter: FilterType = .none
//    
//  
//    
//    var body: some View {
//        ZStack {
//            // 相机预览
//            CameraPreviewView(camera: camera)
//                .edgesIgnoringSafeArea(.all)
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
//                        .fill(Color.white)
//                        .frame(width: 70, height: 70)
//                        .padding()
//                }
//            }
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
//        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
//        camera.preview.frame = view.frame
//        camera.preview.videoGravity = .resizeAspectFill
//        view.layer.addSublayer(camera.preview)
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {}
//}
//
//// 相机模型
//class CameraModel:NSObject, ObservableObject {
//    @Published var isTaken = false
//    
//    var session = AVCaptureSession()
//    var preview: AVCaptureVideoPreviewLayer!
//    
//    private var output = AVCapturePhotoOutput()
//    private var filter: FilterType = .none
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
//            session.commitConfiguration()
//            
//            DispatchQueue.main.async {
//                self.session.startRunning()
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
//}
//
//extension CameraModel:AVCapturePhotoCaptureDelegate {
//    
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        if let imageData = photo.fileDataRepresentation(),
//           let image = UIImage(data: imageData) {
//            // 这里可以处理拍摄的照片，应用滤镜等
//            // 可以将照片保存到相册或进行其他操作
//        }
//    }
//} 
