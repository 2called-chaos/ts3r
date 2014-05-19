module Heatmon
  # Heatmon notification gateway base class.
  class Gateway
    Banana.require_on(self, %w[email xmpp])
  end
end
