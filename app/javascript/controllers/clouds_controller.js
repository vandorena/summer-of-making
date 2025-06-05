import { Controller } from "@hotwired/stimulus";

// hey rowan how does this work?
// i dont fuckin know man, ask my goofy ass that was up at 1:25 on why this is so jank
// ah i see, are you sane?
// barely, but i can still code, so we ball

export default class extends Controller {
  static targets = ["container"];
  static values = {
    count: { type: Number, default: 5 },
    speed: { type: Number, default: 2 },
    color: { type: String, default: "rgba(200, 200, 200, 0.3)" },
  };

  connect() {
    this.c = [];
    this.a = true;
    this.make();
    this.rig();

    this.r = this.handleResize.bind(this);
    window.addEventListener("resize", this.r);

    this.v = this.handleVisibilityChange.bind(this);
    document.addEventListener("visibilitychange", this.v);
  }

  disconnect() {
    this.a = false;
    if (this.f) {
      cancelAnimationFrame(this.f);
    }
    window.removeEventListener("resize", this.r);
    document.removeEventListener("visibilitychange", this.v);
  }

  handleResize() {
    this.c.forEach((c) => {
      c.mx = window.innerWidth + c.offsetWidth;
    });
  }

  handleVisibilityChange() {
    if (document.hidden) {
      this.a = false;
      if (this.f) {
        cancelAnimationFrame(this.f);
      }
    } else {
      this.a = true;
      this.rig();
    }
  }

  make() {
    const svg = [
      `<svg viewBox="0 0 100 60" xmlns="http://www.w3.org/2000/svg">
        <path d="M25 40 C15 40, 10 30, 15 25 C10 15, 25 10, 35 15 C40 5, 60 5, 65 15 C75 10, 85 20, 80 30 C90 30, 90 40, 80 40 Z" fill="currentColor"/>
      </svg>`,

      `<svg viewBox="0 0 80 50" xmlns="http://www.w3.org/2000/svg">
        <path d="M20 35 C12 35, 8 28, 12 23 C8 15, 20 12, 28 16 C32 8, 48 8, 52 16 C60 12, 68 20, 64 28 C72 28, 72 35, 64 35 Z" fill="currentColor"/>
      </svg>`,

      `<svg viewBox="0 0 120 40" xmlns="http://www.w3.org/2000/svg">
        <path d="M15 30 C8 30, 5 25, 8 22 C5 18, 15 15, 22 18 C25 12, 40 12, 43 18 C50 15, 58 22, 55 26 C65 26, 65 30, 58 30 Z" fill="currentColor"/>
        <path d="M70 25 C65 25, 62 22, 64 20 C62 17, 68 15, 73 17 C75 13, 85 13, 87 17 C92 15, 97 20, 95 23 C100 23, 100 25, 95 25 Z" fill="currentColor"/>
      </svg>`,
    ];

    for (let i = 0; i < this.countValue; i++) {
      const c = this.createCloud(svg[i % svg.length], i);
      this.containerTarget.appendChild(c);
      this.c.push(c);
    }
  }

  createCloud(svg, i) {
    const c = document.createElement("div");
    c.className = "absolute pointer-events-none dynamic-cloud";
    c.innerHTML = svg;

    const sz = this.rand(100, 200);
    const y = this.rand(10, 80);
    const sp = this.rand(0.2, 1.0) * this.speedValue;
    const d = this.rand(0, 15);

    c.style.width = `${sz}px`;
    c.style.height = `${sz * 0.6}px`;
    c.style.top = `${y}%`;
    c.style.left = `${sz}px`;
    c.style.color = this.colorValue;
    c.style.zIndex = Math.floor(this.rand(1, 5)).toString();
    c.style.opacity = this.rand(0.3, 0.7);

    c.sp = sp;
    c.x = -sz - d * 100;
    c.mx = window.innerWidth + sz;

    const fd = this.rand(8, 15);
    c.style.animation = `cloudFloat ${fd}s ease-in-out infinite`;
    c.style.animationDelay = `${this.rand(0, 5)}s`;

    return c;
  }

  rand(min, max) {
    return Math.random() * (max - min) + min;
  }

  rig() {
    if (!this.a) return;

    let lt = 0;
    const fps = 60;
    const ft = 1000 / fps;

    const go = (t) => {
      if (!this.a) return;

      if (t - lt >= ft) {
        this.c.forEach((c) => {
          c.x += c.sp;

          if (c.x > c.mx) {
            c.x = -c.offsetWidth;
            c.style.top = `${this.rand(10, 80)}%`;
            c.sp = this.rand(0.2, 1.0) * this.speedValue;
            c.style.opacity = this.rand(0.3, 0.7);
          }

          c.style.transform = `translateX(${c.x}px)`;
        });

        lt = t;
      }

      this.f = requestAnimationFrame(go);
    };

    go(0);
  }
}
