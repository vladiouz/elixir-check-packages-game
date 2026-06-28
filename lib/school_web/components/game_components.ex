defmodule SchoolWeb.GameComponents do
  use Phoenix.Component

  attr :player_name, :string, required: true
  attr :score, :float, required: true
  attr :win_bonus_multiplier, :float, default: 1.0

  def score_banner(assigns) do
    ~H"""
    <div class="player-score-bar">
      <div class="player-identity">
        <div class="player-avatar">MK</div>
        <div>
          <div class="player-name">Inspector {@player_name}</div>
          <div class="player-role">Senior Postal Officer</div>
        </div>
      </div>
      <div class="score-display">
        <span class="score-label">Score</span>
        <span class="score-value">{format_score(@score)}</span>
        <span class="score-unit">pts</span>
      </div>
      <div class="score-display">
        <span class="score-label">Bonus</span>
        <span class="score-value">{Float.round((@win_bonus_multiplier - 1.0) * 100, 0) |> trunc()}</span>
        <span class="score-unit">%</span>
      </div>
    </div>
    """
  end

  def match_time_remaining(assigns) do
    ~H"""
    <div class="card-timer-section">
      <span class="card-timer-label">Match time remaining</span>
      <div class="card-timer-track">
        <div class="card-timer-fill" style="width: 0%;"></div>
      </div>
      <span class="card-timer-seconds">0s</span>
    </div>
    """
  end

  attr :package, :map, required: true
  attr :timestamp, :integer, required: true
  attr :validation_result, :atom, required: true
  attr :show_boss_action, :boolean, default: false
  attr :show_reverse_action, :boolean, default: false
  attr :show_player_bonus_action, :boolean, default: false

  def package_inspection_form(assigns) do
    ~H"""
    <div class="card-reveal-wrapper">
      <%= case @validation_result do %>
        <% :correct -> %>
          <div :if={not @show_boss_action} class="stamp-result" id={"card-#{@timestamp}"}>
            <div class="stamp-mark approved">
              <span class="stamp-label">Approved</span>
              <span class="stamp-points">+1</span>
            </div>
          </div>
        <% :incorrect -> %>
          <div :if={not @show_boss_action} class="stamp-result" id={"card-#{@timestamp}"}>
            <div class="stamp-mark rejected">
              <span class="stamp-label">Rejected</span>
              <span class="stamp-points">−1</span>
            </div>
          </div>
        <% nil -> %>
          <div></div>
      <% end %>

      <div class="package-card">
        <div :if={not @show_boss_action} class="card-header">
          <div class="card-title-group">
            <div class="card-title">Package Inspection Form</div>
            <div class="card-id">PKG-{@timestamp}</div>
          </div>
          <div class="card-stamp">
            <span class="card-stamp-text">Postage</span>
            <span class="card-stamp-value">€4.50</span>
            <span class="card-stamp-text">Paid</span>
          </div>
        </div>

        <div :if={not @show_boss_action} class="package-fields">
          <div class="field">
            <div class="field-label">Package Type</div>
            <div class="field-value type-badge">{capitalise(@package.type)}</div>
          </div>
          <div class="field">
            <div class="field-label">Weight</div>
            <div class="field-value">{@package.weight}g</div>
          </div>
          <div class="field">
            <div class="field-label">Destination</div>
            <div class="field-value">{capitalise(@package.destination)}</div>
          </div>
          <div class="field">
            <div class="field-label">Shipping Class</div>
            <div class="field-value">{capitalise(@package.shipping_class)}</div>
          </div>
          <div class="field">
            <div class="field-label">Declared Value</div>
            <div class="field-value">{@package.declared_value}</div>
          </div>
        </div>

        <div :if={not @show_boss_action} class="package-checks">
          <span :if={@package.has_customs_form} class="check-tag has">
            <span class="check-dot"></span> Customs Form
          </span>
          <span :if={@package.has_insurance} class="check-tag has">
            <span class="check-dot"></span> Insurance
          </span>
          <span :if={@package.has_fragile_sticker} class="check-tag has">
            <span class="check-dot"></span> Fragile Sticker
          </span>
        </div>

        <div :if={not @show_boss_action} class="card-actions">
          <button phx-click="decline" class="btn btn-decline">
            <span class="btn-icon">✕</span> Decline
          </button>
          <button phx-click="approve" class="btn btn-approve">
            <span class="btn-icon">✓</span> Approve
          </button>
        </div>

        <div :if={@show_boss_action} class="card-actions">
          <button phx-click="boss_change_rules" class="btn btn-approve">
            <span class="btn-icon">♟</span> Change Rules
          </button>
          <button phx-click="boss_toggle_rules" class="btn btn-approve">
            <span class="btn-icon">⇄</span> Reverse Rules
          </button>
          <button phx-click="boss_double_points" class="btn btn-approve">
            <span class="btn-icon">×2</span> Double Stakes
          </button>
        </div>

        <div :if={@show_player_bonus_action} class="card-actions">
          <button phx-click="buy_win_bonus" class="btn btn-approve">
            <span class="btn-icon">+25%</span> Buy Win Bonus
          </button>
        </div>
      </div>
    </div>
    """
  end

  def boss_control_panel(assigns) do
    ~H"""
    <div class="card-reveal-wrapper">
      <div class="package-card">
        <div class="card-header">
          <div class="card-title-group">
            <div class="card-title">Boss Controls</div>
            <div class="card-id">COMMAND PANEL</div>
          </div>
        </div>

        <div class="card-actions">
          <button phx-click="boss_change_rules" class="btn btn-approve">
            <span class="btn-icon">♟</span> Change Rules
          </button>
          <button phx-click="boss_toggle_rules" class="btn btn-approve">
            <span class="btn-icon">⇄</span> Reverse Rules
          </button>
          <button phx-click="boss_double_points" class="btn btn-approve">
            <span class="btn-icon">×2</span> Double Stakes
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :local_player, :map, default: nil

  def ready_section(assigns) do
    ~H"""
    <div class="ready-section">
      <span class="ready-title">Report for Duty</span>

      <%= if @local_player do %>
        <.form for={%{}} phx-submit="ready">
          <div class="ready-input-group">
            <label class="player-name" for="inspector-name">{@local_player.name}</label>
          </div>

          <%= if @local_player.ready? do %>
            ✓ Ready
          <% else %>
            <button class="btn">
              Ready
            </button>
          <% end %>
        </.form>
      <% else %>
        <.form for={%{}} phx-submit="join">
          <div class="ready-input-group">
            <label class="ready-label" for="inspector-name">Inspector Name</label>
            <input
              class="ready-input"
              type="text"
              id="inspector-name"
              name="name"
              placeholder="e.g. Inspector Wazowski"
              value=""
              autocomplete="off"
            />
          </div>

          <button class="btn-ready">
            Join
          </button>
        </.form>
      <% end %>
    </div>
    """
  end

  attr :rule_descriptions, :list, required: true
  attr :reversed_rules, :boolean, default: false

  def postal_regulations(assigns) do
    ~H"""
    <div class="rules-reference">
      <div class="rules-header">
        <span class="rules-title">Postal Regulations</span>
        <span :if={@reversed_rules} class="rules-title">All rules reversed</span>
      </div>

      <%= for {desc, index} <- Enum.with_index(@rule_descriptions) do %>
        <div class="rules-list">
          <div class="rule-item">
            <span class="rule-number">{index + 1}</span>
            <strong :if={@reversed_rules}>{desc}</strong>
            <span :if={!@reversed_rules}>{desc}</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :player_list, :list, required: true
  attr :boss_name, :string, default: nil

  def leaderboard(assigns) do
    ~H"""
    <div class="leaderboard">
      <div class="leaderboard-header">
        <div class="leaderboard-title">Inspector Rankings</div>
        <div :if={@boss_name} class="leaderboard-subtitle">Boss: {@boss_name}</div>
      </div>

      <ul class="leaderboard-list">
        <li :for={player <- @player_list} class="leaderboard-item">
          <span class="rank rank-1"><%= if player.boss?, do: "B", else: "1" %></span>
          <div class="lb-player-info">
            <div class="lb-player-name">{player.name}</div>
          </div>
          <div class="lb-player-score">{player.score}</div>
        </li>
      </ul>
    </div>
    """
  end

  attr :player_list, :list, required: true

  def match_end_overlay(assigns) do
    ~H"""
    <div class="match-end-overlay" style="display:flex">
      <div class="match-end-card">
        <div class="match-end-label">Match Complete</div>
        <div class="match-end-title">Final Results</div>
        <ul class="match-end-scores">
          <li :for={{player, index} <- Enum.with_index(@player_list)}>
            <span>{get_medal(index)} {player.name}</span>
            <span class="final-score">{player.score} pts</span>
          </li>
        </ul>
        <button class="btn-new-match">New Match</button>
      </div>
    </div>
    """
  end

  def capitalise(term) do
    String.capitalize("#{term}")
  end

  def get_medal(place) do
    Enum.at(["🥇", "🥈", "🥉"], place)
  end

  defp format_score(score) when is_integer(score), do: score
  defp format_score(score) when is_float(score), do: Float.round(score, 1)
end
