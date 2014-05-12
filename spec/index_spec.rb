require 'spec_helper'

describe 'visit home page' do
  include Capybara::DSL

  it 'must have a logo' do
    visit('/')

    page.must_have_selector('.brand')
  end
end
