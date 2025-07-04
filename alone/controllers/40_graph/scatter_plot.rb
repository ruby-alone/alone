# coding: utf-8
require 'al_graph_scatter'

#
# コントローラへ、散布図用アクションを追加
#
class AlControllerGraph < AlController

  # 散布図1
  def action_scatter_sample_01
    # 竹村彰通(著) 統計　共立出版より引用
    data_m = [[172,70],[176,69],[170,70],[174,70],[170,62],
              [167,50],[175,75],[179,80],[162,60],[169,80]]
    data_f = [[157,42],[166,68],[160,55],[176,65],[164,51],
              [168,56],[159,45],[154,44],[168,45],[150,52]]

    graph = AlGraphScatter.new
    graph.add_data_pair( data_m, "Male" )
    graph.add_data_pair( data_f, "Female" )

    graph.add_main_title("散布図（身長、体重）")
    graph.add_xaxis_title("身長(cm)")
    graph.add_yaxis_title("体重(kg)")
    graph.x_axis.at_labels[:format] = "%d"
    graph.y_axis.at_labels[:format] = "%d"

    graph.draw
  end


  # バブルチャートにアレンジ
  def action_scatter_sample_02
    group_A_x =    [ 23,  24,  62   ,9]
    group_A_y =    [ -4,   5,  12, -10]
    group_A_size = [ 50,  40,  90,  20]

    group_B_x =    [ 39,  20,   5,  85]
    group_B_y =    [  0,  10, -14,  -6]
    group_B_size = [ 40,  50,  10,  40]
    group_label = ["農林", "製造", "建築土木", "その他"]

    graph = AlGraphScatter.new(800,600)
    graph.color_list = ["#88f", "#f88"]
    graph.shape_list = [:circle, :circle]

    graph.add_xaxis_title("X軸タイトル")
    graph.add_yaxis_title("Y軸タイトル")
    graph.x_axis.at_labels[:format] = "%.0f%%"
    graph.x_axis.min = 0
    graph.x_axis.max = 90
    graph.y_axis.at_labels[:format] = "%.0f%%"
    graph.y_axis.min = -15
    graph.y_axis.max = 25

    data = graph.add_data( group_A_x, group_A_y, "男性" )
    data.add_data_labels(:CENTER)
    data.labels = group_label
    data.at_data_labels[:font_size] = 20
    group_A_size.each_with_index {|sz,i|
      data.at_marker_several[i] = {:size=>sz, :stroke_width=>3,:stroke=>"#fff"}
    }

    data = graph.add_data( group_B_x, group_B_y, "女性" )
    data.add_data_labels(:CENTER)
    data.labels = group_label
    data.at_data_labels[:font_size] = 20
    group_B_size.each_with_index {|sz,i|
      data.at_marker_several[i] = {:size=>sz, :stroke_width=>3,:stroke=>"#fff"}
    }

    graph.draw
  end

end
