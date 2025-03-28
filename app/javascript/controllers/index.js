// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from './application'

import DeleteController from './delete_controller'
application.register('delete', DeleteController)

import FlashController from './flash_controller'
application.register('flash', FlashController)

import HelloController from './hello_controller'
application.register('hello', HelloController)

import MaskController from './mask_controller'
application.register('mask', MaskController)

import SelectAllController from './select_all_controller'
application.register('select-all', SelectAllController)

import SweetAlertController from './sweet_alert_controller'
application.register('sweet-alert', SweetAlertController)

import ToastController from './toast_controller'
application.register('toast', ToastController)
