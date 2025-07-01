import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "project1DemoOpenedInput",
    "project1RepoOpenedInput",
    "project2DemoOpenedInput",
    "project2RepoOpenedInput",
    "timeSpentVotingInput",
    "musicPlayedInput",
  ];

  votingStartTime = null;
  formSubmitListener = null;

  connect() {
    this.votingStartTime = Date.now();
    
    this.attachFormListener();
  }

  attachFormListener() {
    const votingForm = this.element.querySelector('form[action*="votes"]') || 
                      this.element.querySelector('form');
    
    if (votingForm) {
      this.formSubmitListener = this.handleFormSubmit.bind(this);
      votingForm.addEventListener("submit", this.formSubmitListener, {
        once: true,
      });
    }
  }

  handleFormSubmit(event) {
    const form = event.currentTarget;
    if (this.votingStartTime) {
      const duration = Date.now() - this.votingStartTime;
      const hiddenInput = form.querySelector(
        '[data-voting-steps-target="timeSpentVotingInput"]',
      );
      if (hiddenInput) {
        hiddenInput.value = duration;
      }
    }
  }

  trackLinkClick(event) {
    if (event.type === "keydown" && ![13, 32].includes(event.keyCode)) {
      return;
    }

    event.stopPropagation();

    const link = event.currentTarget;
    const linkType = link.dataset.analyticsLink;
    const projectContainer = link.closest("[data-project-index]");

    if (!projectContainer || !linkType) {
      return;
    }

    const projectIndex = parseInt(projectContainer.dataset.projectIndex);

    // Determine which project (1 or 2) based on index
    const projectNumber = projectIndex + 1;

    // Find the hidden input field to update using data-voting-steps-target
    const targetName = `project${projectNumber}${linkType.charAt(0).toUpperCase() + linkType.slice(1)}OpenedInput`;
    const hiddenInput = document.querySelector(
      `[data-voting-steps-target="${targetName}"]`,
    );

    if (hiddenInput && hiddenInput.value !== "true") {
      hiddenInput.value = "true";
    }
  }

  handleMusicPlayed() {
    if (this.hasMusicPlayedInputTarget) {
      this.musicPlayedInputTargets.forEach((input) => {
        input.value = "true";
      });
    }
  }

  disconnect() {
    if (this.formSubmitListener) {
      const votingForm = this.element.querySelector('form[action*="votes"]') || 
                        this.element.querySelector('form');
      if (votingForm) {
        votingForm.removeEventListener("submit", this.formSubmitListener);
      }
    }
  }
}
