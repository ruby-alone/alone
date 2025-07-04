/*
 * alone : application framework for embedded systems.
 *               Copyright (c) 2009-2013 Inas Co Ltd. All Rights Reserved.
 *               Copyright (c) 2010-2013 FAR END Technologies Corporation.
 *               All Rights Reserved.
 *
 * This file is destributed under BSD License. Please read the LICENSE file.
 *
 * sample program "chat" / control script.
 */


/*
  initializer
*/
window.onload = function() {
    console.log( "================ START ================" );
    document.getElementById( "btn_say" ).onclick = say;
    document.getElementById( "txt_myname" ).focus();

    // Server Sent Event の有無で処理をわける。
    if( window.EventSource ) {
	listen_ssev();
    } else {
	listen();
    }
};


/*
  発言

  (note)
  Alone.Ipc オブジェクトを生成し、callメソッドでサーバ(Worker)の
  "say" メソッドを呼び出す。
*/
function say()
{
    var ipc = new Alone.Ipc();
    var txt_myname = document.getElementById( "txt_myname" );
    var txt_say = document.getElementById( "txt_say" );

    ipc.call( "say",
	      { myname: txt_myname.value, message: txt_say.value } );
    txt_say.value = "";
    txt_say.focus();
}


/*
  メッセージ取得 by Server Sent Event

  (note)
  ServerSentEventの使い方は十分簡単なので、wrapすることなく
  直接利用することで透明性を確保する方が得策と判断した。

  EventSourceオブジェクトを生成し、onmessage コールバックによって
  画面に反映する。
  このサンプルでは、データが簡単なのでプレーンテキストで受信して
  改行でsplitするように設計したが、複雑な場合はサーバ側でJSONエンコードし、
  クライアント側でJSON.parse() する方が良いだろう。
*/
function listen_ssev()
{
    console.log( "CALLED: listen_ssev()" );

    var uri = Alone.make_uri({ action:"ssev", ipc:"listen_ssev" });
    var evs = new EventSource( uri );

    evs.onmessage = function( ev ) {
	console.log( "CALLED: onmessage() / lastEventId=" + ev.lastEventId );

	var data = ev.data.split( "\n" );
	var html = '<p><div style="float: right;">';
	html += Alone.escape_html( data[1] ) + '</div>';
	html += '( ' + Alone.escape_html( data[0] ) + ' )<br>';
	for( var i = 2; i < data.length; i++ ) {
	    html += Alone.escape_html( data[i] ) + "<br>";
	}
	html += "</p>";

	var e = document.getElementById( "pane_listen" );
	e.innerHTML = e.innerHTML + html;
	e.scrollTop = e.scrollHeight;
    }
}


/*
  メッセージ取得

  (note)
  通常のipc call のみを使ったメッセージ取得。
*/
function listen( tid )
{
    var e = document.getElementById( "pane_listen" );
    var ipc = new Alone.Ipc();
    if( tid == undefined ) tid = 0;

    // アクセス成功時の処理
    ipc.success = function( data, status )
    {
	console.log( "success: " + status + " data length=" + data.length  );
	var tid = 0;
	for( var i = 0; i < data.length; i++ ) {
	    var html = '<p><div style="float: right;">';
	    html += Alone.escape_html( data[i].timestamp ) + '</div>';
	    html += '( ' + Alone.escape_html( data[i].myname ) + ' )<br>';
	    html += Alone.escape_html( data[i].message ).replace( /\n/, "<br>" );
	    html += "</p>";

	    e.innerHTML = e.innerHTML + html;
	    tid = data[i].TID;
	}
	e.scrollTop = e.scrollHeight;
	listen( tid + 1 );
    };

    // アクセスエラー時の処理
    ipc.error = function( xhr, status )
    {
	console.log( "listen(): ERROR " + status );
	e.innerHTML = "";
	setTimeout( listen, 5000 );
    };

    // IPC開始
    ipc.call( "listen", {TID: tid} );
}


/*
  check & add console.log method
*/
if( ! window.console ) {
    window.console = function() {};
    window.console.log = function() {};
}
