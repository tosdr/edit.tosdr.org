//= require jquery
//= require jquery_ujs
//= require select2
//= require bootstrap-sprockets
//= require_tree .

var initSelect2 = function(){

    // function that will initialize the select2 plugin, to be triggered later
    var renderSelect = function(){
        $('section#formSection select').each(function(){
            $(this).select2({
                'dropdownCssClass': 'dropdown-hover',
                'width': '',
                'minimumResultsForSearch': -1,
            });
        })
    };

    // create select2 HTML elements
    var style = document.createElement('link');
    var script = document.createElement('script');
    style.rel = 'stylesheet';
    style.href = 'https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.4/css/select2.min.css';
    script.type = 'text/javascript';
    script.src = 'https://cdnjs.cloudflare.com/ajax/libs/select2/4.0.4/js/select2.full.min.js';

    // trigger the select2 initialization once the script tag has finished loading
    script.onload = renderSelect;

    // render the style and script tags into the DOM
    document.getElementsByTagName('head')[0].appendChild(style);
    document.getElementsByTagName('head')[0].appendChild(script);
};

initSelect2();

$(document).ready(function() {
  $('select#forSelect').select2();
});
