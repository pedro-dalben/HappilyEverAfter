import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Hello, Stimulus teste! 2 3", this.element)
  }
  greet() {
    console.log("Hello, Stimulus!", this.element)
  }
}
