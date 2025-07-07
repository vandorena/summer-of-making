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

    const converted = this.convertGit(repoUrl);
    if (converted !== repoUrl) {
      if (converted.includes("raw.githubusercontent.com")) {
        this.readmeInputTarget.value = converted;
        this.showRepoInfo("Adjusted your URL for ya!");
        return;
      }
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

    const converted = this.convertGit(url);
    if (converted !== url) {
      event.target.value = converted;
      this.showReadmeInfo("Auto-converted GitHub blob URL to raw URL");
    }

    // Check file extension for any URL
    const urlParts = converted.split("?")[0]; // Remove query params
    const extension = urlParts.split(".").pop().toLowerCase();

    if (!["md", "txt"].includes(extension)) {
      this.showReadmeError("README must be a .md or .txt file");
      return;
    }

    if (!["md", "txt"].includes(extension)) {
      this.showReadmeError("README must be a .md or .txt file");
      return;
    }

    this.clearReadmeError();
  }

  convertGit(url) {
    const match = url.match(/^https:\/\/github\.com\/([^\/]+)\/([^\/]+)\/blob\/([^\/]+)\/(.+)$/);

    if (match) {
      const [, owner, repo, branch, path] = match;
      return `https://raw.githubusercontent.com/${owner}/${repo}/refs/heads/${branch}/${path}`;
    }

    return url;
  }

  showReadmeInfo(message) {
    const errorElement = document.getElementById("readmeError");
    if (errorElement) {
      errorElement.textContent = message;
      errorElement.className = errorElement.className.replace("text-vintage-red", "text-forest");
      errorElement.classList.remove("hidden");

      setTimeout(() => {
        this.clearReadmeError();
      }, 3000);
    }
  }

  showReadmeError(message) {
    const errorElement = document.getElementById("readmeError");
    if (errorElement) {
      errorElement.textContent = message;
      errorElement.className = errorElement.className.replace("text-forest", "text-vintage-red");
      errorElement.classList.remove("hidden");
    }
  }

  clearReadmeError() {
    const errorElement = document.getElementById("readmeError");
    if (errorElement) {
      errorElement.classList.add("hidden");
    }
  }

  showRepoInfo(message) {
    const errorElement = document.getElementById("repoError");
    if (errorElement) {
      errorElement.textContent = message;
      errorElement.className = errorElement.className.replace("text-vintage-red", "text-forest");
      errorElement.classList.remove("hidden");

      setTimeout(() => {
        this.clearRepoError();
      }, 3000);
    }
  }

  clearRepoError() {
    const errorElement = document.getElementById("repoError");
    if (errorElement) {
      errorElement.classList.add("hidden");
    }
  }
}
