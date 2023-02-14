defmodule FiFo.Guards do
  @moduledoc false

  defguard is_queue(rear, front) when is_list(rear) and is_list(front)
end
