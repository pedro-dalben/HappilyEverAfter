import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]
  static values = {
    autoDismissAfter: { type: Number, default: 5000 } // 5 segundos por padrão
  }

  connect() {
    // Auto-dimiss after specified time
    if (this.autoDismissAfterValue > 0) {
      this.dismissTimeout = setTimeout(() => {
        this.dismiss()
      }, this.autoDismissAfterValue)
    }
  }

  disconnect() {
    // Clear timeout if component is removed
    if (this.dismissTimeout) {
      clearTimeout(this.dismissTimeout)
    }
  }

  dismiss() {
    // Fade out animation
    this.element.classList.add('opacity-0', 'transition-opacity', 'duration-500')

    // Remove after animation completes
    setTimeout(() => {
      this.element.remove()
    }, 500)
  }
}
