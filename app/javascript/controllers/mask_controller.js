import { Controller } from '@hotwired/stimulus'
import Inputmask from 'inputmask'

export default class extends Controller {
	static values = { pattern: String }

	connect() {
		if (this.patternValue) {
			Inputmask(this.patternValue).mask(this.element)
		} else {
			console.warn('No mask pattern provided for', this.element)
		}
	}
}
