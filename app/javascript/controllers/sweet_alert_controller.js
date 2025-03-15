import { Controller } from '@hotwired/stimulus'
import Swal from 'sweetalert2'

export default class extends Controller {
	static values = {
		title: String,
		text: { type: String, default: '' },
		html: { type: String, default: '' },
		confirmButtonText: { type: String, default: 'Confirmar' },
		cancelButtonText: { type: String, default: 'Cancelar' },
		icon: { type: String, default: 'warning' },
		confirmButtonColor: { type: String, default: '#2D3047' },
		cancelButtonColor: { type: String, default: '#73C8A9' },
		customHandler: { type: Boolean, default: false },
	}

	static targets = ['form']

	initialize() {
		// Determinar se estamos em uma página de membros
		this.isMembersPage =
			document.querySelectorAll('input[name="member_ids[]"]').length > 0
	}

	connect() {
		// Certificar-se de que o form não é enviado diretamente
		console.log('loaded')

		if (this.hasFormTarget) {
			this.formTarget.addEventListener('submit', this.handleSubmit.bind(this))
		}
	}

	disconnect() {
		if (this.hasFormTarget) {
			this.formTarget.removeEventListener(
				'submit',
				this.handleSubmit.bind(this)
			)
		}
	}

	// Intercepta o submit do formulário
	handleSubmit(event) {
		event.preventDefault()
		this.confirm()
	}

	// Método público que pode ser chamado via data-action
	confirm() {
		let message = this.textValue
		let htmlContent = this.htmlValue

		// Se estamos na página de membros e não temos texto/html personalizado
		if (this.isMembersPage && !message && !htmlContent) {
			// Coleta os dados necessários para o alerta
			const selectedMembers = Array.from(
				document.querySelectorAll('input[name="member_ids[]"]:checked')
			).map((checkbox) => checkbox.nextElementSibling.textContent.trim())

			const unselectedMembers = Array.from(
				document.querySelectorAll('input[name="member_ids[]"]:not(:checked)')
			).map((checkbox) => checkbox.nextElementSibling.textContent.trim())

			htmlContent = '<div class="text-left">'

			if (selectedMembers.length > 0) {
				htmlContent +=
					'<p class="font-medium mb-2">Você está confirmando a presença de:</p>'
				htmlContent += '<ul class="mb-4 pl-4">'
				selectedMembers.forEach((member) => {
					htmlContent += `<li class="mb-1">✅ ${member}</li>`
				})
				htmlContent += '</ul>'
			} else {
				htmlContent += '<p class="mb-4">Nenhum membro selecionado</p>'
			}

			if (unselectedMembers.length > 0) {
				htmlContent += '<p class="font-medium mb-2">Não comparecerão:</p>'
				htmlContent += '<ul class="pl-4">'
				unselectedMembers.forEach((member) => {
					htmlContent += `<li class="mb-1">❌ ${member}</li>`
				})
				htmlContent += '</ul>'
			}

			htmlContent += '</div>'
		}

		Swal.fire({
			title: this.titleValue || 'Confirmar',
			text: message,
			html: htmlContent,
			icon: this.iconValue,
			showCancelButton: true,
			confirmButtonColor: this.confirmButtonColorValue,
			cancelButtonColor: this.cancelButtonColorValue,
			confirmButtonText: this.confirmButtonTextValue,
			cancelButtonText: this.cancelButtonTextValue,
			customClass: {
				container: 'sweet-alert-custom',
				popup: 'sweet-alert-popup',
				content: 'sweet-alert-content',
			},
		}).then((result) => {
			if (result.isConfirmed) {
				if (this.customHandlerValue) {
					// Dispara um evento customizado para handlers externos
					const event = new CustomEvent('sweet-alert:confirmed', {
						bubbles: true,
						detail: { controller: this },
					})
					this.element.dispatchEvent(event)
				} else if (this.hasFormTarget) {
					// Submit do formulário padrão
					this.formTarget.removeEventListener(
						'submit',
						this.handleSubmit.bind(this)
					)
					this.formTarget.submit()
				}
			}
		})
	}
}
