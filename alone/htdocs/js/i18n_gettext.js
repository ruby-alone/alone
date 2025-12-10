/*
  サンプル i18n_gettext 用 JavaScript
*/

console.log( _("in i18n_gettext.js"));

$("#ID001").text(_("messages in JavaScript."));


$("#locale").on("change", function() {
  const selected_value = $(this).val();
  console.log( selected_value );
  const new_url = Alone.make_uri( {action:"change_locale", locale:selected_value});
  console.log( new_url );
  window.location.replace( new_url );
  //window.location.href = new_url;

});
