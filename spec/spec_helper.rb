# frozen_string_literal: true

CUPRITE_ROOT = File.expand_path("..", __dir__)
$:.unshift(CUPRITE_ROOT + "/lib")

require "bundler/setup"

require "rspec"
require "capybara/spec/spec_helper"
require "capybara/cuprite"

require "support/test_app"
require "support/external_browser"

Capybara.register_driver(:cuprite) do |app|
  options = {}
  options.merge!(inspector: true) if ENV["INSPECTOR"]
  options.merge!(logger: StringIO.new) if ENV["TRAVIS"]
  driver = Capybara::Cuprite::Driver.new(app, options)
  process = driver.browser.process

  puts "Browser: #{process.browser_version}"
  puts "Protocol: #{process.protocol_version}"
  puts "V8: #{process.v8_version}"
  puts "Webkit: #{process.webkit_version}"

  driver
end

module TestSessions
  Cuprite = Capybara::Session.new(:cuprite, TestApp)
end

RSpec.configure do |config|
  config.define_derived_metadata do |metadata|
    regexes = <<~REGEXP.split("\n").map { |s| Regexp.quote(s.strip) }.join("|")
    node #obscured?
    node #drag_to should work with jsTree
    node #drag_to should drag and drop an object
    node #drag_to should drag and drop if scrolling is needed
    node #drag_to should drag a link
    node #drag_to should work with Dragula
    node #drag_to HTML5 should work with SortableJS
    node #drag_to HTML5 should HTML5 drag and drop an object
    node #drag_to HTML5 should set clientX/Y in dragover events
    node #drag_to HTML5 should not HTML5 drag and drop on a non HTML5 drop element
    node #drag_to HTML5 should HTML5 drag and drop when scrolling needed
    node #drag_to HTML5 should drag HTML5 default draggable elements
    node #drag_to HTML5 should drag HTML5 default draggable element child
    node #drag_to should simulate a single held down modifier key
    node #drag_to should simulate multiple held down modifier keys
    node #drag_to should support key aliases
    node #drag_to HTML5 should preserve clientX/Y from last dragover event
    node #drag_to HTML5 should simulate a single held down modifier key
    node #drag_to HTML5 should simulate multiple held down modifier keys
    node #drag_to HTML5 should support key aliases
    node Element#drop can drop a file
    node Element#drop can drop multiple files
    node Element#drop can drop strings
    node Element#drop can drop multiple strings
    node #visible? details non-summary descendants should be non-visible
    node #visible? works when details is toggled open and closed
    #all with obscured filter should only find nodes on top in the viewport when fals
    #all with obscured filter should not find nodes on top outside the viewport when false
    #all with obscured filter should find top nodes outside the viewport when true
    #all with obscured filter should only find non-top nodes when true
    #click offset when w3c_click_offset is false should offset outside the element
    #click offset when w3c_click_offset is true should offset from center of element
    #click offset when w3c_click_offset is true should offset outside from center of element
    #double_click offset when w3c_click_offset is false should offset outside the element
    #double_click offset when w3c_click_offset is true should offset from center of element
    #double_click offset when w3c_click_offset is true should offset outside from center of element
    #right_click offset when w3c_click_offset is false should offset outside the element
    #right_click offset when w3c_click_offset is true should offset from center of element
    #right_click offset when w3c_click_offset is true should offset outside from center of element
    #fill_in should fill in a color field
    #has_field with valid should be false if field is invalid
    #find with spatial filters should find an element above another element
    #find with spatial filters should find an element below another element
    #find with spatial filters should find an element left of another element
    #find with spatial filters should find an element right of another element
    #find with spatial filters should combine spatial filters
    #find with spatial filters should find an element "near" another element
    #has_css? with spatial requirements accepts spatial options
    #has_css? with spatial requirements supports spatial sugar
    REGEXP

    metadata[:skip] = true if metadata[:full_description].match(/#{regexes}/)
  end

  config.around do |example|
    if ENV["TRAVIS"]
      session = @session || TestSessions::Cuprite
      session.driver.browser.logger.truncate(0)
      session.driver.browser.logger.rewind
    end

    example.run

    if ENV["TRAVIS"] && example.exception
      session = @session || TestSessions::Cuprite
      raise session.driver.browser.logger.string
    end
  end

  config.after do
    FileUtils.rm_rf(CUPRITE_ROOT + "/screenshots")
    FileUtils.rm_rf(CUPRITE_ROOT + "/save_path_tmp")
  end

  Capybara::SpecHelper.configure(config)
end
