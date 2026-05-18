# frozen_string_literal: true

require "minitest/autorun"
require "active_support/url"

class QueryTokenTest < Minitest::Test
  def test_tokenize_query_string
    assert_equal [['a', '1']], tokenize("a=1")
    assert_equal [['a', '=']], tokenize("a==")
    assert_equal [['a', '=1']], tokenize("a==1")
    assert_equal [['a', '1'], ["", nil]], tokenize("a=1&")
    assert_equal [["", nil], ['a', '1']], tokenize("&a=1")
    assert_equal [["", ""]], tokenize("=")
    assert_equal [[" ", nil]], tokenize(" ")
    assert_equal [[" ", '']], tokenize(" =")
    assert_equal [["", ' ']], tokenize("= ")
    assert_equal [['a', '1'], ["b", nil]], tokenize("a=1&b")
    assert_equal [['a', ''], ['b', nil]], tokenize("a=&b")
    assert_equal [['a', '1'], ['b', '2']], tokenize("a=1&b=2")
  end

  private

  def tokenize(query)
    ActiveSupport::URL::QueryToken.tokenize(query)
  end
end
