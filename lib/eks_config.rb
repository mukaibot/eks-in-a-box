class EksConfig
  MANDATORY_ATTRIBUTES = %w(name keypair private_subnets public_subnets region vpc_id)
  OPTIONAL_ATTRIBUTES  = %w(acm_ingress_cert_arn node_ebs_size node_type)

  DEFAULT_NODE_EBS_SIZE = 50
  DEFAULT_NODE_TYPE     = 't3.medium'

  def initialize
    (MANDATORY_ATTRIBUTES + OPTIONAL_ATTRIBUTES).each { |a| self.class.__send__(:attr_accessor, a.to_sym) }
    set_defaults
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

  private

  def set_defaults
    OPTIONAL_ATTRIBUTES.each do |attr|
      send("#{attr}=".to_sym, eval("default_#{attr}".upcase)) rescue NameError
    end
  end
end
