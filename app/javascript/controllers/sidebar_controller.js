import { Controller } from "@hotwired/stimulus";

// After how many milliseconds should we collapse the sidebar when the user is not hovering
// over it?
const COLLAPSE_DELAY = 250;

// For how many milliseconds should elements marked with 'collapseFade' fade out for?
// This should be a value recognized by Tailwind.
const FADE_DURATION = "200";

const SS_SIDEBAR_EXPANDED_KEY = "som.sidebarExpanded";
const SS_SIDEBAR_PINNED_KEY = "som.sidebarPinned";

export default class extends Controller {
  static targets = [
    "sidebar",
    "content",
    "collapseHide",
    "collapseFade",
    "underline",
    "links",
    "pinButton",
    "pinIcon",
  ];

  connect() {
    this.expanded = true;
    this.transitioning = false;
    this.mouseEntered = false;
    this.animationTimers = [];
    this.prevKnownSize = this.hasSidebarTarget
      ? this.sidebarTarget.clientWidth + "px"
      : "100px";
    this.pinned = sessionStorage.getItem(SS_SIDEBAR_PINNED_KEY) === "true";

    this.collapseFadeTargets.forEach((element) => {
      element.classList.add("transition-opacity", `duration-${FADE_DURATION}`);
    });

    if (this.pinned) {
      this.expand();
      this.pinIconTarget.classList.remove("rotate-45");
    } else if (sessionStorage.getItem(SS_SIDEBAR_EXPANDED_KEY) === "false") {
      // In this session, the sidebar *wasn't* previously expanded. This probably
      // means that the user navigated somewhere without the use of the sidebar.
      this.collapse(true);
    } else {
      // In this session, there either wasn't any interaction with the sidebar before (null)
      // or the sidebar was expanded.
      //
      // Collapse it after a couple of seconds, given the user didn't interact with the
      // sidebar. This is intended to:
      //    1) teach new users that the sidebar expands.
      //    2) give time for us to register if the user is hovering over the sidebar,
      //       so that between navigations we don't collapse it for a split second,
      //       which looks quite janky.
      setTimeout(() => {
        if (!this.mouseEntered && !this.sidebarTarget.matches(":hover")) {
          this.collapse();
        }
      }, 1000);
    }
  }

  /**
   * Queues an animation task to run after the specified amount of milliseconds. Animation
   * timers may be interrupted if another animation is played.
   * @param {number} delay
   * @param {TimerHandler} handler
   */
  registerAnimationTimer(delay, handler) {
    const timerId = setTimeout(() => {
      this.animationTimers = this.animationTimers.filter((x) => x != timerId);
      handler();
    }, delay);

    this.animationTimers.push(timerId);
  }

  interruptAnimationTimers() {
    for (const timer of this.animationTimers) {
      clearTimeout(timer);
    }

    this.animationTimers = [];
  }

  disconnect() {}

  togglePin(event) {
    event.preventDefault();
    this.pinned = !this.pinned;
    sessionStorage.setItem(SS_SIDEBAR_PINNED_KEY, this.pinned.toString());

    if (this.pinned) {
      this.expand();
      this.pinIconTarget.classList.remove("rotate-45");
    } else {
      this.pinIconTarget.classList.add("rotate-45");
      if (!this.mouseEntered) {
        this.collapse();
      }
    }
  }

  /**
   * @param {MouseEvent} event
   */
  handleMouseEnter(event) {
    if (this.transitioning || this.pinned) {
      return;
    }

    // As soon as the user touches the sidebar, expand it.
    if (!this.expanded) {
      this.expand();
    }

    this.mouseEntered = true;
  }

  /**
   * @param {MouseEvent} event
   */
  handleMouseExit(event) {
    this.mouseEntered = false;

    if (this.transitioning || this.pinned) {
      return;
    }

    setTimeout(() => {
      // If after .5s the user hasn't moved the mouse back inside the sidebar, hide it.
      if (!this.mouseEntered && !this.pinned) {
        this.collapse();
      }
    }, COLLAPSE_DELAY);
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
  }

  collapse(immediate = false) {
    if (!this.expanded) return;

    this.interruptAnimationTimers();

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
    if (!immediate) {
      this.transitioning = true;
      this.sidebarTarget.style.width =
        this.prevKnownSize = `${this.sidebarTarget.clientWidth}px`;

      setTimeout(() => {
        this.sidebarTarget.style.width = "48px";
        this.transitioning = false;
      }, 16);
    } else {
      // We don't want a transition, so just set it out-right.
      this.sidebarTarget.classList.add("disable-transitions");
      this.sidebarTarget.style.width = "48px";

      setTimeout(
        () => this.sidebarTarget.classList.remove("disable-transitions"),
        1
      );
    }

    this.sidebarTarget.classList.add("collapsed");
    this.collapseHideTargets.forEach((element) => {
      element.classList.add("hidden");
    });

    this.collapseFadeTargets.forEach((element) => {
      element.classList.add("opacity-0");
    });

    this.pinButtonTarget.classList.add("opacity-0");

    this.registerAnimationTimer(250, () => {
      this.collapseFadeTargets.forEach((element) => {
        element.classList.add("w-[0px]");
      });
    });

    this.underlineTargets.forEach((element) => {
      element.classList.remove("w-full");
      element.classList.add("w-[36px]");
      element.style.transform = "translateX(-10px)";
    });

    if (this.hasLinksTarget) {
      this.linksTarget.style.transform = "translateX(5px)";
    }

    this.expanded = false;
    sessionStorage.setItem(SS_SIDEBAR_EXPANDED_KEY, "false");
  }

  expand() {
    if (this.expanded) return;

    this.interruptAnimationTimers();
    this.transitioning = true;

    this.sidebarTarget.style.width = this.prevKnownSize;
    this.sidebarTarget.style.overflowX = "hidden";

    this.registerAnimationTimer(150, () => {
      this.sidebarTarget.style.width = "";
      this.sidebarTarget.style.overflowX = "";
      this.transitioning = false;
    });

    this.sidebarTarget.classList.remove("collapsed", "w-[30px]");
    this.collapseHideTargets.forEach((element) => {
      element.classList.remove("hidden");
    });

    this.collapseFadeTargets.forEach((element) => {
      element.classList.remove("opacity-0", "w-[0px]");
    });

    this.pinButtonTarget.classList.remove("opacity-0");

    this.underlineTargets.forEach((element) => {
      element.classList.add("w-full");
      element.classList.remove("w-[36px]");
      element.style.transform = "";
    });

    if (this.hasLinksTarget) {
      this.linksTarget.style.transform = "";
    }

    this.expanded = true;
    sessionStorage.setItem(SS_SIDEBAR_EXPANDED_KEY, "true");
  }
}
