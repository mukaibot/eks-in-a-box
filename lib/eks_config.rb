class EksConfig
  MANDATORY_ATTRIBUTES = %w(name keypair private_subnets public_subnets region vpc_id)
  OPTIONAL_ATTRIBUTES  = %w(acm_ingress_cert_arn)

  def initialize
    (MANDATORY_ATTRIBUTES + OPTIONAL_ATTRIBUTES).each { |a| self.class.__send__(:attr_accessor, a.to_sym) }
  end

  def missing_attributes
    MANDATORY_ATTRIBUTES
      .select { |a| send(a.to_sym).nil? }
  end

  def valid?
    MANDATORY_ATTRIBUTES
      .map { |a| send(a.to_sym) }
      .none?(&:nil?)
  end
end
