import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tabButton", "content"];
  static values = { currentTab: String };

  connect() {
    this.updateTabButtons();
  }

  switchTab(event) {
    const newTab = event.currentTarget.dataset.tab;
    this.currentTabValue = newTab;
    this.updateTabButtons();
    this.loadTabContent(newTab);
  }

  updateTabButtons() {
    this.tabButtonTargets.forEach((button) => {
      const isActive = button.dataset.tab === this.currentTabValue;

      if (isActive) {
        button.className = "px-6 tab-element py-2 text-xl text-black";
      } else {
        button.className = "px-6 py-2 text-xl text-black";
      }
    });
  }

  loadTabContent(tab) {
    const devlogsListContainer = document.getElementById(
      "devlogs-list-container",
    );

    if (devlogsListContainer) {
      devlogsListContainer.innerHTML = `
        <div class="space-y-4 sm:space-y-6" id="devlogs-list">
        </div>
        <div id="load-more-devlogs">
        </div>
      `;
    }

    const devlogsList = document.getElementById("devlogs-list");
    const newInitialFrame = document.createElement("turbo-frame");
    newInitialFrame.id = "initial-devlogs";
    newInitialFrame.src = `/explore?tab=${tab}&format=turbo_stream`;
    newInitialFrame.loading = "eager";

    if (devlogsList) {
      devlogsList.appendChild(newInitialFrame);
    }
  }
}
