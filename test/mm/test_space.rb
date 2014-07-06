require "minitest/autorun"
require "mm/space"
require "mm"

class TestMM < Minitest::Test; end

class TestMM::TestSpace < Minitest::Test
  def setup
    @x = MM::Metric.olm intra_delta: :tenney, inter_delta: :abs
    @y = MM::Metric.olm intra_delta: :log_ratio, inter_delta: :abs
    @space = MM::Space.new [@x, @y], 0.5
  end

  # Testing the attribute methods
  def test_max_distance_multi_dimensional
    @space.max_distance = [8.414, 3.0]
    assert_equal [8.414, 3.0], @space.max_distance
  end
  def test_max_distance_single_dimensional_sets_properly
    @space.max_distance = 8.414
    assert_equal [8.414], @space.max_distance
  end
  def test_set_and_get_metric_multi_dimensional
    @space.metric = [@y, @x]
    assert_equal MM::Deltas.singleton_method(:tenney),
      @space.metric[1].instance_variable_get(:@intra_delta)
  end
  def test_metric_single_dimensional_sets_properly
    @space.metric = @y
    assert_equal MM::Deltas.singleton_method(:log_ratio), 
      @space.metric[0].instance_variable_get(:@intra_delta)
  end

  # Testing that the cost function is the root of sum of squares
  def test_cost_function
    cost = @space.cost_function(start_morph, [0.4, 0.4])
    assert_in_delta 0.5657, cost.call(start_morph)
  end

  # Testing the morphing methods
  def test_morph_to_not_nil
    refute_nil new_morph
  end
  def test_morph_includes_origin
    assert_includes new_morph, MM::Ratio.from_s("1/1")
  end
  def test_morph_same_length
    assert_equal start_morph.length, new_morph.length
  end
  def test_morph_proper_distance_away
    @space.max_distance = [4.907, 0.263]
    x_distance = @x.call(start_morph, new_morph)
    y_distance = @y.call(start_morph, new_morph)
    root_of_sum_of_squares = (x_distance**2 + y_distance**2) ** 0.5
    assert_in_delta 0.5657, root_of_sum_of_squares, 0.5
  end

  # Testing that the whole block situation works
  def test_morph_in_block
    # Have to assign as a proper local variable, rather than method
    start = start_morph
    @space.enter do |s| 
      s.delta = 0.001
      morph start, to: [0.1, -0.1] 
    end
  end

  # Some helper buddies
  def start_morph
    @start_morph ||= %w(1/1 5/4 3/2).map {|x| MM::Ratio.from_s(x)}
  end
  def new_morph
    @new_morph ||= @space.morph start_morph, to: [0.4, 0.4]
  end

  attr_writer :new_morph
end

