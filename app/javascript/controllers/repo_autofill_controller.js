import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["repoInput", "readmeInput"];
  static debounceTimeout = null;

  connect() {
    this.debounceDelay = 500; // ms
  }

  repoInputChanged(event) {
    clearTimeout(this.constructor.debounceTimeout);

    this.constructor.debounceTimeout = setTimeout(() => {
      this.processRepoUrl(event.target.value.trim());
    }, this.debounceDelay);
  }

  processRepoUrl(repoUrl) {
    if (!repoUrl) {
      this.readmeInputTarget.value = "";
      return;
    }

    // Check if it's a GitHub URL
    const githubMatch = repoUrl.match(/github\.com\/([^\/]+)\/([^\/]+)/);

    if (githubMatch) {
      const [, owner, repo] = githubMatch;
      const cleanRepo = repo.replace(/\.git$/, ""); // Remove .git suffix if present

      // Check if readme exists via server
      this.checkGitHubReadme(owner, cleanRepo);
    }
  }

  async checkGitHubReadme(owner, repo) {
    try {
      const response = await fetch(
        `/check_github_readme?owner=${encodeURIComponent(owner)}&repo=${encodeURIComponent(repo)}`,
        {
          headers: {
            Accept: "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
        },
      );

      const data = await response.json();

      if (data.readme_url) {
        this.readmeInputTarget.value = data.readme_url;
        // Dispatch an event to trigger validation
        this.readmeInputTarget.dispatchEvent(
          new Event("input", { bubbles: true }),
        );
      }
    } catch (error) {
      console.error("Failed to check GitHub readme:", error);
    }
  }

  validateReadmeUrl(event) {
    const url = event.target.value.trim();
    if (!url) return;

    // Check if it's a GitHub blob URL (not allowed)
    if (url.includes("github.com") && url.includes("/blob/")) {
      this.showReadmeError("Please use the raw GitHub link, not the blob URL");
      return;
    }

    // Check file extension for any URL
    const urlParts = url.split("?")[0]; // Remove query params
    const extension = urlParts.split(".").pop().toLowerCase();

    if (!["md", "txt"].includes(extension)) {
      this.showReadmeError("README must be a .md or .txt file");
      return;
    }

    this.clearReadmeError();
  }

  showReadmeError(message) {
    const errorElement = document.getElementById("readmeError");
    if (errorElement) {
      errorElement.textContent = message;
      errorElement.classList.remove("hidden");
    }
  }

  clearReadmeError() {
    const errorElement = document.getElementById("readmeError");
    if (errorElement) {
      errorElement.classList.add("hidden");
    }
  }
}
