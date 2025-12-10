/*
  サンプル i18n_gettext 用 JavaScript
*/

// span id="ID001" タグに挿入する翻訳対象メッセージ
$("#ID001").text(_("messages in JavaScript."));

/*
  Localeプルダウン変更時の処理
*/
$("#locale").on("change", function() {
  const new_url = Alone.make_uri( {action:"change_locale", locale:$(this).val()} );
  console.log( new_url );
  window.location.replace( new_url );
  //window.location.href = new_url;
});
