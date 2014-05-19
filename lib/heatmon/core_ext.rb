class String
  [:black, :red, :green, :yellow, :blue, :magenta, :cyan, :white].each do |color|
    define_method(color) { colorize(color) }
  end

  def colorize color = :magenta
    Heatmon.logger unless $heatmon_loggers[:default]
    $heatmon_loggers[:default].colorize(self, color)
  end
end

# Backport for ruby < 2
unless Signal.respond_to?(:signame)
  module Signal
    def signame sig
      list.key(sig.to_i) || sig || "???"
    end
    module_function :signame
  end
end
