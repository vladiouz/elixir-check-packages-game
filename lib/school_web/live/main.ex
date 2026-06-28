defmodule SchoolWeb.MainLive do
  use SchoolWeb, :live_view

  alias School.Logic
  alias School.State

  import SchoolWeb.GameComponents

  @impl true
  def mount(_params, _session, socket) do
    package = Logic.generate_package()

    Phoenix.PubSub.subscribe(School.PubSub, "game_room")

    active_rules = State.get_active_rules()
    rule_descriptions = Logic.descriptions_by_rules(active_rules)

    new_socket =
      socket
      |> assign(:local_player, nil)
      |> assign(:package, package)
      |> assign(:timestamp, nil)
      |> assign(:validation_result, :correct)
      |> assign(:game_state, :waiting)
      |> assign(:current_game_time, 0)
      |> assign(:active_rules, active_rules)
      |> assign(:rule_descriptions, rule_descriptions)
      |> assign(:score, 0)
      |> assign(:player_list, [])
      |> assign(:is_boss, false)
      |> assign(:boss_name, nil)
      |> assign(:reversed_rules, false)
      |> assign(:double_points_active, false)

    {:ok, new_socket}
  end

  @impl true
  def handle_event("join", %{"name" => name}, socket) do
    local_player = State.add_player(name, self())

    new_socket =
      socket
      |> assign(:local_player, local_player)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("ready", _params, socket) do
    local_player = socket.assigns.local_player
    {updated_local_player, _game_state} = State.player_ready(local_player.name)

    new_socket =
      socket
      |> assign(:local_player, updated_local_player)
      |> assign(:is_boss, updated_local_player.boss?)
      |> assign(:boss_name, if(updated_local_player.boss?, do: updated_local_player.name, else: socket.assigns.boss_name))

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("decline", _params, socket) do
    new_socket = validation("swipe-left", :invalid, socket)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    new_socket = validation("swipe-right", :valid, socket)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("boss_change_rules", _params, socket) do
    case State.change_active_rules(self()) do
      {:ok, _active_rules} ->
        active_rules = State.get_active_rules()
        rule_descriptions = Logic.descriptions_by_rules(active_rules)

        {:noreply,
         socket
         |> assign(:active_rules, active_rules)
         |> assign(:rule_descriptions, rule_descriptions)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("boss_toggle_rules", _params, socket) do
    case State.toggle_reversed_rules(self()) do
      {:ok, reversed_rules} ->
        {:noreply, assign(socket, :reversed_rules, reversed_rules)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("boss_double_points", _params, socket) do
    case State.activate_double_points(self()) do
      {:ok, _expires_at} ->
        {:noreply, assign(socket, :double_points_active, true)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("buy_win_bonus", _params, socket) do
    case State.buy_win_bonus(self()) do
      {:ok, updated_player} ->
        updated_local_player =
          if socket.assigns.local_player do
            socket.assigns.local_player
            |> Map.put(:score, updated_player.score)
            |> Map.put(:win_bonus_multiplier, updated_player.win_bonus_multiplier)
          else
            updated_player
          end

        {:noreply,
         socket
         |> assign(:local_player, updated_local_player)
         |> assign(:score, updated_player.score)}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:next_package, socket) do
    package = Logic.generate_package()

    new_socket =
      socket
      |> assign(:package, package)
      |> push_event("reset-package-card", %{})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_start, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_ended, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:tick_update, current_game_time}, socket) do
    width = build_game_time_loading_bar(current_game_time)

    new_socket =
      socket
      |> assign(:current_game_time, current_game_time)
      |> push_event("timer-tick", %{
        time: current_game_time,
        width: width,
        red: socket.assigns.double_points_active
      })

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:update_rules, socket) do
    active_rules = State.get_active_rules()
    rule_descriptions = Logic.descriptions_by_rules(active_rules)
    reversed_rules = State.get_reversed_rules()
    double_points_active = State.get_double_points_active()

    new_socket =
      socket
      |> assign(:rule_descriptions, rule_descriptions)
      |> assign(:active_rules, active_rules)
      |> assign(:reversed_rules, reversed_rules)
      |> assign(:double_points_active, double_points_active)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:double_points_active, expires_at}, socket) do
    current_game_time = socket.assigns[:current_game_time] || 0
    remaining = max(expires_at - current_game_time, 0)

    Process.send_after(self(), :double_points_expired, remaining * 1_000)

    {:noreply, assign(socket, :double_points_active, true)}
  end

  @impl true
  def handle_info(:double_points_expired, socket) do
    {:noreply, assign(socket, :double_points_active, false)}
  end

  def handle_info({:update_player_list, updated_player_list}, socket) do
    boss_player = Enum.find(updated_player_list, & &1.boss?)
    local_player =
      if socket.assigns.local_player do
        Enum.find(updated_player_list, fn player ->
          player.pid == socket.assigns.local_player.pid
        end)
      else
        nil
      end

    new_socket =
      socket
      |> assign(:player_list, updated_player_list)
      |> assign(:local_player, local_player)
      |> assign(:is_boss, local_player && local_player.boss?)
      |> assign(:boss_name, if(boss_player, do: boss_player.name, else: socket.assigns.boss_name))

    {:noreply, new_socket}
  end

  defp validation(swipe_direction, expected, socket) do
    package = socket.assigns.package

    {updated_player, decision, validation_msg} =
      State.update_player_score(self(), package, expected)

    new_socket =
      socket
      |> assign(:validation_result, decision)
      |> assign(:validation_msg, validation_msg)
      |> assign(:local_player, updated_player)
      |> assign(:score, updated_player.score)
      |> push_event(swipe_direction, %{})

    Process.send_after(self(), :next_package, 1_000)

    new_socket
  end

  def build_game_time_loading_bar(game_time) do
    max_game_time = State.max_game_time()
    game_time / max_game_time * 100
  end
end
