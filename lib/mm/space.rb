module MM; end

class MM::Space
  VERSION = "1.0.0"
  def initialize metric, delta = 0.001
    @metric = metric
    @delta = delta
  end

  attr_accessor :delta
  attr_reader :max_distance, :metric

  def morph start_morph, to: nil 
    search = MM::Search.new(start_morph)
    search.cost_function = cost_function start_morph, to
    search.adjacent_points_function = adjacent_points_function
    search.delta = @delta
    found = search.find
    # Transpose the morph so that it begins at 1/1
    if found
      found.map {|x| x * found[0].reciprocal}
    else
      nil
    end
  end

  def max_distance= d
    if d.respond_to? :each
      # Assign global maxes to each dimension
      d.zip(@metric).each do |distance_and_metric|
        distance_and_metric[1].scale = MM::Scaling.get_global(distance_and_metric[0])
      end
      @max_distance = d
    elsif d.is_a? Numeric
      # Wrap it in an Array so it can be zipped
      self.max_distance = [d]
    else
      raise ArgumentError, "arg to max_distance= must respond_to? #zip or be Numeric"
    end
  end
  def metric= m
    if m.respond_to? :each
      @metric = m
    elsif m.respond_to? :call
      # Wrap it in an Array so it can be zipped
      self.metric = [m]
    else
      raise ArgumentError, "arg to metric= must respond_to? #each or #call"
    end
  end

  # root of sum of squared errors
  def cost_function start_morph, to
    ->(current_point) {
      @metric.zip(to).inject(0) {|memo, x|
        memo = memo + (x[0].call(start_morph, current_point) - x[1]).abs ** 2
      } ** 0.5
    }
  end

  # All repeated permutations of a given morph
  def adjacent_points_function
    ->(current_point) {
      current_point.repeated_permutation(current_point.size)
    }
  end

  def enter locals = {}, &block
    create_local_variables locals
    output = instance_eval(&block)
    remove_local_variables locals
    output
  end

  private 
  def create_local_variables locals
    locals.each do |name, value|
      define_singleton_method name do 
        value
      end
    end
  end
  def remove_local_variables locals
    locals.each do |name, value|
      self.singleton_class.class_eval do
        remove_method name
      end
    end
  end
end

