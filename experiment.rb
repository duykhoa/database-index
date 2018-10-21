module Experiment
  def experiment(message = nil, &block)
    return unless block_given?

    printf "|\s%s\n" % [message] if message

    start = Time.now
    block.call
    duration = Time.now - start

    printf "> Took %f seconds\n" % [ duration ]
    printf "> Run explanation for given query: %s\n" % [ block.call.explain ]
  end
end
