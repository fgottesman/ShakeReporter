import SwiftUI
import PencilKit

/// View for annotating screenshots with drawing tools
@available(iOS 16.0, *)
public struct ScreenshotAnnotationView: View {
    @Environment(\.dismiss) private var dismiss
    
    let image: UIImage
    let onSave: (UIImage) -> Void
    
    @State private var canvasView = PKCanvasView()
    @State private var selectedColor: Color = .red
    @State private var strokeWidth: CGFloat = 5.0
    
    private let availableColors: [Color] = [.red, .yellow, .green, .blue, .black]
    
    public init(image: UIImage, onSave: @escaping (UIImage) -> Void) {
        self.image = image
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                GeometryReader { geometry in
                    let imageSize = calculateImageSize(in: geometry.size)
                    
                    ZStack {
                        // Background image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageSize.width, height: imageSize.height)
                        
                        // Drawing canvas overlay
                        CanvasViewRepresentable(
                            canvasView: $canvasView,
                            strokeColor: selectedColor,
                            strokeWidth: strokeWidth
                        )
                        .frame(width: imageSize.width, height: imageSize.height)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Annotate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    // Color picker
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                    updateToolPicker()
                                }
                        }
                        
                        Divider()
                            .frame(height: 24)
                        
                        // Clear button
                        Button {
                            canvasView.drawing = PKDrawing()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let annotatedImage = renderAnnotatedImage()
                        onSave(annotatedImage)
                        dismiss()
                    }
                }
            })
        }
    }
    
    private func calculateImageSize(in containerSize: CGSize) -> CGSize {
        let imageRatio = image.size.width / image.size.height
        let containerRatio = containerSize.width / containerSize.height
        
        if imageRatio > containerRatio {
            // Image is wider than container
            let width = containerSize.width
            let height = width / imageRatio
            return CGSize(width: width, height: height)
        } else {
            // Image is taller than container
            let height = containerSize.height
            let width = height * imageRatio
            return CGSize(width: width, height: height)
        }
    }
    
    private func updateToolPicker() {
        let ink = PKInkingTool(.pen, color: UIColor(selectedColor), width: strokeWidth)
        canvasView.tool = ink
    }
    
    private func renderAnnotatedImage() -> UIImage {
        // Calculate the scale to match the original image size
        let canvasSize = canvasView.bounds.size
        let scale = image.size.width / canvasSize.width
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            // Draw canvas content scaled to match
            context.cgContext.scaleBy(x: scale, y: scale)
            canvasView.drawing.image(from: canvasView.bounds, scale: 1.0)
                .draw(in: canvasView.bounds)
        }
    }
}

/// UIViewRepresentable wrapper for PKCanvasView
@available(iOS 16.0, *)
struct CanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let strokeColor: Color
    let strokeWidth: CGFloat
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        
        // Set initial tool
        let ink = PKInkingTool(.pen, color: UIColor(strokeColor), width: strokeWidth)
        canvasView.tool = ink
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        let ink = PKInkingTool(.pen, color: UIColor(strokeColor), width: strokeWidth)
        uiView.tool = ink
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ScreenshotAnnotationView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenshotAnnotationView(
            image: UIImage(systemName: "photo")!,
            onSave: { _ in }
        )
    }
}
#endif
