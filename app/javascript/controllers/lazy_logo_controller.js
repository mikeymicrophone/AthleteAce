// app/javascript/controllers/lazy_logo_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    entityId: Number,
    entityType: String,
    url: String // Direct image URL from data attribute
  }
  static targets = ["image", "name"]

  connect() {
    console.log(`LazyLogo#connect: ${this.entityTypeValue} ${this.entityIdValue}`, this.element);
    
    // Defer the check slightly to allow for layout stabilization
    requestAnimationFrame(() => {
      const inView = this.isElementInViewport(this.element);
      console.log(`LazyLogo#connect (in RAF) - inView: ${inView} for ${this.entityTypeValue} ${this.entityIdValue}`);

      if (inView) {
        console.log(`LazyLogo#connect - Loading immediately for ${this.entityTypeValue} ${this.entityIdValue}`);
        this.loadLogo();
      } else {
        console.log(`LazyLogo#connect - Setting up observer for ${this.entityTypeValue} ${this.entityIdValue}`);
        this.observer = new IntersectionObserver(this.handleIntersection.bind(this), {
          rootMargin: "0px 0px 200px 0px", // Start loading when 200px away from viewport
        });
        this.observer.observe(this.element);
      }
    });
  }

  disconnect() {
    if (this.observer) {
      console.log(`LazyLogo#disconnect - Disconnecting observer for ${this.entityTypeValue} ${this.entityIdValue}`);
      this.observer.disconnect();
    }
  }

  isElementInViewport(el) {
    if (!el) return false;
    const rect = el.getBoundingClientRect();
    const inView = (
      rect.top < window.innerHeight &&
      rect.bottom >= 0 &&
      rect.left < window.innerWidth &&
      rect.right >= 0
    );
    // console.log(`LazyLogo#isElementInViewport - rect: {top: ${rect.top}, bottom: ${rect.bottom}, left: ${rect.left}, right: ${rect.right}}, inView: ${inView} for el:`, el);
    return inView;
  }

  handleIntersection(entries, observer) {
    entries.forEach(entry => {
      // entry.target is this.element in this controller's setup
      console.log(`LazyLogo#handleIntersection - isIntersecting: ${entry.isIntersecting} for ${this.entityTypeValue} ${this.entityIdValue}`);
      if (entry.isIntersecting) {
        this.loadLogo();
        observer.unobserve(entry.target);
      }
    });
  }

  async loadLogo() {
    if (this.logoLoaded) {
      // console.log(`LazyLogo#loadLogo - Already loaded for ${this.entityTypeValue} ${this.entityIdValue}`);
      return;
    }
    this.logoLoaded = true;
    console.log(`LazyLogo#loadLogo - Called for ${this.entityTypeValue} ${this.entityIdValue}`);

    const cacheKey = `logo-${this.entityTypeValue}-${this.entityIdValue}`;
    let imageUrl = localStorage.getItem(cacheKey);
    // console.log(`LazyLogo#loadLogo - From cache: '${imageUrl}' for ${this.entityTypeValue} ${this.entityIdValue}`);

    if (!imageUrl && this.hasUrlValue && this.urlValue) {
        imageUrl = this.urlValue;
        console.log(`LazyLogo#loadLogo - From data-url: '${imageUrl}' for ${this.entityTypeValue} ${this.entityIdValue}`);
        if (imageUrl) localStorage.setItem(cacheKey, imageUrl);
    }
    
    if (imageUrl) {
      console.log(`LazyLogo#loadLogo - Creating img tag with src: '${imageUrl}' for ${this.entityTypeValue} ${this.entityIdValue}`);
      const img = document.createElement("img");
      img.src = imageUrl;
      const altText = (this.hasNameTarget && this.nameTarget.textContent.trim()) 
                      ? `${this.nameTarget.textContent.trim()} logo` 
                      : `${this.entityTypeValue} ${this.entityIdValue} logo`;
      img.alt = altText;
      img.classList.add("h-full", "w-full", "object-contain");

      this.imageTarget.innerHTML = '';
      this.imageTarget.appendChild(img);
    } else {
      console.warn(`LazyLogo#loadLogo - No image URL found for ${this.entityTypeValue} ${this.entityIdValue}`);
      this.imageTarget.innerHTML = '';
    }
  }
}
