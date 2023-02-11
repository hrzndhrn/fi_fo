IEx.configure(inspect: [charlists: false])

defmodule Debug do
  def q(%FiFo{rear: rear, front: front}) do
    %{rear: rear, front: front}
  end
end

import Debug
