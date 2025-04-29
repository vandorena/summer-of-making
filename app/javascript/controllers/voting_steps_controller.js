import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step1", "step2", "loadingIndicator", "project", "form",
    "winnerDemoOpenedInput", "winnerReadmeOpenedInput", "winnerRepoOpenedInput",
    "loserDemoOpenedInput", "loserReadmeOpenedInput", "loserRepoOpenedInput",
    "timeSpentVotingInput", "musicPlayedInput"
  ]
  
  selectedProject = null
  votingStartTime = null
  formSubmitListener = null

  async connect() {
    this.step1Target.classList.add("hidden")
    this.step2Target.classList.add("hidden")
    this.loadingIndicatorTarget.classList.remove("hidden")
    
    await new Promise(resolve => setTimeout(resolve, 500))
    
    this.loadingIndicatorTarget.classList.add("hidden")
    this.step1Target.classList.remove("hidden")
    
    this.votingStartTime = Date.now();
    
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
    let selectedForm = null;
    
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
    
    if (this.formSubmitListener) {
        this.formTargets.forEach(form => {
            form.removeEventListener('submit', this.formSubmitListener);
        });
        this.formSubmitListener = null;
    }

    this.formTargets.forEach(form => {
      if (form.dataset.projectId === projectId) {
        form.classList.remove("hidden")
        selectedForm = form;
      } else {
        form.classList.add("hidden")
      }
    })

    if (selectedForm) {
        this.formSubmitListener = this.handleFormSubmit.bind(this);
        selectedForm.addEventListener('submit', this.formSubmitListener, { once: true }); 
    }
  }
  
  resetSelection() {
    this.selectedProject = null
    
    if (this.formSubmitListener) {
        this.formTargets.forEach(form => {
            form.removeEventListener('submit', this.formSubmitListener);
        });
        this.formSubmitListener = null;
    }

    this.projectTargets.forEach(project => {
      project.classList.remove("opacity-50", "scale-95", "scale-105", "z-10")
    })
    
    this.formTargets.forEach(form => {
      form.classList.add("hidden")
    })
  }
  
  handleFormSubmit(event) {
      const form = event.currentTarget;
      if (this.votingStartTime) {
          const duration = Date.now() - this.votingStartTime;
          const hiddenInput = form.querySelector('[data-voting-steps-target="timeSpentVotingInput"]');
          if (hiddenInput) {
              hiddenInput.value = duration;
          }
      } 
  }

  trackLinkClick(event) {
    if (event.type === 'keydown' && ![13, 32].includes(event.keyCode)) {
      return;
    }
    
    event.stopPropagation(); 

    const link = event.currentTarget;
    const linkType = link.dataset.analyticsLink;
    const projectCard = link.closest('[data-project-id]');
    
    if (!projectCard || !linkType) {
        return;
    }

    const clickedProjectId = projectCard.dataset.projectId;

    this.formTargets.forEach(form => {
      const winnerInput = form.querySelector('input[name="vote[winner_id]"]');
      if (!winnerInput) {
          return;
      }

      const formWinnerId = winnerInput.value;
      
      const isWinnerClick = clickedProjectId === formWinnerId; 
      const prefix = isWinnerClick ? 'winner' : 'loser';

      const targetName = `${prefix}${linkType.charAt(0).toUpperCase() + linkType.slice(1)}OpenedInput`;

      const hiddenInput = form.querySelector(`[data-voting-steps-target="${targetName}"]`);

      if (hiddenInput) {
        if (hiddenInput.value !== 'true') {
          hiddenInput.value = 'true';
        }
      }
    });
  }

  handleMusicPlayed() {
    if (this.hasMusicPlayedInputTarget) {
      this.musicPlayedInputTargets.forEach(input => {
        input.value = 'true';
      });
    }
  }

  disconnect() {
      if (this.formSubmitListener) {
          this.formTargets.forEach(form => {
              form.removeEventListener('submit', this.formSubmitListener);
          });
      }
  }
} 