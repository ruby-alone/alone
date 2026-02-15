#!/usr/bin/env ruby
#
# alone : application framework for embedded systems.
#   Copyright (c) 2009-2010 Inas Co Ltd. All Rights Reserved.
#   Copyright (c) 2018-2026 Hirohito Higashi All Rights Reserved.
#   Copyright (C) 2020-2026 Shimane IT Open-Innovation Center.
#
# This file is destributed under BSD License. Please read the LICENSE file.
#
# ログインマネージャ
#
# (STRATEGY)
# requireされるだけで、動作開始する。
# セッション変数 al_user_idが設定されていれば、ログインしていると見なし、
# 設定されていなければ、ログインされていないと見なして、AL_LOGIN_URIに規定された
# ログイン画面のURIへリダイレクトする。

require 'al_session'

##
# ログインチェック
#
# (note)
# ログインしていなければ、ログインURIへリダイレクトする
#
if ! AlSession[:al_user_id]
  Alone::redirect_to( AL_LOGIN_URI )
  AlSession[:al_request_uri] = Alone::request_uri()
end
