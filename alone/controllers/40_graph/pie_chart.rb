require 'al_graph_pie'

#
# コントローラへ、円グラフ用アクションを追加
#
class AlControllerGraph < AlController

  # シンプル
  def action_pie_sample_01
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    graph = AlGraphPie.new
    graph.add_data(ydata1, labels)

    graph.draw
  end


  # セパレート
  def action_pie_sample_02
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    graph = AlGraphPie.new
    ds = graph.add_data(ydata1, labels)
    ds[2].separate

    graph.draw
  end


  # JavaScriptイベント
  def action_pie_sample_03
    ydata1 = [5, 3, 6, 3, 2, 5, 6]
    labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

    graph = AlGraphPie.new
    ds = graph.add_data(ydata1, labels)
    ds.each_with_index do |item, i|
      item.at_piece['onclick'] = "alert('at #{labels[i]}, value #{ydata1[i]}')"
    end

    graph.draw
  end

end
