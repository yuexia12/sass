#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../test_helper'
require 'sass/engine'

class SassScriptTest < Test::Unit::TestCase
  include Sass::Script

  def test_color_checks_input
    assert_raise(Sass::SyntaxError, "Color values must be between 0 and 255") {Color.new([1, 2, -1])}
    assert_raise(Sass::SyntaxError, "Color values must be between 0 and 255") {Color.new([256, 2, 3])}
  end

  def test_string_escapes
    assert_equal '"', resolve("\"\\\"\"")
    assert_equal "\\", resolve("\"\\\\\"")
    assert_equal "\\02fa", resolve("\"\\02fa\"")
  end

  def test_color_names
    assert_equal "white", resolve("white")
    assert_equal "white", resolve("#ffffff")
    assert_equal "#fffffe", resolve("white - #000001")
  end

  def test_implicit_strings
    silence_warnings do
      assert_equal Sass::Script::String.new("foo"), eval("foo")
      assert_equal Sass::Script::String.new("foo bar"), eval("foo bar")
      assert_equal Sass::Script::String.new("foo/bar"), eval("foo/bar")
    end
  end

  def test_warning_reporting
    assert_warning(<<WARN) {eval("foo")}
DEPRECATION WARNING:
On line 1, character 1 of 'test_warning_reporting_inline.sass'
Implicit strings have been deprecated and will be removed in version 2.4.
'foo' was not quoted. Please add double quotes (e.g. "foo").
WARN
    assert_warning(<<WARN) {eval("1 + foo")}
DEPRECATION WARNING:
On line 1, character 5 of 'test_warning_reporting_inline.sass'
Implicit strings have been deprecated and will be removed in version 2.4.
'foo' was not quoted. Please add double quotes (e.g. "foo").
WARN
    assert_warning(<<WARN) {render("@if 1 + foo")}
DEPRECATION WARNING:
On line 1, character 9 of 'test_warning_reporting_inline.sass'
Implicit strings have been deprecated and will be removed in version 2.4.
'foo' was not quoted. Please add double quotes (e.g. "foo").
WARN

    # Regression
    assert_warning(<<WARN) {render("@if if")}
DEPRECATION WARNING:
On line 1, character 5 of 'test_warning_reporting_inline.sass'
Implicit strings have been deprecated and will be removed in version 2.4.
'if' was not quoted. Please add double quotes (e.g. "if").
WARN
  end

  def test_inaccessible_functions
    assert_warning <<WARN do
DEPRECATION WARNING:
On line 2, character 6 of 'test_inaccessible_functions_inline.sass'
Implicit strings have been deprecated and will be removed in version 2.4.
'to_s' was not quoted. Please add double quotes (e.g. "to_s").
WARN
      assert_equal "send(to_s)", resolve("send(to_s)", :line => 2)
    end
    assert_equal "public_instance_methods()", resolve("public_instance_methods()")
  end

  def test_ruby_equality
    assert_equal eval('"foo"'), eval('"foo"')
    assert_equal eval('1'), eval('1.0')
    assert_not_equal eval('1'), eval('"1"')
  end

  private

  def resolve(str, opts = {}, environment = {})
    munge_filename opts
    eval(str, opts, environment).to_s
  end

  def eval(str, opts = {}, environment = {})
    munge_filename opts
    Sass::Script.parse(str, opts[:line] || 1,
      opts[:offset] || 0, opts[:filename]).perform(environment)
  end

  def render(sass, options = {})
    munge_filename options
    Sass::Engine.new(sass, options).render
  end

  def assert_warning(message)
    the_real_stderr, $stderr = $stderr, StringIO.new
    yield
    assert_equal message.strip, $stderr.string.strip
  ensure
    $stderr = the_real_stderr
  end

  def silence_warnings
    the_real_stderr, $stderr = $stderr, StringIO.new
    yield
  ensure
    $stderr = the_real_stderr
  end
end