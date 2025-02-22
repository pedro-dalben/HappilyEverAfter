// app/javascript/controllers/select_all_controller.js
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
	static targets = ['checkbox']

	toggle(event) {
		const checked = event.target.checked
		this.checkboxTargets.forEach((el) => {
			el.checked = checked
		})
	}
}
