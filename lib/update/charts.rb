# frozen_string_literal: true

module Update
  class Charts
    DEFAULTS = [
      {
        channel: 'stable',
        name: 'metrics-server',
        version: '2.0.4',
        params: {}
      }
    ].freeze
  end
end
