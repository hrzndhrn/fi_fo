IEx.configure(inspect: [charlists: false])

defmodule Debug do
  def queue(%FiFo{rear: rear, front: front}) do
    %{rear: rear, front: front}
  end
end
