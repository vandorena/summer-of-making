import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["canvas", "image", "pointsContainer", "zoomInButton", "zoomOutButton", "placeableProjects", "placeableCount", "tooltipTemplate"]
    static values = {
        projects: Array,
        userId: Number,
        updateUrl: String,
        mapPointsUrl: String,
        unplaceUrl: String,
    }

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
        this.draggedPoint = null
        this.selectedProjectId = null
        this.tooltipTimeout = null

        this.renderPoints()
        this.setupProjectSelection()
        this.updatePlaceableInstructions()
    }

    disconnect() {
        if (this.animationFrameId) cancelAnimationFrame(this.animationFrameId)
    }

    renderPoints() {
        this.pointsContainerTarget.innerHTML = ''
        this.projectsValue.forEach(project => {
            const isOwner = project.user_id === this.userIdValue

            const pointWrapper = document.createElement("div");
            pointWrapper.className = "absolute transform -translate-x-1/2 -translate-y-1/2 group";
            pointWrapper.style.left = `${project.x}%`;
            pointWrapper.style.top = `${project.y}%`;
            pointWrapper.dataset.projectId = project.id;

            // Show tooltip on hover
            pointWrapper.addEventListener('mouseenter', () => this.showTooltip(pointWrapper, project));
            pointWrapper.addEventListener('mouseleave', () => this.hideTooltip(pointWrapper));

            const point = document.createElement("div")
            point.className = "w-3 h-3 rounded-full border-2 transition-transform duration-200 group-hover:scale-150"
            point.dataset.projectId = project.id

            const avatar = document.createElement("img");
            avatar.src = project.user.avatar;
            avatar.className = "w-8 h-8 rounded-full border-2 border-white absolute -top-10 left-1/2 transform -translate-x-1/2 transition-all opacity-0 group-hover:opacity-100 group-hover:-translate-y-2 pointer-events-none";

            if (isOwner) {
                point.classList.add("bg-green-500", "border-white", "cursor-grab")
                point.dataset.action = "mousedown->map#startPointDrag"

                const unplaceButton = document.createElement("button");
                unplaceButton.innerHTML = "×";
                unplaceButton.className = "absolute -top-2 -right-2 w-5 h-5 bg-red-500 text-white rounded-full text-xs font-bold opacity-0 group-hover:opacity-50 transition-opacity duration-200 hover:bg-red-600 flex items-center justify-center";
                unplaceButton.title = "Remove from map";
                unplaceButton.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.unplaceProject(project.id);
                });
                pointWrapper.appendChild(unplaceButton);
            } else {
                point.classList.add("bg-red-500", "border-white")
            }

            pointWrapper.appendChild(avatar);
            pointWrapper.appendChild(point);

            this.pointsContainerTarget.appendChild(pointWrapper)
        })
    }

    showTooltip(pointWrapper, project) {
        if (this.tooltipTimeout) {
            clearTimeout(this.tooltipTimeout);
            this.tooltipTimeout = null;
        }

        // don't show tooltip if one already exists!
        if (pointWrapper.querySelector('.absolute.bottom-full')) return;
        const tooltipClone = this.tooltipTemplateTarget.content.cloneNode(true).firstElementChild;

        tooltipClone.querySelector('[data-map-target="tooltipTitle"]').textContent = project.title;
        tooltipClone.querySelector('[data-map-target="tooltipInfo"]').textContent = `${project.devlogs_count} updates • ${project.total_time_spent}`;
        tooltipClone.querySelector('[data-map-target="tooltipLink"]').href = project.project_path;

        tooltipClone.addEventListener('mouseenter', () => {
            if (this.tooltipTimeout) {
                clearTimeout(this.tooltipTimeout);
                this.tooltipTimeout = null;
            }
        });

        tooltipClone.addEventListener('mouseleave', () => {
            this.hideTooltip(pointWrapper);
        });

        pointWrapper.appendChild(tooltipClone);
    }

    hideTooltip(pointWrapper) {
        this.tooltipTimeout = setTimeout(() => {
            const tooltip = pointWrapper.querySelector('.absolute.bottom-full');
            if (tooltip) {
                tooltip.remove();
            }
            this.tooltipTimeout = null;
        }, 100);
    }

    startCardDrag(event) {
        event.dataTransfer.setData("text/plain", event.currentTarget.dataset.projectId);
        event.dataTransfer.effectAllowed = "move";
    }

    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = "move";
    }

    handleDrop(event) {
        event.preventDefault();
        const projectId = event.dataTransfer.getData("text/plain");
        if (!projectId) return;

        const imageRect = this.imageTarget.getBoundingClientRect()
        const xPercent = ((event.clientX - imageRect.left) / imageRect.width) * 100
        const yPercent = ((event.clientY - imageRect.top) / imageRect.height) * 100

        if (xPercent < 0 || xPercent > 100 || yPercent < 0 || yPercent > 100) return

        this.updateProjectPosition(projectId, xPercent, yPercent);
    }

    async updateProjectPosition(projectId, x, y) {
        const url = this.updateUrlValue.replace(':id', projectId);
        const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
        const csrfToken = csrfTokenMeta ? csrfTokenMeta.content : '';

        try {
            // 1. Make API call to update coordinates
            const response = await fetch(url, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-Token': csrfToken
                },
                body: JSON.stringify({ project: { x, y } })
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.errors ? errorData.errors.join(', ') : 'Failed to update position');
            }

            // 2. After successful update, fetch fresh map data
            await this.fetchFreshMapData();

            // 3. Remove the card from the placeable list if it was placed from there
            if (this.hasPlaceableProjectsTarget) {
                const cardToRemove = this.placeableProjectsTarget.querySelector(`[data-project-id="${projectId}"]`);
                if (cardToRemove) {
                    cardToRemove.remove();
                    this.updatePlaceableInstructions();
                }
            }

        } catch (error) {
            console.error('Failed to update project position:', error);
            alert(`Error: ${error.message}`);
        }
    }

    async fetchFreshMapData() {
        try {
            const response = await fetch('/map/points', {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error('Failed to fetch fresh map data');
            }

            const data = await response.json();

            this.projectsValue = data.projects;

            // re-render all points with confirmed server state
            this.renderPoints();

        } catch (error) {
            console.error('Failed to fetch fresh map data:', error);
            // Fallback: just re-render with current data
            this.renderPoints();
        }
    }

    startDrag(event) {
        if (this.draggedPoint) return
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

    startPointDrag(event) {
        event.stopPropagation();
        event.preventDefault();

        this.draggedPoint = event.target.parentElement;
        this.element.style.cursor = 'grabbing';
        this.draggedPoint.classList.add("z-20");

        const moveHandler = this.dragPoint.bind(this);
        const upHandler = () => {
            this.endPointDrag();
            document.removeEventListener('mousemove', moveHandler);
            document.removeEventListener('mouseup', upHandler);
        };
        document.addEventListener('mousemove', moveHandler);
        document.addEventListener('mouseup', upHandler);
    }

    dragPoint(event) {
        if (!this.draggedPoint) return;

        const imageRect = this.imageTarget.getBoundingClientRect();
        const xPercent = Math.max(0, Math.min(100, ((event.clientX - imageRect.left) / imageRect.width) * 100));
        const yPercent = Math.max(0, Math.min(100, ((event.clientY - imageRect.top) / imageRect.height) * 100));

        this.draggedPoint.style.left = `${xPercent}%`;
        this.draggedPoint.style.top = `${yPercent}%`;
    }

    endPointDrag() {
        if (!this.draggedPoint) return;

        this.draggedPoint.classList.remove("z-20");
        const point = this.draggedPoint.querySelector('[data-project-id]');
        const x = parseFloat(this.draggedPoint.style.left);
        const y = parseFloat(this.draggedPoint.style.top);
        const projectId = point.dataset.projectId;

        this.updateProjectPosition(projectId, x, y);

        this.draggedPoint = null;
        this.element.style.cursor = 'crosshair';
    }

    drag(event) {
        if (this.draggedPoint) return this.dragPoint(event);
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
        if (this.draggedPoint) return this.endPointDrag();
        if (!this.isDragging) return
        this.isDragging = false
        this.element.style.cursor = 'crosshair'
        this.startInertia()
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

    setupProjectSelection() {
        if (this.hasPlaceableProjectsTarget) {
            this.placeableProjectsTarget.addEventListener('click', (event) => {
                const card = event.target.closest('[data-project-id]');
                if (card) {
                    event.preventDefault();
                    event.stopPropagation();
                    this.selectProject(card.dataset.projectId, card);
                }
            });
        }

        this.imageTarget.addEventListener('click', (event) => {
            if (this.selectedProjectId && !this.isDragging && !this.draggedPoint) {
                this.handleMapClick(event);
            }
        });
    }

    selectProject(projectId, cardElement) {
        this.clearProjectSelection();

        this.selectedProjectId = projectId;
        cardElement.classList.add('ring-2', 'ring-blue-500', 'bg-blue-100');

        this.element.style.cursor = 'crosshair';
        this.updatePlaceableInstructions('Click anywhere on the map to place this project, or drag it directly.');
    }

    clearProjectSelection() {
        if (this.hasPlaceableProjectsTarget) {
            const cards = this.placeableProjectsTarget.querySelectorAll('[data-project-id]');
            cards.forEach(card => {
                card.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-100');
            });
        }
        this.selectedProjectId = null;
        this.element.style.cursor = 'crosshair';
        this.updatePlaceableInstructions();
    }

    handleMapClick(event) {
        if (!this.selectedProjectId) return;

        if (this.isDragging || this.draggedPoint) return;

        event.preventDefault();
        event.stopPropagation();

        const imageRect = this.imageTarget.getBoundingClientRect();
        const xPercent = ((event.clientX - imageRect.left) / imageRect.width) * 100;
        const yPercent = ((event.clientY - imageRect.top) / imageRect.height) * 100;

        // ensure the click is within our map bounds
        if (xPercent < 0 || xPercent > 100 || yPercent < 0 || yPercent > 100) return;

        this.updateProjectPosition(this.selectedProjectId, xPercent, yPercent);
        this.clearProjectSelection();
    }

    updatePlaceableInstructions(customMessage = null) {
        if (!this.hasPlaceableCountTarget) return;

        const remaining = this.hasPlaceableProjectsTarget ? this.placeableProjectsTarget.children.length : 0;

        if (customMessage) {
            this.placeableCountTarget.textContent = customMessage;
        } else if (remaining > 0) {
            this.placeableCountTarget.textContent = `You can place ${remaining} more ${remaining === 1 ? 'project' : 'projects'}. Click a project below to select it, then click on the map to place it, or drag it directly.`;
        } else {
            this.placeableCountTarget.textContent = 'No projects available to place. Ship a project first to add it to the map.';
        }
    }

    async unplaceProject(projectId) {
        if (!confirm('Are you sure you want to remove this project from the map?')) {
            return;
        }

        const url = `/projects/${projectId}/unplace_coordinates`;
        const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
        const csrfToken = csrfTokenMeta ? csrfTokenMeta.content : '';

        try {
            const response = await fetch(url, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-Token': csrfToken
                }
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.errors ? errorData.errors.join(', ') : 'Failed to unplace project');
            }

            await this.fetchFreshMapData();

            await this.refreshPlaceableProjects();

        } catch (error) {
            console.error('Failed to unplace project:', error);
            alert(`Error: ${error.message}`);
        }
    }

    async refreshPlaceableProjects() {
        window.location.reload();
    }
}
