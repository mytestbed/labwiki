require 'spec_helper'

describe 'search script in prepare panel' do
  include Capybara::DSL

  after do
    Capybara.reset_sessions!
  end

  it 'must return a list of matched fils' do
    visit("/")

    # Kaitan panel 1 is the middle panel
    within("#kp1") do
      fill_in("input.input", with: "hello")
    end
  end
end
