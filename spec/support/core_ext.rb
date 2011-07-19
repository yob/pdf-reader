# coding: utf-8

class Array
  def to_h
    Hash[*self.flatten]
  end
end
