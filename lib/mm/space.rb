module MM; end

class MM::Space
  VERSION = "1.0.0"
  def initialize metric, delta = 0.001
    @metric = metric
    @delta = delta
    @boundaries = nil
    @adjacent_points_function = nil
    @cost_function = nil
  end

  attr_accessor :delta
  attr_reader :max_distance, :metric, :boundaries
  attr_writer :adjacent_points_function, :cost_function

  def morph start_morph, to: nil 
    search = MM::Search.new(start_morph)
    search.cost_function = cost_function start_morph, to
    search.adjacent_points_function = adjacent_points_function
    search.delta = @delta
    found = search.find
    # Transpose the morph so that it begins at 1/1
    if found
      if found[0].respond_to? :reciprocal
        found.map {|x| x * found[0].reciprocal}
      else
        found
      end
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
    @cost_function ||
    ->(current_point) {
      @metric.zip(to).inject(0) {|memo, x|
        distance = x[0].call(start_morph, current_point)
        unless @boundaries.nil?
          start_to_lowest = x[0].call(start_morph, @boundaries[0][0])
          current_to_lowest = x[0].call(current_point, @boundaries[0][0])
          if start_to_lowest > current_to_lowest
            distance = distance * -1.0
          end
        end
        memo = memo + (distance - x[1]).abs ** 2
      } ** 0.5
    }
  end

  # All repeated permutations of a given morph
  def adjacent_points_function
    @adjacent_points_function ||
    ->(current_point) {
      current_point.repeated_permutation(current_point.size)
    }
  end

  def boundaries= boundaries
    @boundaries = boundaries
    self.max_distance = boundaries.zip(@metric).map {|boundary_metric|
      boundary_metric[1].call(*boundary_metric[0])
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

