import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["canvas", "image", "pointsContainer", "zoomInButton", "zoomOutButton"]

    MIN_ZOOM = 1
    MAX_ZOOM = 4
    DRAG_THRESHOLD = 5

    connect() {
        this.zoom = this.MIN_ZOOM
        this.isDragging = false
        this.animationFrameId = null
        this.velocity = { x: 0, y: 0 }
        this.currentTranslate = { x: 0, y: 0 }
        this.initialTranslate = { x: 0, y: 0 }
        this.startPos = { x: 0, y: 0 }
        this.element.style.cursor = 'crosshair'
        this.updateButtonStates()
    }

    disconnect() {
        if (this.animationFrameId) cancelAnimationFrame(this.animationFrameId)
    }

    zoomIn() { this.setZoom(this.zoom + 0.5) }
    zoomOut() { this.setZoom(this.zoom - 0.5) }

    setZoom(newZoom) {
        const clampedZoom = Math.max(this.MIN_ZOOM, Math.min(newZoom, this.MAX_ZOOM))
        if (clampedZoom === this.zoom) return
        this.zoom = clampedZoom
        this.currentTranslate = this.getClampedTranslate(this.currentTranslate, 0)
        this.updateTransform(true, this.currentTranslate)
    }

    startDrag(event) {
        if (this.animationFrameId) cancelAnimationFrame(this.animationFrameId)
        event.preventDefault()
        this.isDragging = true
        this.velocity = { x: 0, y: 0 }
        this.startPos = { x: event.clientX, y: event.clientY }
        this.initialTranslate = { ...this.currentTranslate }
        this.lastTimestamp = performance.now()
        this.element.style.cursor = 'grabbing'
        this.canvasTarget.style.transition = "none"
    }

    drag(event) {
        if (!this.isDragging) return
        event.preventDefault()

        const dx = event.clientX - this.startPos.x
        const dy = event.clientY - this.startPos.y
        let nextTranslate = { x: this.initialTranslate.x + dx, y: this.initialTranslate.y + dy }

        const clamped = this.getClampedTranslate(nextTranslate, 100)
        const overshootX = nextTranslate.x - clamped.x
        const overshootY = nextTranslate.y - clamped.y

        const RESISTANCE = 0.6
        nextTranslate.x = clamped.x + overshootX * RESISTANCE
        nextTranslate.y = clamped.y + overshootY * RESISTANCE

        const now = performance.now()
        const elapsed = now - this.lastTimestamp
        if (elapsed > 1) {
            this.velocity = {
                x: (nextTranslate.x - this.currentTranslate.x) / elapsed,
                y: (nextTranslate.y - this.currentTranslate.y) / elapsed,
            }
        }
        this.updateTransform(false, nextTranslate)
        this.currentTranslate = nextTranslate
        this.lastTimestamp = now
    }

    endDrag(event) {
        if (!this.isDragging) return
        this.isDragging = false
        this.element.style.cursor = 'crosshair'
        const totalDist = Math.hypot(event.clientX - this.startPos.x, event.clientY - this.startPos.y)

        if (totalDist < this.DRAG_THRESHOLD) {
            this.plot(event)
        } else {
            this.startInertia()
        }
    }

    startInertia() {
        const FRICTION = 0.94
        const PULL_FACTOR = 0.35

        const inertiaLoop = () => {
            this.currentTranslate.x += this.velocity.x * 16
            this.currentTranslate.y += this.velocity.y * 16
            this.velocity.x *= FRICTION
            this.velocity.y *= FRICTION

            const clamped = this.getClampedTranslate(this.currentTranslate, 0)
            const overshootX = this.currentTranslate.x - clamped.x
            const overshootY = this.currentTranslate.y - clamped.y

            const isOutOfBounds = Math.abs(overshootX) > 0.1 || Math.abs(overshootY) > 0.1
            if (isOutOfBounds) {
                this.currentTranslate.x -= overshootX * PULL_FACTOR
                this.currentTranslate.y -= overshootY * PULL_FACTOR
            }

            const isStill = Math.hypot(this.velocity.x, this.velocity.y) < 0.05
            if (isStill && !isOutOfBounds) {
                this.animationFrameId = null
                this.currentTranslate = clamped
                this.updateTransform(false, this.currentTranslate)
                return
            }

            this.updateTransform(false, this.currentTranslate)
            this.animationFrameId = requestAnimationFrame(inertiaLoop)
        }
        this.animationFrameId = requestAnimationFrame(inertiaLoop)
    }

    plot(event) {
        const imageRect = this.imageTarget.getBoundingClientRect()
        const xPercent = ((event.clientX - imageRect.left) / imageRect.width) * 100
        const yPercent = ((event.clientY - imageRect.top) / imageRect.height) * 100

        if (xPercent < 0 || xPercent > 100 || yPercent < 0 || yPercent > 100) return
        console.log({ x: xPercent.toFixed(2), y: yPercent.toFixed(2) })

        const point = document.createElement("div")
        point.className = "absolute w-3 h-3 bg-red-500 rounded-full border-2 border-white -translate-x-1/2 -translate-y-1/2 pointer-events-none"
        point.style.left = `${xPercent}%`
        point.style.top = `${yPercent}%`
        this.pointsContainerTarget.appendChild(point)
    }

    getClampedTranslate(translate, tolerance = 0) {
        const containerRect = this.element.getBoundingClientRect()
        const scaledWidth = this.canvasTarget.offsetWidth * this.zoom
        const scaledHeight = this.canvasTarget.offsetHeight * this.zoom
        const pannableX = Math.max(0, (scaledWidth - containerRect.width) / 2)
        const pannableY = Math.max(0, (scaledHeight - containerRect.height) / 2)

        return {
            x: Math.max(-pannableX - tolerance, Math.min(translate.x, pannableX + tolerance)),
            y: Math.max(-pannableY - tolerance, Math.min(translate.y, pannableY + tolerance)),
        }
    }

    updateTransform(useTransition, translate) {
        this.canvasTarget.style.transition = useTransition ? "transform 0.2s cubic-bezier(0.25, 1, 0.5, 1)" : "none"
        this.canvasTarget.style.transform = `translate(${translate.x}px, ${translate.y}px) scale(${this.zoom})`
        if (useTransition) this.updateButtonStates()
    }

    updateButtonStates() {
        this.zoomInButtonTarget.disabled = this.zoom >= this.MAX_ZOOM
        this.zoomOutButtonTarget.disabled = this.zoom <= this.MIN_ZOOM
    }
}