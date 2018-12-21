class EksConfig
  ATTRIBUTES = %w(name keypair private_subnets public_subnets region vpc_id)

  def initialize
    ATTRIBUTES.each { |a| self.class.__send__(:attr_accessor, a.to_sym) }
  end

  def missing_attributes
    ATTRIBUTES
      .select { |a| send(a.to_sym).nil? }
  end

  def valid?
    ATTRIBUTES
      .map { |a| send(a.to_sym) }
      .none?(&:nil?)
  end
end
