import Foundation
import Metal
import MetalKit

class MetalView: NSView {

    var time: Float = 0
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var commandQueue: MTLCommandQueue!
    var vertexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!

    var indexBuffer: MTLBuffer!
    var indices: [UInt16]!

    var pointCount: Int = 0

    // Матрица поворота для uniform буфера
    var rotationMatrix = matrix_float4x4(1)

    var rotationX: Float = 0
    var rotationY: Float = 0
    var lastMouseLocation: NSPoint?

    var cursorPosition: SIMD2<Float> = SIMD2<Float>(0, 0)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        device = MTLCreateSystemDefaultDevice()
        setupMetal()
        setupBuffers()
        startRendering()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        device = MTLCreateSystemDefaultDevice()
        setupMetal()
        setupBuffers()
        startRendering()
    }

    override var acceptsFirstResponder: Bool { true }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
        window?.makeFirstResponder(self)
    }

    func setupMetal() {
        wantsLayer = true
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = bounds
        layer = metalLayer

        commandQueue = device.makeCommandQueue()

        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_main")!
        let fragmentFunction = library.makeFunction(name: "fragment_main")!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }



    func setupBuffers() {
        let N = 10 // Количество точек по оси
        let min: Float = -0.7
        let max: Float = 0.7
        let step = (max - min) / Float(N - 1)

        var points: [SIMD3<Float>] = []
        for x in 0..<N {
            for y in 0..<N {
                for z in 0..<N {
                    let px = min + Float(x) * step
                    let py = min + Float(y) * step
                    let pz = min + Float(z) * step
                    points.append(SIMD3(px, py, pz))
                }
            }
        }
        vertexBuffer = device.makeBuffer(bytes: points,
                                         length: MemoryLayout<SIMD3<Float>>.stride * points.count,
                                         options: [])
        uniformBuffer = device.makeBuffer(length: MemoryLayout<matrix_float4x4>.stride,
                                          options: [])
        self.pointCount = points.count
    }

    func startRendering() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.render()
        }
    }

    override func layout() {
        super.layout()
        metalLayer.frame = bounds
    }

    override func mouseDown(with event: NSEvent) {
        lastMouseLocation = event.locationInWindow
    }

    override func mouseMoved(with event: NSEvent) {
        print("mouseMoved!")
        let location = convert(event.locationInWindow, from: nil)
        let x = Float((location.x / self.bounds.width) * 2 - 1)
        let y = Float((location.y / self.bounds.height) * 2 - 1)
        cursorPosition = SIMD2<Float>(x, y)
        print("mouseMoved: \(cursorPosition)")
    }

    override func mouseDragged(with event: NSEvent) {
        guard let last = lastMouseLocation else { return }
        let newLocation = event.locationInWindow
        let dx = Float(newLocation.x - last.x)
        let dy = Float(newLocation.y - last.y)
        // Инверсия мыши: меняем знаки
        rotationY -= dx * 0.01
        rotationX -= dy * 0.01
        lastMouseLocation = newLocation
        let location = convert(event.locationInWindow, from: nil)
        let x = Float((location.x / self.bounds.width) * 2 - 1)
        let y = Float((location.y / self.bounds.height) * 2 - 1)
        cursorPosition = SIMD2<Float>(x, y)
    }

    func render() {
        guard let drawable = metalLayer.nextDrawable() else { return }
        

        // Обновляем матрицу поворота (пример: вращение вокруг оси Y)
        let aspect = Float(self.frame.width / self.frame.height)
        let perspective = matrix_float4x4_perspective(fovyRadians: .pi/3, aspect: aspect, nearZ: 0.1, farZ: 100)
        let rotationYMatrix = matrix_float4x4_rotation(angle: rotationY, axis: SIMD3<Float>(0,1,0))
        let rotationXMatrix = matrix_float4x4_rotation(angle: rotationX, axis: SIMD3<Float>(1,0,0))
        let translation = matrix_float4x4(columns: (
            SIMD4<Float>(1,0,0,0),
            SIMD4<Float>(0,1,0,0),
            SIMD4<Float>(0,0,1,0),
            SIMD4<Float>(0,0,-3,1)
        ))
        rotationMatrix = perspective * translation * rotationYMatrix * rotationXMatrix

        // Обновляем uniform буфер с матрицей поворота
        let bufferPointer = uniformBuffer.contents()
        memcpy(bufferPointer, &rotationMatrix, MemoryLayout<matrix_float4x4>.stride)

        // Создаем descriptor для рендера
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        guard
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }

        // Пока тут можно добавить код настройки pipeline и шейдеров

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        var cursor = cursorPosition
        encoder.setVertexBytes(&cursor, length: MemoryLayout<SIMD2<Float>>.stride, index: 2)
        // Оставляю только отрисовку точек
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: pointCount)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// Вспомогательная функция создания матрицы поворота
func matrix_float4x4_rotation(angle: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let c = cos(angle)
    let s = sin(angle)
    let ci = 1 - c
    let x = axis.x, y = axis.y, z = axis.z

    return matrix_float4x4(columns: (
        SIMD4<Float>(c + x*x*ci,     x*y*ci - z*s,  x*z*ci + y*s,  0),
        SIMD4<Float>(y*x*ci + z*s,   c + y*y*ci,    y*z*ci - x*s,  0),
        SIMD4<Float>(z*x*ci - y*s,   z*y*ci + x*s,  c + z*z*ci,    0),
        SIMD4<Float>(0,              0,             0,             1)
    ))
}

func matrix_float4x4_perspective(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let y = 1 / tan(fovyRadians * 0.5)
    let x = y / aspect
    let z = farZ / (nearZ - farZ)
    return matrix_float4x4(columns: (
        SIMD4<Float>( x,  0,  0,   0),
        SIMD4<Float>( 0,  y,  0,   0),
        SIMD4<Float>( 0,  0,  z,  -1),
        SIMD4<Float>( 0,  0,  z * nearZ,  0)
    ))
}
