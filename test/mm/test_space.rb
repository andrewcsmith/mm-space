require "minitest/autorun"
require "mm/space"

module TestMM; end

class TestMM::TestSpace < MiniTest::Test
  def setup
    @x = MM::Metric.olm intra_delta: :tenney, inter_delta: :abs
    @y = MM::Metric.olm intra_delta: :ratio, inter_delta: :abs
    @space = Space.new [@x, @y]
  end

  # Testing the attribute methods
  def test_max_distance_multi_dimensional
    @space.max_distance = [8.414, 3.0]
    assert_equal [8.414, 3.0], @space.max_distance
  end
  def test_max_distance_single_dimensional_sets_properly
    @space.metric = @x
    @space.max_distance = 8.414
    assert_equal 8.414, @space.max_distance
  end
  def test_max_distance_single_dimensional_throws_error
    assert_raises ArgumentError do
      @space.max_distance = 8.414
    end
  end  
  def test_set_and_get_metric_multi_dimensional
    @space.metric = [@y, @x]
    assert_equal :tenney, @space.metric[1].intra_delta
  end
  def test_metric_single_dimensional_sets_properly
    @space.max_distance = nil
    @space.metric = @y
    assert_equal :ratio, @space.metric
  end
  def test_metric_single_dimensional_throws_error
    assert_raises ArgumentError do
      @space.metric = @y
    end
  end

  # Testing the morphing methods
  def test_morph_to_not_nil
    refute_nil new_morph
  end
  def test_morph_includes_origin
    assert_includes new_morph, MM::Ratio.from_s("1/1")
  end
  def test_morph_same_length
    assert_equal 5, new_morph.length
  end
  def test_morph_proper_distance_away
    assert_in_delta 0.4, @x.call(start_metric, new_morph)
    assert_in_delta 0.4, @y.call(start_metric, new_morph)
  end

  # Testing that the whole block situation works
  def test_morph_in_block
    @space.enter do |s|
      @new_morph = morph start_metric, to: [0.1, -0.1]
      assert_in_delta 0.1, @x.call(start_metric, new_morph)
      assert_in_delta -0.1, @y.call(start_metric, new_morph)
    end
  end

  private

  def start_metric
    @start_metric ||= %w(1/1 5/4 3/2 8/7 9/8).map {|x| MM::Ratio.from_s(x)}
  end
  def new_morph
    @new_morph ||= @space.morph start_metric, to: [0.4, 0.4]
  end
end

