module Timelog
  def timelog(message = nil, &block)
    return unless block_given?

    printf "%s\t" % [message] if message

    start = Time.now
    block.call
    duration = Time.now - start

    printf "Took %f seconds\n" % [ duration ]
  end
end
