/*
 * alone : application framework for small embedded systems.
 *               Copyright (c) 2009-2017 Inas Co Ltd. All Rights Reserved.
 *               Copyright (c) 2010-2017 FAR END Technologies Corporation.
 *               All Rights Reserved.
 *
 * This file is destributed under BSD License. Please read the COPYRIGHT file.
 */


/**
  Aloneオブジェクトコンテナ
*/
function Alone()
{
}


/**
  URIの生成
  @param  [Hash]	arg
  @return [String]	URI (http://example.com/cgi-bin/alone.cgi?ctrl=....)
*/
Alone.make_uri = function( arg )
{
  var ctrl = "";
  var result;
  if( arg == undefined ) arg = [];

  if( arg["ctrl"] ) {
    result = arg["ctrl"].match( /([a-zA-Z0-9_\-\/]*)/ );
  } else {
    result = location.search.match( /ctrl=([a-zA-Z0-9_\-\/]*)/ );
  }
  if( result ) {
    ctrl = result[1];
  }

  var uri = location.protocol + "//" + location.host + location.pathname;
  if( this.make_uri_base != undefined ) {
    uri = this.make_uri_base;
    if( uri.indexOf( "?ctrl=" ) == -1 ) {
      uri += "?ctrl=" + ctrl;
    }
  } else {
    uri += "?ctrl=" + ctrl;
  }
  for( var i in arg ) {
    if( i == "ctrl" ) continue;
    uri += "&" + i + "=" + encodeURIComponent( arg[i] );
  }
  return uri;
};


/**
  コントローラ名を得る
*/
Alone.ctrl = function()
{
  var ctrl = "";
  var result = location.search.match( /ctrl=([a-zA-Z0-9_\-\/]*)/ );
  if( result ) ctrl = result[1];

  return ctrl;
};


/**
  アクション名を得る
*/
Alone.action = function()
{
  var action = "";
  var result = location.search.match( /action=([a-zA-Z0-9_\-\/]*)/ );
  if( result ) action = result[1];

  return action;
};


/**
  オブジェクトを表示 (for debug)
*/
Alone.list_properties = function( obj, obj_name )
{
  var res = "";
  for( var i in obj ) {
    res += obj_name + "." + i + "=" + obj[i] + "\n";
  }
  alert( res );
};


/**
  AJAX通信
  @note
   jQueryが読み込まれていたら、そちらを使う。
*/
Alone.ajax = function( uri, options )
{
  if( typeof jQuery != "undefined" ) {
    return jQuery.ajax( uri, options );	// use jQuery.
  }

  // emulate jQuery.ajax, but very tiny.
  if( options.cache == undefined ) options.cache = true;
  if( options.async == undefined ) options.async = true;

  // make XMLHttpRequest object.
  var xhr = false;
  if( window.XMLHttpRequest ) {
    xhr = new XMLHttpRequest();
  } else if( window.ActiveXObject ) {
    xhr = new ActiveXObject( "Microsoft.XMLHTTP" );
  }
  if( ! xhr ) return false;

  // cache option
  if( ! options.cache ) {
    if( uri.indexOf( "?" ) == -1 ) {
      uri += "?_=" + (new Date()).valueOf();
    } else {
      uri += "&_=" + (new Date()).valueOf();
    }
  }

  // ready request.
  var data = null;
  var reason = "error";
  var timer;
  xhr.open( "GET", uri, options.async );
  xhr.onreadystatechange = function() {
    if( xhr.readyState != 4 ) return;
    if( timer ) clearTimeout( timer );

    if( xhr.status == 200 ) {
      reason = "success";
      switch( options.dataType ) {
      case "xml":
	data = xhr.responseXML;
	break;
      case "html":
	data = xhr.responseText;
	break;
      case "json":
	data = JSON.parse( xhr.responseText );
	break;
      default:
	break;
      }
      if( options.success ) {
	options.success( data, reason, xhr );
      }
    } else {
      if( options.error ) {
	options.error( xhr, reason );
      }
    }
    if( options.complete ) {
      options.complete( xhr, reason );
    }
  };

  // set timeout
  if( options.timeout ) {
    timer = setTimeout( function() {
      if( xhr.readyState != 4 ) {
	xhr.abort();
	reason = "timeout";
      }
    }, options.timeout );
  }

  // go
  xhr.send("");

  return xhr;
};


/**
  HTML特殊文字のエスケープ
  @param  [String]  s	ソース文字列
  @return [String]	変換後文字列
*/
Alone.escape_html = function( s )
{
  return s.replace( /[<>&"']/g, function( matched_char ) {
    return {'<':'&lt;', '>':'&gt;', '&':'&amp;', '"':'&quot;', "'":'&#39;' }[matched_char];
  });
};


/**
  HTML特殊文字のエスケープ with改行文字
  @param  [String]  s	ソース文字列
  @return [String]	変換後文字列
*/
Alone.escape_html_br = function( s )
{
  return s.replace( /[<>&"']|\r?\n/g, function( matched_char ) {
    return {'<':'&lt;', '>':'&gt;', '&':'&amp;', '"':'&quot;', "'":'&#39;', "\r\n":'<br>', "\n":"<br>" }[matched_char];
  });
};


/**
  Dateオブジェクトを文字列に変換
  @param  [Date]	対象オブジェクト
  @param  [String]	変換文字列
  @return [String]	変換後文字列
*/
Alone.strftime = function( d, fmt )
{
  var pattern = /%[a-z%]/gi;
  var day1 = [ "Sunday","Monday","Tuesday","Wednesday",
	       "Thursday","Friday","Saturday" ];
  var day2 = [ "Sun","Mon","Tue","Wed","Thu","Fri","Sat" ];
  var mon1 = [ "January","February","March","April",
	       "May","June","July","August",
	       "September","October","November","December" ];
  var mon2 = [ "Jan","Feb","Mar","Apr",
	       "May","Jun","Jul","Aug",
	       "Sep","Oct","Nov","Dec" ];

  var result;
  var pos = 0;
  var ret = "";
  while((result = pattern.exec(fmt)) != null) {
    ret += fmt.substring( pos, result.index );
    pos = pattern.lastIndex;
    switch( result[0] ) {
    case "%A":
      ret += day1[ d.getDay() ];
      break;
    case "%a":
      ret += day2[ d.getDay() ];
      break;
    case "%B":
      ret += mon1[ d.getMonth() ];
      break;
    case "%b":
    case "%h":
      ret += mon2[ d.getMonth() ];
      break;
    case "%C":
      ret += ("" + d.getFullYear()).slice(0,-2);
      break;
    case "%d":
      ret += ("0" + d.getDate()).slice(-2);
      break;
    case "%e":
      ret += (" " + d.getDate()).slice(-2);
      break;
    case "%F":
      ret += d.getFullYear() +
	"-" + ("0" + (d.getMonth()+1)).slice(-2) +
	"-" + ("0" + d.getDate()).slice(-2);
      break;
    case "%H":
      ret += ("0" + d.getHours()).slice(-2);
      break;
    case "%I":
      ret += ("0" + d.getHours() % 12).slice(-2);
      break;
    case "%j":
      var d1 = new Date(d.getTime());
      d1.setMonth(0,1);
      var days = (d.getTime() - d1.getTime()) / (60*60*24*1000) + 1;
      ret += ("00" + days).slice(-3);
      break;
    case "%k":
      ret += (" " + d.getHours()).slice(-2);
      break;
    case "%L":
      ret += ("00" + d.getMilliseconds()).slice(-3);
      break;
    case "%l":
      ret += (" " + d.getHours() % 12).slice(-2);
      break;
    case "%M":
      ret += ("0" + d.getMinutes()).slice(-2);
      break;
    case "%m":
      ret += ("0" + (d.getMonth()+1)).slice(-2);
      break;
    case "%n":
      ret += "\n";
      break;
    case "%P":
      ret += ["am","pm"][ Math.floor(d.getHours() / 12) ];
      break;
    case "%p":
      ret += ["AM","PM"][ Math.floor(d.getHours() / 12) ];
      break;
    case "%R":
      ret += ("0" + d.getHours()).slice(-2) +
	":" + ("0" + d.getMinutes()).slice(-2);
      break;
    case "%r":
      ret += ("0" + d.getHours() % 12).slice(-2) +
	":" + ("0" + d.getMinutes()).slice(-2) +
	":" + ("0" + d.getSeconds()).slice(-2) +
	" " + ["AM","PM"][ Math.floor(d.getHours() / 12) ];
      break;
    case "%S":
      ret += ("0" + d.getSeconds()).slice(-2);
      break;
    case "%T":
      ret += ("0" + d.getHours()).slice(-2) +
	":" + ("0" + d.getMinutes()).slice(-2) +
	":" + ("0" + d.getSeconds()).slice(-2);
      break;
    case "%t":
      ret += "\t";
      break;
    case "%u":
      ret += d.getDay() == 0 ? 7 : d.getDay();
      break;
    case "%w":
      ret += d.getDay();
      break;
    case "%Y":
      ret += d.getFullYear();
      break;
    case "%y":
      ret += ("0" + d.getYear()).slice(-2);
      break;
    case "%%":
      ret += "%";
      break;
    }
  }

  ret += fmt.substring( pos, fmt.length );
  return ret;
}



/**
  IPC オブジェクトコンストラクタ
  @param  [String]	ipc_node (ex: "/tmp/al_worker") 必須では無い
*/
Alone.Ipc = function( ipc_node )
{
  this.ipc_node = ipc_node;	// not indispensable
  this.options = {
    type: "GET",
    dataType: "json",
    cache: false };
  this.status_code = "";
  this.data = {};
};


/**
  IPC call
  @param  [String]	ipc_name コールするIPC
  @param  [Hash]	ipc_arg  引数
  @return [Object]	XmlHttpRequestオブジェクト
*/
Alone.Ipc.prototype.call = function( ipc_name, ipc_arg )
{
  var me = this;
  var uri_param;
  if( this.options.type == "GET" ) {
    uri_param = { action: "ipc",
		  ipc: ipc_name,
		  arg: JSON.stringify(ipc_arg == undefined ? {} : ipc_arg)
		};
    if( this.ipc_node ) {
      uri_param.ipc_node = this.ipc_node;
    }

  } else if( this.options.type == "POST" ) {
    uri_param = { action: "ipc" };
    this.options.data = { ipc: ipc_name,
			  arg: JSON.stringify(ipc_arg) };
    if( this.ipc_node ) {
      this.options.data.ipc_node = this.ipc_node;
    }
  }

  this.options.success = function( data, status, xhr ) {
    me.status_code = data[0];
    me.data = data[1];
    if( me.success ) {
      me.success( me.data, status, xhr );
    }
  };

  this.options.error = function( xhr, status, ex ) {
    me.status_code = "500 " + status;
    me.data = null;
    if( me.error ) {
      me.error( xhr, status, ex );
    }
  };

  if( this.complete ) {
    this.options.complete = this.complete;
  }

  return Alone.ajax( Alone.make_uri( uri_param ), this.options );
};
