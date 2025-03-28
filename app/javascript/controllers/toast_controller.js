import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: String
  }

  connect() {
    if (this.messageValue && typeof showToast === 'function') {
      showToast(this.messageValue);
      // Auto-destruir este elemento após um pequeno intervalo
      setTimeout(() => {
        this.element.remove();
      }, 500);
    }
  }
}
