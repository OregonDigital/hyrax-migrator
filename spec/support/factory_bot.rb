# frozen_string_literal:true

require 'shoulda/matchers'
require 'factory_bot'
FactoryBot.definition_file_paths << File.expand_path('../spec/factories', __dir__)
FactoryBot.find_definitions

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec

    # Choose one or more libraries:
    with.library :rails
  end
end
