# coding: utf-8

class PDF::Reader
  class TransformationMatrix
    attr_reader :a, :b, :c, :d, :e, :f

    def initialize(a, b, c, d, e, f)
      @a, @b, @c, @d, @e, @f = a, b, c, d, e, f
    end

    def inspect
      "#{a}, #{b}, 0,\n#{c}, #{d}, #{0},\n#{e}, #{f}, 1"
    end

    def to_a
      [@a,@b,0,
       @c,@d,0,
       @e,@f,1]
    end

    # multiply two 3x3 matrices
    # the second is represented by the last 9 scalar arguments
    # store the results back into the first (to avoid allocating memory)
    #
    # NOTE: When multiplying matrixes, ordering matters. Double check
    #       the PDF spec to ensure you're multiplying things correctly.
    #
    # NOTE: see Section 8.3.3, PDF 32000-1:2008, pp 119
    #
    # NOTE: The if statements in this method are ordered to prefer optimisations
    #       that allocate fewer objects
    #
    # TODO: it might be worth adding an optimised path for vertical
    #       displacement to speed up processing documents that use vertical
    #       writing systems
    #
    #
    def multiply!(a,b=nil,c=nil, d=nil,e=nil,f=nil)
      if b == 0 && c == 0 && f == 0
        if a == 1 && d == 1
          if e == 0
            # the identity matrix, no effect
            self
          else
            # the other matrix is a horizontal displacement
            horizontal_displacement_multiply!(a,b,c,d,e,f)
          end
        else
          # the other matrix is an xy scale
          xy_scaling_multiply!(a,b,c,d,e,f)
        end
      elsif @b == 0 && @c == 0 && @f == 0
        if @a == 1 && @d == 1
          if @e == 0
            # I'm the identity matrix, so just copy values across
            @a = a
            @b = b
            @c = c
            @d = d
            @e = e
            @f = f
          else
            # I'm a horizontal displacement
            horizontal_displacement_multiply_reversed!(a,b,c,d,e,f)
          end
        else
          # I'm a xy scale
          xy_scaling_multiply_reversed!(a,b,c,d,e,f)
        end
      else
        faster_multiply!(a,b,c, d,e,f)
      end
    end

    private

    # Multiplying a matrix to apply a horizontal displacement is super common,
    # so use an optimised method that achieves the same result with significantly
    # less object allocations.
    #
    # At the time of writing, the entire test suite uses this optimised multiply
    # method 23687 times and the regular multiply 718.
    #
    def horizontal_displacement_multiply!(a2,b2,c2, d2,e2,f2)
      @e = @e + e2
      self
    end

    def horizontal_displacement_multiply_reversed!(a2,b2,c2,d2,e2,f2)
      newa = a2
      newb = b2
      newc = c2
      newd = d2
      newe = (@e * a2) + e2
      newf = (@e * b2) + f2
      @a, @b, @c, @d, @e, @f = newa, newb, newc, newd, newe, newf
      self
    end

    def xy_scaling_multiply!(a2,b2,c2,d2,e2,f2)
      newa = @a * a2
      newb = @b * d2
      newc = @c * a2
      newd = @d * d2
      newe = @e * a2
      newf = @f * d2
      @a, @b, @c, @d, @e, @f = newa, newb, newc, newd, newe, newf
      self
    end

    def xy_scaling_multiply_reversed!(a2,b2,c2,d2,e2,f2)
      newa = @a * a2
      newb = @a * b2
      newc = @d * c2
      newd = @d * d2
      newe = e2
      newf = f2
      @a, @b, @c, @d, @e, @f = newa, newb, newc, newd, newe, newf
      self
    end

    # A general solution to multiplying two 3x3 matrixes. This is correct in all cases,
    # but slower due to excessive object allocations. It's not actually used in any
    # active code paths, but is here for reference
    #
    def regular_multiply!(a2,b2,c2,d2,e2,f2)
      newa = (@a * a2) + (@b * c2) + (0 * e2)
      newb = (@a * b2) + (@b * d2) + (0 * f2)
      newc = (@c * a2) + (@d * c2) + (0 * e2)
      newd = (@c * b2) + (@d * d2) + (0 * f2)
      newe = (@e * a2) + (@f * c2) + (1 * e2)
      newf = (@e * b2) + (@f * d2) + (1 * f2)
      @a, @b, @c, @d, @e, @f = newa, newb, newc, newd, newe, newf
      self
    end

    def faster_multiply!(a2,b2,c2, d2,e2,f2)
      newa = (@a * a2) + (@b * c2)
      newb = (@a * b2) + (@b * d2)
      newc = (@c * a2) + (@d * c2)
      newd = (@c * b2) + (@d * d2)
      newe = (@e * a2) + (@f * c2) + e2
      newf = (@e * b2) + (@f * d2) + f2
      @a, @b, @c, @d, @e, @f = newa, newb, newc, newd, newe, newf
      self
    end
  end
end
