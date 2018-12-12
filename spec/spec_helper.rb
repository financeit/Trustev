require 'rspec'
require 'trustev'

RSpec.configure do |config|
  config.before(:all) do
    Trustev.configure do |trustev_config|
      trustev_config.url = 'www.example.com'
      trustev_config.username = 'foo'
      trustev_config.password = 'bar'
      trustev_config.solution_set_id = 'baz'
    end
  end
end
