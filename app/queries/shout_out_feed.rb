class ShoutOutFeed
  def self.ranked(scope, seed:)
    quoted = ShoutOut.connection.quote(seed)
    random = "(('x' || substr(md5(#{quoted} || ':' || shout_outs.id::text), 1, 13))::bit(52)::bigint / 4503599627370496.0)"
    score = "POWER(shout_outs.bid_cents / 100.0 + 0.5 + 2.0 * #{random}, 1.6)"
    scope.order(Arel.sql("#{score} DESC"), id: :desc)
  end
end
