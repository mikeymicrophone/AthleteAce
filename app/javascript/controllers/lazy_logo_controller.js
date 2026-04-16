// app/javascript/controllers/lazy_logo_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    entityId: Number,
    entityType: String,
    url: String
  }
  static targets = ["image", "name"]

  connect() {
    this.logoLoaded = false

    requestAnimationFrame(() => {
      const inView = this.isElementInViewport(this.element)

      if (inView) {
        this.loadLogo()
      } else {
        this.observer = new IntersectionObserver(this.handleIntersection.bind(this), {
          rootMargin: "0px 0px 200px 0px"
        })
        this.observer.observe(this.element)
      }
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  isElementInViewport(el) {
    if (!el) return false
    const rect = el.getBoundingClientRect()
    return (
      rect.top < window.innerHeight &&
      rect.bottom >= 0 &&
      rect.left < window.innerWidth &&
      rect.right >= 0
    )
  }

  handleIntersection(entries, observer) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.loadLogo()
        observer.unobserve(entry.target)
      }
    })
  }

  async loadLogo() {
    if (this.logoLoaded) return
    this.logoLoaded = true

    const cacheKey = `logo-${this.entityTypeValue}-${this.entityIdValue}`
    let imageUrl = localStorage.getItem(cacheKey)

    if (!imageUrl && this.hasUrlValue && this.urlValue) {
      imageUrl = this.urlValue
    }

    if (imageUrl) {
      const img = document.createElement("img")
      img.src = imageUrl
      const altText = (this.hasNameTarget && this.nameTarget.textContent.trim())
        ? `${this.nameTarget.textContent.trim()} logo`
        : `${this.entityTypeValue} ${this.entityIdValue} logo`
      img.alt = altText
      img.classList.add("h-full", "w-full", "object-contain")

      img.onload = () => {
        localStorage.setItem(cacheKey, imageUrl)
      }

      img.onerror = () => {
        localStorage.removeItem(cacheKey)
      }

      this.imageTarget.innerHTML = ''
      this.imageTarget.appendChild(img)
    } else {
      this.imageTarget.innerHTML = ''
    }
  }
}
