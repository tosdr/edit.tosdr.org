import 'jquery'
import 'popper.js'
import 'bootstrap'
import {} from 'jquery-ujs'

import "@fortawesome/fontawesome-free/css/all"

// Import the specific modules you may need (Modal, Alert, etc)
import { Tooltip, Popover, Modal } from "bootstrap"

// The stylesheet location we created earlier
require("../application.scss")

// If you're using Turbolinks. Otherwise simply use: jQuery(function () {
document.addEventListener("turbolinks:load", () => {
    // Both of these are from the Bootstrap 5 docs
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
    var tooltipList = tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new Tooltip(tooltipTriggerEl)
    })

    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
    var popoverList = popoverTriggerList.map(function(popoverTriggerEl) {
        return new Popover(popoverTriggerEl)
    })
})