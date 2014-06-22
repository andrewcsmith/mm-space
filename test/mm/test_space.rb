require "minitest/autorun"
require "mm/space"

module TestMM; end

class TestMM::TestSpace < MiniTest::Test
  def setup
    @x = MM::Metric.olm intra_delta: :tenney, inter_delta: :abs
    @y = MM::Metric.olm intra_delta: :ratio, inter_delta: :abs
    @space = Space.new [@x, @y]
  end
  def test_max_distance_multi_dimensional
    @space.max_distance = [8.414, 3.0]
    assert_equal [8.414, 3.0], @space.max_distance
  end
  def test_max_distance_single_dimensional
    @space.max_distance = 8.414
    assert_equal 8.414, @space.max_distance
  end
  def test_morph_to_not_nil
    setup_new_morph
    refute_nil @new_morph
  end
  def test_morph_includes_origin
    setup_new_morph
    assert_includes @new_morph, MM::Ratio.from_s("1/1")
  end
  def test_morph_same_length
    setup_new_morph
    assert_equal 5, @new_morph.length
  end
  def test_morph_proper_distance_away
    setup_new_morph
    assert_in_delta 0.4, @x.call(@start, @new_morph)
    assert_in_delta 0.4, @y.call(@start, @new_morph)
  end

  private

  def setup_new_morph
    @start = %w(1/1 5/4 3/2 8/7 9/8).map {|x| MM::Ratio.from_s(x)}
    @new_morph = @space.morph @start, to: [0.4, 0.4]
  end
end

