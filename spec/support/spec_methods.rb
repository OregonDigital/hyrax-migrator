# frozen_string_literal: true

module SpecMethods
  def capture_stdout(&blk)
    old = $stdout
    $stdout = fake = StringIO.new
    blk.call
    fake.string
  ensure
    $stdout = old
  end

  RSpec.configure do |config|
    config.include SpecMethods
  end
end
