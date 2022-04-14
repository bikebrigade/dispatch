defmodule BikeBrigade.Delivery do
  import Ecto.Query, warn: false
  alias BikeBrigade.Repo

  alias BikeBrigade.LocalizedDateTime

  import Geo.PostGIS, only: [st_distance: 2]

  alias BikeBrigade.Riders.Rider

  alias BikeBrigade.Messaging
  alias BikeBrigade.Delivery.{Task, CampaignRider}

  import BikeBrigade.Utils, only: [task_count: 1, humanized_task_count: 1]

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(Task, preload: [:campaigns])
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task(123)
      %Task{}

      iex> get_task(456)
      nil

  """
  def get_task(id, opts \\ []) do
    preload =
      Keyword.get(opts, :prelaod, [
        :assigned_rider,
        :task_items,
        :pickup_location,
        :dropoff_location
      ])

    from(t in Task,
      as: :task,
      where: t.id == ^id
    )
    |> task_load_location()
    |> Repo.one()
    |> Repo.preload(preload)
  end

  defp task_load_location(query) do
    query
    |> join(:inner, [task: t], pl in assoc(t, :pickup_location), as: :pickup_location)
    |> join(:inner, [task: t], dl in assoc(t, :dropoff_location), as: :dropoff_location)
    |> preload([pickup_location: pl, dropoff_location: dl],
      pickup_location: pl,
      dropoff_location: dl
    )
    |> select_merge([pickup_location: pl, dropoff_location: dl], %{
      delivery_distance: st_distance(pl.coords, dl.coords)
    })
  end

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs, opts \\ []) do
    # TODO validate items unique index stuff
    task
    |> Task.changeset(attrs, opts)
    |> Repo.update()
    |> broadcast(:task_updated)
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
    |> broadcast(:task_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}, opts \\ []) do
    Task.changeset(task, attrs, opts)
  end

  alias BikeBrigade.Delivery.Campaign

  def list_campaigns(week \\ nil, opts \\ []) do
    preload = Keyword.get(opts, :preload, [:program])

    query =
      from c in Campaign,
        as: :campaign,
        order_by: [desc: c.delivery_start]

    query =
      if week do
        start_date = LocalizedDateTime.new!(week, ~T[00:00:00])
        end_date = Date.add(week, 6) |> LocalizedDateTime.new!(~T[23:59:59])

        query
        |> where([campaign: c], c.delivery_start >= ^start_date and c.delivery_start <= ^end_date)
      else
        query
      end

    Repo.all(query)
    |> Repo.preload(preload)
  end

  alias BikeBrigade.Delivery.CampaignRider

  def get_campaign_rider!(token) do
    query =
      from cr in CampaignRider,
        join: c in assoc(cr, :campaign),
        join: r in assoc(cr, :rider),
        left_join: t in assoc(c, :tasks),
        on: t.assigned_rider_id == r.id,
        # TODO make this join dor distance some kind of function
        left_join: pl in assoc(t, :pickup_location),
        left_join: dl in assoc(t, :dropoff_location),
        order_by: st_distance(pl.coords, dl.coords),
        where: cr.token == ^token,
        preload: [
          campaign: [:program, :location],
          rider: {r, [:location, assigned_tasks: {t, [:dropoff_location, task_items: :item]}]}
        ]

    Repo.one!(query)
  end

  def create_campaign_rider(attrs \\ %{}) do
    %CampaignRider{}
    |> CampaignRider.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:rider_capacity, :notes, :pickup_window, :enter_building]},
      conflict_target: [:rider_id, :campaign_id]
    )
    |> broadcast(:campaign_rider_created)
  end

  def delete_campaign_rider(%CampaignRider{} = campaign_rider) do
    Repo.delete(campaign_rider)
    |> broadcast(:campaign_rider_deleted)
  end

  def create_task_for_campaign(campaign, attrs \\ %{}, opts \\ []) do
    # TODO handle conflicts for multiple task items here
    # TODO this looks a lot like Task.changeset_for_campaign()
    %Task{
      pickup_location: campaign.location,
      campaign_id: campaign.id
    }
    |> Task.changeset(attrs, opts)
    |> Repo.insert()
    |> broadcast(:task_created)
  end

  @doc """
  Creates a campaign.
  """
  def create_campaign(attrs \\ %{}) do
    %Campaign{}
    |> Campaign.changeset(attrs)
    |> Repo.insert()
  end

  def get_campaign(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [:location, :program])

    Repo.get(Campaign, id)
    |> Repo.preload(preload)
  end

  @doc """
  Returns a tuple of `{riders, tasks}` for a `campaign`. Riders are pre-loaded with their assigned tasks,
  and tasks are pre-loaded with the assigned rider, and task_items/items.
  """
  def campaign_riders_and_tasks(%Campaign{} = campaign) do
    campaign =
      campaign
      |> Repo.preload(:location)

    all_tasks =
      from(t in Task,
        as: :task,
        where: t.campaign_id == ^campaign.id,
        select: t
      )
      |> task_load_location()
      |> Repo.all()
      |> Repo.preload([:pickup_location, :dropoff_location, task_items: [:item]])

    all_riders =
      Repo.all(
        from cr in CampaignRider,
          join: r in assoc(cr, :rider),
          join: l in assoc(r, :location),
          where: cr.campaign_id == ^campaign.id,
          order_by: r.name,
          select: r,
          select_merge: %{
            distance: st_distance(l.coords, ^campaign.location.coords),
            task_notes: cr.notes,
            task_capacity: cr.rider_capacity,
            task_enter_building: cr.enter_building,
            pickup_window: cr.pickup_window,
            delivery_url_token: cr.token
          }
      )
      |> Repo.preload(:location)

    # Does a nested preload to get tasks' assigned riders without doing an extra db query
    tasks = Repo.preload(all_tasks, assigned_rider: fn _ -> all_riders end)

    riders = Repo.preload(all_riders, assigned_tasks: fn _ -> all_tasks end)

    {riders, tasks}
  end

  # TODO RENAME TO TODAYS TASKS

  def latest_campaign_tasks(rider) do
    # This is hacky, better to refigure out how we present this
    today = LocalizedDateTime.today()
    end_of_today = LocalizedDateTime.new!(today, ~T[23:59:59])
    start_of_yesterday = Date.add(today, -1) |> LocalizedDateTime.new!(~T[00:00:00])

    query =
      from c in Campaign,
        join: t in assoc(c, :tasks),
        join: cr in CampaignRider,
        on: cr.rider_id == ^rider.id and cr.campaign_id == c.id,
        where: c.delivery_start <= ^end_of_today and c.delivery_start >= ^start_of_yesterday,
        where: t.assigned_rider_id == ^rider.id,
        select: c,
        select_merge: %{delivery_url_token: cr.token},
        order_by: [desc: c.delivery_start, asc: t.id],
        preload: [tasks: t]

    Repo.all(query)
    |> Repo.preload([:program, tasks: [:dropoff_location, task_items: :item]])
  end

  def campaigns_per_rider(rider) do
    query = from c in CampaignRider, where: c.rider_id == ^rider.id, select: count(c.id)
    Repo.one(query)
  end

  def hacky_assign(%Campaign{} = campaign) do
    riders_query =
      from r in Rider,
        join: cr in CampaignRider,
        on: cr.rider_id == r.id and cr.campaign_id == ^campaign.id,
        join: l in assoc(r, :location),
        order_by: [
          desc: cr.rider_capacity,
          asc: r.max_distance - st_distance(l.coords, ^campaign.location.coords)
        ],
        left_join: t in Task,
        on: t.assigned_rider_id == r.id and t.campaign_id == ^campaign.id,
        preload: [:location, assigned_tasks: {t, :task_items}],
        select: {r, cr.rider_capacity}

    riders = Repo.all(riders_query)

    require Logger

    for {rider, rider_capacity} <- riders do
      if task_count(rider.assigned_tasks) < rider_capacity do
        tasks =
          if rider_capacity > 1 do
            Repo.all(
              from t in Task,
                where: t.campaign_id == ^campaign.id and is_nil(t.assigned_rider_id),
                join: pl in assoc(t, :pickup_location),
                join: dl in assoc(t, :dropoff_location),
                preload: [task_items: :item],
                order_by: st_distance(pl.coords, dl.coords)
            )
          else
            Repo.all(
              from t in Task,
                where: t.campaign_id == ^campaign.id and is_nil(t.assigned_rider_id),
                join: dl in assoc(t, :dropoff_location),
                preload: [task_items: :item],
                order_by: st_distance(dl.coords, ^rider.location.coords)
            )
          end
          |> Repo.preload([:assigned_rider])

        {to_assign, _tasks} = Enum.split(tasks, rider_capacity)

        Logger.info("Assigning #{Enum.count(to_assign)} items to #{rider.name}")

        for task <- to_assign do
          update_task(task, %{assigned_rider_id: rider.id})
        end
      end
    end
  end

  def change_campaign(campaign, attrs \\ %{}) do
    Campaign.changeset(campaign, attrs)
  end

  def update_campaign(campaign, attrs, opts \\ []) do
    campaign
    |> Campaign.changeset(attrs, opts)
    |> Repo.update()
    |> broadcast(:campaign_updated)
  end

  def delete_campaign(%Campaign{} = campaign) do
    Repo.delete(campaign)
  end

  def send_campaign_messages(%Campaign{} = campaign) do
    campaign = Repo.preload(campaign, [:location, :instructions_template, :program])
    {riders, _} = campaign_riders_and_tasks(campaign)

    msgs =
      for rider <- riders, rider != nil, rider.assigned_tasks != [] do
        {:ok, msg} = send_campaign_message(%Campaign{} = campaign, rider)

        msg
      end

    {:ok, msgs}
  end

  def send_campaign_message(%Campaign{} = campaign, rider) do
    body =
      render_campaign_message_for_rider(
        campaign,
        campaign.instructions_template.body,
        rider
      )

    {:ok, msg} = Messaging.send_message_in_chunks(campaign, body, rider)

    if rider.text_based_itinerary do
      send_text_based_itinerary(rider, campaign)
    end

    {:ok, msg}
  end

  defp send_text_based_itinerary(rider, campaign) do
    template = """
    1. Pickup
    • {{{task_count}}}
    • {{{pickup_address}}}
    • {{{pickup_window}}}

    2. Drop-off
    {{{task_details}}}

    {{{directions}}}
    """

    body =
      render_campaign_message_for_rider(
        campaign,
        template,
        rider
      )

    Messaging.send_message_in_chunks(campaign, body, rider)
  end

  def render_campaign_message_for_rider(campaign, nil, rider),
    do: render_campaign_message_for_rider(campaign, "", rider)

  def render_campaign_message_for_rider(%Campaign{} = campaign, message, %Rider{} = rider)
      when is_binary(message) do
    tasks =
      rider.assigned_tasks
      |> Enum.sort_by(& &1.delivery_distance)

    # TODO: referncing CampaignHelpers here is bad!
    # need to move this into Task or Delivery
    pickup_window = BikeBrigadeWeb.CampaignHelpers.pickup_window(campaign, rider)

    locations = [campaign.location | Enum.map(tasks, & &1.dropoff_location)]

    task_details =
      for task <- tasks do
        "Name: #{task.dropoff_name}\nPhone: #{task.dropoff_phone}\nType: #{BikeBrigadeWeb.CampaignHelpers.request_type(task)}\nAddress: #{task.dropoff_location}\nNotes: #{task.rider_notes}"
      end
      |> Enum.join("\n\n")

    {destination, waypoints} = List.pop_at(locations, -1)

    # TODO: this is the same as DeliveryHelpers.directions_url
    map_query =
      URI.encode_query(%{
        api: 1,
        travelmode: "bicycling",
        origin: rider.location,
        waypoints: Enum.join(waypoints, "|"),
        destination: destination
      })

    directions = "https://www.google.com/maps/dir/?#{map_query}"

    delivery_details_url =
      BikeBrigadeWeb.Router.Helpers.delivery_show_url(
        BikeBrigadeWeb.Endpoint,
        :show,
        rider.delivery_url_token
      )

    assigns = %{
      rider_name: rider.name |> String.split(" ") |> List.first(),
      pickup_address: campaign.location,
      task_details: task_details,
      directions: directions,
      task_count: humanized_task_count(tasks),
      pickup_window: pickup_window,
      delivery_details_url: delivery_details_url
    }

    Mustache.render(message, assigns)
  end

  def campaign_rider_token(%Campaign{} = campaign, %Rider{} = rider) do
    # TODO
    # this is very inefficient to look up each time, which we could cache these
    query =
      from cr in CampaignRider,
        where: cr.rider_id == ^rider.id and cr.campaign_id == ^campaign.id

    case Repo.one(query) do
      %CampaignRider{token: nil} = cr ->
        cr =
          cr
          |> CampaignRider.gen_token_changeset()
          |> Repo.update!()

        cr.token

      %CampaignRider{token: token} ->
        token

      _ ->
        nil
    end
  end

  def remove_rider_from_campaign(campaign, rider) do
    if cr = Repo.get_by(CampaignRider, campaign_id: campaign.id, rider_id: rider.id) do
      delete_campaign_rider(cr)
    end

    tasks =
      from(t in Task,
        where: t.campaign_id == ^campaign.id and t.assigned_rider_id == ^rider.id
      )
      |> Repo.all()

    for task <- tasks do
      update_task(task, %{assigned_rider_id: nil})
    end
  end

  alias BikeBrigade.Delivery.Program

  @doc """
  Returns the list of programs.

  ## Examples

      iex> list_programs()
      [%Program{}, ...]

  """
  def list_programs(opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    query =
      from p in Program,
        as: :program,
        order_by: [desc: p.active, asc: p.name]

    query =
      if opts[:with_campaign_count] do
        from p in query,
          left_join: c in assoc(p, :campaigns),
          group_by: p.id,
          select_merge: %{campaign_count: count(c)}
      else
        query
      end

    Repo.all(query)
    |> Repo.preload(preload)
  end

  @doc """
  Gets a single program.

  Raises `Ecto.NoResultsError` if the Program does not exist.

  ## Examples

      iex> get_program!(123)
      %Program{}

      iex> get_program!(456)
      ** (Ecto.NoResultsError)

  """
  def get_program!(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])

    Repo.get!(Program, id)
    |> Repo.preload(preload)
  end

  @doc """
  Creates a program.

  ## Examples

      iex> create_program(%{field: value})
      {:ok, %Program{}}

      iex> create_program(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_program(attrs \\ %{}) do
    %Program{}
    |> Program.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a program.

  ## Examples

      iex> update_program(program, %{field: new_value})
      {:ok, %Program{}}

      iex> update_program(program, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_program(%Program{} = program, attrs) do
    program
    |> Program.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a program.

  ## Examples

      iex> delete_program(program)
      {:ok, %Program{}}

      iex> delete_program(program)
      {:error, %Ecto.Changeset{}}

  """
  def delete_program(%Program{} = program) do
    Repo.delete(program)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking program changes.

  ## Examples

      iex> change_program(program)
      %Ecto.Changeset{data: %Program{}}

  """
  def change_program(%Program{} = program, attrs \\ %{}) do
    Program.changeset(program, attrs)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(BikeBrigade.PubSub, "delivery")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, struct}, event) do
    Phoenix.PubSub.broadcast(BikeBrigade.PubSub, "delivery", {event, struct})
    {:ok, struct}
  end

  alias BikeBrigade.Delivery.Item

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    query = from i in Item, order_by: i.name

    Repo.all(query)
    |> Repo.preload(:program)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  alias BikeBrigade.Delivery.Opportunity

  @doc """
  Returns the list of opportunities.

  ## Examples

      iex> list_opportunities()
      [%Opportunity{}, ...]

  """
  def list_opportunities(opts \\ []) do
    query =
      from o in Opportunity,
        as: :opportunity,
        left_join: p in assoc(o, :program),
        as: :program,
        on: o.program_id == p.id,
        where: ^opportunities_filter(opts)

    query =
      case {Keyword.get(opts, :sort_order, :asc), Keyword.get(opts, :sort_field, :delivery_start)} do
        {order, :program_name} ->
          query
          |> order_by([{^order, as(:program).name}, asc: as(:opportunity).delivery_start])

        {order, :program_lead} ->
          query
          |> join(:left, [o, p], l in assoc(p, :lead), as: :lead)
          |> order_by([{^order, as(:lead).name}, asc: as(:opportunity).delivery_start])

        {order, field} when order in [:asc, :desc] and is_atom(field) ->
          query
          |> order_by([{^order, ^field}])
      end

    preload = Keyword.get(opts, :preload, [])

    Repo.all(query)
    |> Repo.preload(preload)
  end

  defp opportunities_filter(opts) do
    filter = true

    filter =
      case Keyword.fetch(opts, :published) do
        {:ok, true} -> dynamic([o], ^filter and o.published == true)
        _ -> filter
      end

    filter =
      case Keyword.fetch(opts, :start_date) do
        {:ok, date} ->
          date_time = LocalizedDateTime.new!(date, ~T[00:00:00])
          dynamic([o], ^filter and o.delivery_start >= ^date_time)

        _ ->
          filter
      end

    filter =
      case Keyword.fetch(opts, :end_date) do
        {:ok, date} ->
          date_time = LocalizedDateTime.new!(date, ~T[23:59:59])
          dynamic([o], ^filter and o.delivery_start <= ^date_time)

        _ ->
          filter
      end

    filter
  end

  def get_opportunity(id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [:location, :program])

    Repo.get!(Opportunity, id)
    |> Repo.preload(preload)
  end

  def create_opportunity(attrs \\ %{}) do
    %Opportunity{}
    |> Opportunity.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:opportunity_created)
  end

  def update_opportunity(%Opportunity{} = opportunity, attrs \\ %{}) do
    opportunity
    |> Opportunity.changeset(attrs)
    |> Repo.update()
    |> broadcast(:opportunity_updated)
  end

  def create_or_update_opportunity(%Opportunity{} = opportunity, attrs \\ %{}) do
    if opportunity.id do
      update_opportunity(opportunity, attrs)
    else
      create_opportunity(attrs)
    end
  end

  def delete_opportunity(%Opportunity{} = opportunity) do
    Repo.delete(opportunity)
    |> broadcast(:opportunity_deleted)
  end

  def change_opportunity(%Opportunity{} = opportunity, attrs \\ %{}) do
    Opportunity.changeset(opportunity, attrs)
  end
end
