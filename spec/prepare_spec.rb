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
      fill_in("search", with: "hello")
      all(:xpath, '//input[@name="search"]')[1].value.must_equal "hello"

      all('a').each do |el|
        puts ">>>>>>>>>>>>>>>>>>>>>#{el}"
      end
      #first(:xpath, '//div[@class="suggestion-list" or @class="selection-list"]').wont_be_nil
      #must_have_selector(:css, ".suggestion-list.selection-list")
      #find("div.suggestion-list")#.visible?.must_equal true
    end
  end
end
