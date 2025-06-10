import { Controller } from "@hotwired/stimulus";

// After how many milliseconds should we collapse the sidebar when the user is not hovering
// over it?
const COLLAPSE_DELAY = 250;

// For how many milliseconds should elements marked with 'collapseFade' fade out for?
// This should be a value recognized by Tailwind.
const FADE_DURATION = "200";

export default class extends Controller {
  static targets = [
    "sidebar",
    "content",
    "collapseHide",
    "collapseFade",
    "underline",
    "links"
  ]

  connect() {
    this.expanded = true
    this.transitioning = false
    this.mouseEntered = false
    this.prevKnownSize = this.hasSidebarTarget ? this.sidebarTarget.clientWidth + "px" : "100px";

    this.collapseFadeTargets.forEach(element => {
      element.classList.add("transition-opacity", `duration-${FADE_DURATION}`)
    })
  
    // Store sidebar state in localStorage to persist across page loads (exists cause I don't want state to reset when user clicks on another button)
    if (localStorage.getItem("sidebarCollapsed") === "true") {
      this.collapse();
      this.expanded = false;
      if (this.hasCollapseIconTarget) {
        this.collapseIconTarget.classList.add("rotate-180");
      }
    } else {
      if (this.hasCollapsedOverlayTarget) {
        this.collapsedOverlayTarget.classList.add("hidden");
      }
    }
  }
  
  disconnect() {
  }

  /**
   * @param {MouseEvent} event 
   */
  handleMouseEnter(event) {
    if (this.transitioning) {
      console.log("'handleMouseEnter' invoked while playing the sidebar transition animation. Ignoring.");
      return;
    }

    // As soon as the user touches the sidebar, expand it.
    if (!this.expanded) {
      this.expand()
    }

    this.mouseEntered = true
  }

  /**
   * @param {MouseEvent} event 
   */
  handleMouseExit(event) {
    if (this.transitioning) {
      console.log("'handleMouseExit' invoked while playing the sidebar transition animation. Ignoring.");
      return;
    }

    this.mouseEntered = false

    setTimeout(() => {
      // If after .5s the user hasn't moved the mouse back inside the sidebar, hide it.
      if (!this.mouseEntered) {
        this.collapse()
      }
    }, COLLAPSE_DELAY)
  }
  
  toggle(event) {
    if (event) {
      event.stopPropagation();
    }

    if (this.expanded) {
      this.collapse();
    } else {
      this.expand();
    }
    
    localStorage.setItem('sidebarCollapsed', !this.expanded)
    
    // Rotate. I'm not asking darlene to design another icon :D
    if (this.hasCollapseIconTarget) {
      this.collapseIconTarget.classList.toggle("rotate-180");
    }
  }

  collapse() {
    // Each element that needs to be hidden when the sidebar is collapsed should
    // be marked with the "collapseHide" target. 
    //
    // We want a nice width scaling animation, but CSS can realistically only do that
    // when the property actually *changes*... if `width` is 100% and something changes
    // inside the element, it doesn't animate, unfortunately.
    //
    // When collapsing the sidebar, we calculate its expanded width. We assign that
    // width as a fixed one in CSS (hopefully not causing any layout shifting in the process),
    // and then, one animation frame later, we set the width to a known, expected value.
    this.transitioning = true;

    this.sidebarTarget.style.width = this.prevKnownSize = `${this.sidebarTarget.clientWidth}px`;
    setTimeout(() => {
      this.sidebarTarget.style.width = "48px";
      this.transitioning = false;
    }, 16);

    this.sidebarTarget.classList.add("collapsed")
    this.collapseHideTargets.forEach(element => {
      element.classList.add("hidden")
    })

    this.collapseFadeTargets.forEach(element => {
      element.classList.add("opacity-0")
    })

    this.underlineTargets.forEach(element => {
      element.classList.remove("w-full")
      element.classList.add("w-[36px]")
      element.style.transform = "translateX(-10px)"
    })

    if (this.hasLinksTarget) {
      this.linksTarget.style.transform = "translateX(5px)";
    }
  
    this.expanded = false
  }

  expand() {
    this.transitioning = true;

    this.sidebarTarget.style.width = this.prevKnownSize;
    setTimeout(() => {
      this.sidebarTarget.style.width = "";
      this.transitioning = false;
    }, 16);

    this.sidebarTarget.classList.remove("collapsed")
    this.sidebarTarget.classList.remove("w-[30px]")
    this.collapseHideTargets.forEach(element => {
      element.classList.remove("hidden")
    })

    this.collapseFadeTargets.forEach(element => {
      element.classList.remove("opacity-0")
    })

    this.underlineTargets.forEach(element => {
      element.classList.add("w-full")
      element.classList.remove("w-[36px]")
      element.style.transform = "";
    })

    if (this.hasLinksTarget) {
      this.linksTarget.style.transform = "";
    }

    this.expanded = true
  }
} 