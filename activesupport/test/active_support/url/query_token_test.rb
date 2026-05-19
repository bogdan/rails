# frozen_string_literal: true

require "minitest/autorun"
require "active_support/url"

class QueryTokenTest < Minitest::Test
  def test_parse_query_string
    assert_equal [['a', '1']], parse("a=1")
    assert_equal [['a', '=']], parse("a==")
    assert_equal [['a', '=1']], parse("a==1")
    assert_equal [['a', '1'], ["", nil]], parse("a=1&")
    assert_equal [["", nil], ['a', '1']], parse("&a=1")
    assert_equal [['a', nil], ["", nil], ['b', nil]], parse("a&&b")
    assert_equal [["", ""]], parse("=")
    assert_equal [[" ", nil]], parse(" ")
    assert_equal [[" ", '']], parse(" =")
    assert_equal [["", ' ']], parse("= ")
    assert_equal [['a', '1'], ["b", nil]], parse("a=1&b")
    assert_equal [['a', ''], ['b', nil]], parse("a=&b")
    assert_equal [['a', '1'], ['b', '2']], parse("a=1&b=2")
    assert_equal [], parse(nil)
  end

  private

  def parse(query)
    ActiveSupport::URL::QueryToken.parse(query).map(&:to_a)
  end
end
