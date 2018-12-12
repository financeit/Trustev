require 'services/data_converter'
require 'trustev/case'
require 'trustev/case_response_error_codes'
require 'trustev/version'

module Trustev
  class Configuration
    attr_accessor :url, :username, :password, :solution_set_id, :is_production
  end

  class << self
    def configure
      yield(configuration)
      configuration
    end

    def configuration
      @_configuration ||= Configuration.new
    end
  end
end
