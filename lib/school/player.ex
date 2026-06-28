defmodule School.Player do
  @type t :: %__MODULE__{
          name: String.t(),
          score: integer(),
          pid: pid(),
          ready?: boolean(),
          boss?: boolean(),
          player_timer: non_neg_integer(),
          win_bonus_multiplier: float()
        }

  defstruct name: nil,
            score: 0,
            pid: nil,
            ready?: false,
            boss?: false,
            player_timer: 0,
            win_bonus_multiplier: 1.0
end
