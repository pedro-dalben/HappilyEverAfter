import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.modal = document.getElementById("photoModal")
  }

  openModal(event) {
    const photoId = event.currentTarget.dataset.photo
    const photoElement = document.querySelector(`[data-photo-id="${photoId}"]`)

    if (photoElement) {
      // Esconde todas as fotos
      document.querySelectorAll('[data-photo-id]').forEach(el => el.classList.add('hidden'))
      // Mostra a foto selecionada
      photoElement.classList.remove('hidden')
      // Mostra o modal
      this.modal.classList.remove('hidden')
    }
  }

  closeModal() {
    this.modal.classList.add('hidden')
  }
}
