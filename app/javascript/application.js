// Entry point for the build script in your package.json
import './controllers'
import '@hotwired/turbo-rails'
import * as Turbo from '@hotwired/turbo-rails'
import "./cart"

window.Turbo = Turbo
