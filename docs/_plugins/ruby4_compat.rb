# Compatibility shim for legacy Jekyll/Liquid on Ruby 4.0.
# Ruby removed taint-related methods; they no longer provide security guarantees.

class Object
  def tainted?
    false
  end

  def taint
    self
  end

  def untaint
    self
  end
end
