# coding: utf-8
require 'al_graph_xy'

#
# コントローラへ、XYグラフ用アクションを追加
#
class AlControllerGraph < AlController

  # XYグラフ
  def action_xy_sample_01
    # XとYを別々の配列で指定する方法
    xdata = [0.1, 1.0, 1.1, 1.2, 1.3, 1.0, 0.0]
    ydata = [5.0, 5.0, 4.9, 4.7, 4.0, 2.0, 0.0]

    graph = AlGraphXY.new
    graph.add_data(xdata, ydata)

    graph.draw
  end


  # 海水中の溶存酸素量
  def action_xy_sample_02
    # 気象庁公開情報を参考にデータを引用
    # XとYをペアで指定する方法
    data1 = [[330,0],  [318,100], [180,200], [105,300], [70,400],  [44,500],
             [27,750], [37,1000], [50,1500], [80,2000], [108,2500]]
    data2 = [[220,0],  [220,100], [221,200], [200,300], [180,500], [118,750],
             [65,1000],[72,1500], [100,2000],[125,2500]]
    data3 = [[195,0],  [200,50],  [170,100], [100,150], [42,200],  [48,300],
             [63,400], [70,500],  [80,1000], [92,1500], [110,2000],[120,2500]]
    data4 = [[280,0],  [270,50],  [265,100], [268,200], [265,300], [240,400],
             [225,500],[210,1000],[205,1500],[205,2500]]

    graph = AlGraphXY.new(500, 500)
    graph.add_xaxis_title("溶存酸素量 (μmol/kg)")
    graph.add_yaxis_title("水深 (m)")
    graph.x_axis.at_labels[:format] = "%d"
    graph.y_axis.at_labels[:format] = "%d"
    graph.y_axis.reverse()      # Ｙ軸上下反転

    graph.add_data_pair(data1, "亜寒帯")
    graph.add_data_pair(data2, "亜熱帯")
    graph.add_data_pair(data3, "熱帯")
    graph.add_data_pair(data4, "日本海")

    graph.draw
  end

end
