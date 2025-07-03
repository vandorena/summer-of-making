import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video"]
  static values = { 
    context: { type: String, default: "" },
    autoplay: { type: Boolean, default: false }
  }

  connect() {
    if (this.autoplayValue && this.contextValue === "explore") {
      this.setupAutoplay()
    }
  }

  setupAutoplay() {
    this.videoTargets.forEach(video => {
      video.muted = true
      video.loop = true
      video.autoplay = true
      video.playsInline = true

      video.controls = false

      video.setAttribute('data-loading', 'true')
      video.addEventListener('click', this.handleVideoClick.bind(this))
      video.addEventListener('loadeddata', this.handleVideoLoaded.bind(this))
      video.addEventListener('error', this.handleVideoError.bind(this))
      
      this.observeVideo(video)
    })
  }

  handleVideoLoaded(event) {
    const video = event.target
    video.removeAttribute('data-loading')
  }

  handleVideoError(event) {
    const video = event.target
    console.error('Video failed to load:', event)
    
    const container = video.closest('[data-controller*="video"]')
    if (container) {
      const errorMessage = document.createElement('div')
      errorMessage.className = 'absolute inset-0 flex items-center justify-center bg-gray-100 text-gray-600 rounded-lg'
      errorMessage.innerHTML = '<div class="text-center"><div class="text-2xl mb-2">📹</div><div>Video unavailable</div></div>'
      container.appendChild(errorMessage)
    }
  }

  observeVideo(video) {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.playVideo(video)
        } else {
          this.pauseVideo(video)
        }
      })
    }, {
      threshold: 0.5
    })
    
    observer.observe(video)
    
    video._intersectionObserver = observer
  }

  async playVideo(video) {
    try {
      await video.play()
    } catch (error) {
      console.log('autoplay being funky ', error)
      
      this.showPlayButton(video)
    }
  }

  showPlayButton(video) {
    const container = video.closest('[data-controller*="video"]')
    const existingButton = container?.querySelector('.play-button-overlay')
    if (existingButton) return
    
    const playButton = document.createElement('div')
    playButton.className = 'play-button-overlay absolute inset-0 flex items-center justify-center bg-black bg-opacity-30 cursor-pointer z-10'
    playButton.innerHTML = '<div class="bg-white bg-opacity-90 rounded-full p-4 hover:bg-opacity-100 transition-all"><svg class="w-8 h-8 text-black" fill="currentColor" viewBox="0 0 20 20"><path d="M8 5v10l8-5-8-5z"/></svg></div>'
    
    playButton.addEventListener('click', () => {
      video.play()
      playButton.remove()
    })
    
    container.appendChild(playButton)
  }

  pauseVideo(video) {
    if (!video.paused) {
      video.pause()
    }
  }

  handleVideoClick(event) {
    const video = event.target
    if (video.muted) {
      video.muted = false
      video.controls = true
      
      this.updateSoundHint(video, true)
      this.showSoundEnabledFeedback(video)
    }
  }

  updateSoundHint(video, soundEnabled) {
    const container = video.closest('[data-controller*="video"]')
    const hint = container?.querySelector('.video-sound-hint')
    
    if (hint) {
      if (soundEnabled) {
        hint.textContent = '🔊 Sound enabled'
        hint.classList.add('bg-green-600', 'bg-opacity-75')
        hint.classList.remove('bg-black')

        setTimeout(() => {
          hint.style.opacity = '0'
          setTimeout(() => hint.remove(), 300)
        }, 1500)
      } else {
        hint.textContent = '🔇 Click for sound'
      }
    }
  }

  showSoundEnabledFeedback(video) {
    const container = video.closest('[data-controller*="video"]')
    const existingOverlay = container?.querySelector('.sound-enabled-overlay')
    if (existingOverlay) return
    
    const overlay = document.createElement('div')
    overlay.className = 'sound-enabled-overlay absolute top-2 left-2 bg-green-600 bg-opacity-90 text-white px-3 py-2 rounded-lg text-sm z-20 animate-pulse'
    overlay.innerHTML = '🔊 <span class="font-medium">Sound enabled!</span>'
    
    if (!container.classList.contains('relative')) {
      container.classList.add('relative')
    }
    
    container.appendChild(overlay)
    
    overlay.style.opacity = '0'
    overlay.style.transform = 'translateY(-10px)'
    setTimeout(() => {
      overlay.style.transition = 'all 0.3s ease'
      overlay.style.opacity = '1'
      overlay.style.transform = 'translateY(0)'
    }, 10)
    
    setTimeout(() => {
      overlay.style.opacity = '0'
      overlay.style.transform = 'translateY(-10px)'
      setTimeout(() => {
        if (overlay.parentElement) {
          overlay.remove()
        }
      }, 300)
    }, 2500)
  }

  disconnect() {
    this.videoTargets.forEach(video => {
      if (video._intersectionObserver) {
        video._intersectionObserver.disconnect()
        delete video._intersectionObserver
      }
      
      video.removeEventListener('click', this.handleVideoClick.bind(this))
      video.removeEventListener('loadeddata', this.handleVideoLoaded.bind(this))
      video.removeEventListener('error', this.handleVideoError.bind(this))
    })
  }
}
