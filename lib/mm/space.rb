module MM; end

class MM::Space
  VERSION = "1.0.0"

  attr_accessor :delta, :search_klass
  attr_reader :max_distance, :metric, :boundaries
  attr_writer :adjacent_points_function, :cost_function

  # Initialization method for MM::Space
  #
  # metric - Array of MM::Metrics, where each metric corresponds to a dimension
  #   in the MM::Space.
  # opts - Hash with additional parameters. (default: {})
  #   :delta - The delta of the MM::Search function used in #morph.
  #     (default: 0.001)
  #   :boundaries - Array of same size as metric containing pairs [low,
  #     high], which should be the bounding vectors of a given MM::Space.
  #   :adjacent_points_function - Proc to use as the
  #     adjacent_points_function for MM::Search in #morph.
  #   :cost_function - Proc to use for cost_function for MM::Search in
  #     #morph.
  #   
  # Returns an MM::Space object
  def initialize metric, opts = {}
    @metric = metric
    @search_klass = opts[:search_klass] || MM::Search
    @delta = opts[:delta] || 0.001
    @boundaries = opts[:boundaries]
    @adjacent_points_function = opts[:adjacent_points_function]
    @cost_function = opts[:cost_function]
  end

  # Morphs to a given point within the space
  #
  # start_morph - Enumerable object of things to morph from
  # to - Array to morph to, with one element for each dimension
  #
  # Returns Array of resulting MM::Ratio objects
  def morph start_morph, to: nil, current_point: nil
    if current_point
      # puts "Finding from #{current_point.map {|r| r.join ' '}}"
      searcher(start_morph, to).find_from_point current_point
    else
      searcher(start_morph, to).find
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

  # Default cost_function to use if no other one is specified. Takes the root of
  # the sum of the squares, or the generalized Euclidean distance.
  #
  # start_morph - morph to begin the morph from. This should be a valid morph in
  #   the space (i.e., not out of bounds), and should also work with MM::Metric.
  # to - Destination vector. There should be one dimension in the Array for each
  #   element in @metric
  #
  # Returns a Proc that calculates how much the current difference vector
  # differs from the requested difference vector.
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

  # Default adjacent_points_function. It takes all repeated permutations of a
  # given morph.
  #
  # Returns the adjacent_points_function Proc.
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
  
  # Allows for morphing within a given block. 
  #
  # locals - Hash of key-value pairs where the key is the name of the local
  #   variable to be created and the value is the value of that variable. Note
  #   that it actually creates *methods*, rather than *variables*, and that these
  #   methods refer to instance variables that are then removed. It could get
  #   buggy if you were to try to create a variable that was the same name as an
  #   existing method or class variable. (default: {})
  # block - Block to evaluate within the context of the instance.
  #
  # Returns the last element returned by the block.
  def enter locals = {}, &block
    create_local_variables locals
    output = instance_eval &block
    remove_local_variables locals
    output
  end

  protected 

  def searcher start_morph, to
    search = @search_klass.new(start_morph)
    search.cost_function = cost_function start_morph, to
    search.adjacent_points_function = adjacent_points_function
    search.delta = @delta
    search
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

