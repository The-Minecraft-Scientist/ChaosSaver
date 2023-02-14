
import ScreenSaver
import Metal
import MetalKit

//MARK: -
class ChaosSaverView: ScreenSaverView {
    var view: MTKView
    var renderer: Renderer!

    override init?(frame: NSRect, isPreview: Bool) {
        view = MTKView(frame: frame)
        view.colorPixelFormat = .bgra8Unorm
        view.delegate = renderer
        let device = MTLCreateSystemDefaultDevice()!
        super.init(frame: frame, isPreview: isPreview)
        renderer = Renderer(view: view, device: device)
        self.addSubview(view)
    }

    @available(*, unavailable)
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: NSRect) {
        renderer.draw(in: view)
    }

    override func animateOneFrame() {
        super.animateOneFrame()
        setNeedsDisplay(bounds)
    }

}
