class RandomNumberService
  # Generate a random number with optional min and max bounds
  def self.generate(min: 1, max: 100)
    validate_bounds!(min, max)
    rand(min..max)
  end

  # Generate a random float between 0 and 1
  def self.generate_float
    rand
  end

  private

  def self.validate_bounds!(min, max)
    raise ArgumentError, "min must be less than or equal to max" if min > max
    raise ArgumentError, "min and max must be integers" unless min.is_a?(Integer) && max.is_a?(Integer)
  end
end
