require 'spec_helper'

describe 'visit home page' do
  include Capybara::DSL

  after do
    Capybara.reset_sessions!
  end

  it 'must have a logo' do
    visit('/')
    must_have_selector('.brand')
  end

  it 'must load a wiki page' do
    visit("/")
    find("#col_content_plan").find(".title").text.must_equal "LabWiki Quickstart Guide"
  end
end
