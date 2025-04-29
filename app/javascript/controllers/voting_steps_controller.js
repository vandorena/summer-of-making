import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step1", "step2", "loadingIndicator", "project", "form"]
  
  selectedProject = null

  async connect() {
    this.step1Target.classList.add("hidden")
    this.step2Target.classList.add("hidden")
    this.loadingIndicatorTarget.classList.remove("hidden")
    
    await new Promise(resolve => setTimeout(resolve, 500))
    
    this.loadingIndicatorTarget.classList.add("hidden")
    this.step1Target.classList.remove("hidden")
    
    if (this.hasFormTarget) {
      this.formTargets.forEach(form => {
        form.classList.add("hidden")
      })
    }
  }

  async nextStep() {
    this.step1Target.classList.add("hidden")
    this.loadingIndicatorTarget.classList.remove("hidden")
    
    await new Promise(resolve => setTimeout(resolve, 250))
    
    this.loadingIndicatorTarget.classList.add("hidden")
    this.step2Target.classList.remove("hidden")
    window.scrollTo({ top: 0, behavior: "smooth" })
  }

  prevStep() {
    this.step2Target.classList.add("hidden")
    this.step1Target.classList.remove("hidden")
    window.scrollTo({ top: 0, behavior: "smooth" })
    
    this.resetSelection()
  }
  
  selectProject(event) {
    const projectId = event.currentTarget.dataset.projectId
    
    if (this.selectedProject === projectId) {
      this.resetSelection()
      return
    }
    
    this.selectedProject = projectId
    
    this.projectTargets.forEach(project => {
      const isSelected = project.dataset.projectId === projectId
      
      if (isSelected) {
        project.classList.add("scale-105", "z-10")
        project.classList.remove("opacity-50", "scale-95")
      } else {
        project.classList.add("opacity-50", "scale-95")
        project.classList.remove("scale-105", "z-10")
      }
    })
    
    this.formTargets.forEach(form => {
      if (form.dataset.projectId === projectId) {
        form.classList.remove("hidden")
      } else {
        form.classList.add("hidden")
      }
    })
  }
  
  resetSelection() {
    this.selectedProject = null
    
    this.projectTargets.forEach(project => {
      project.classList.remove("opacity-50", "scale-95", "scale-105", "z-10")
    })
    
    this.formTargets.forEach(form => {
      form.classList.add("hidden")
    })
  }
} 