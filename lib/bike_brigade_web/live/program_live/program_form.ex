defmodule BikeBrigadeWeb.ProgramLive.ProgramForm do
  use BikeBrigade.Schema
  import Ecto.Changeset

  alias BikeBrigade.Delivery.Program

  alias Crontab.CronExpression

  defmodule Schedule do
    use BikeBrigade.Schema

    @weekdays [
      :monday,
      :tuesday,
      :wednesday,
      :thursday,
      :friday,
      :saturday,
      :sunday
    ]

    # Sunday is both 0 and 7 in cron
    @cron_weekdays Enum.with_index([:sunday | @weekdays])

    @primary_key false
    embedded_schema do
      field :start_time, :time, default: ~T[12:00:00]
      field :end_time, :time, default: ~T[13:00:00]

      field :weekday, Ecto.Enum, values: @weekdays, default: :monday
    end

    def changeset(schedule, attrs \\ %{}) do
      schedule
      |> cast(attrs, [:weekday, :start_time, :end_time])
      |> validate_required([:weekday, :start_time, :end_time])
    end

    def from_program_schedule(%Program.Schedule{
          cron: %CronExpression{
            weekday: [w],
            hour: [hour],
            minute: [minute]
          },
          duration: duration
        }) do
      start_time = Time.new!(hour, minute, 0)
      end_time = Time.add(start_time, duration)
      {weekday, _i} = List.keyfind(@cron_weekdays, w, 1)

      %__MODULE__{
        weekday: weekday,
        start_time: start_time,
        end_time: end_time
      }
    end

    def to_program_schedule_attrs(%__MODULE__{
          weekday: weekday,
          start_time: start_time,
          end_time: end_time
        }) do
      w = Keyword.get(@cron_weekdays, weekday)

      %{
        cron:
          CronExpression.Composer.compose(%CronExpression{
            weekday: [w],
            hour: [start_time.hour],
            minute: [start_time.minute]
          }),
        duration: Time.diff(end_time, start_time)
      }
    end

    defimpl Phoenix.HTML.Safe do
      @weekday_abbr %{
        monday: "Mon",
        tuesday: "Tue",
        wednesday: "Wed",
        thursday: "Thu",
        friday: "Fri",
        saturday: "Sat",
        sunday: "Sun"
      }
      def to_iodata(%{
            weekday: weekday,
            start_time: start_time,
            end_time: end_time
          }) do
        w = @weekday_abbr[weekday]
        s = Calendar.strftime(start_time, "%-I:%M")
        e = Calendar.strftime(end_time, "%-I:%M%p")
        "#{w} #{s} - #{e}"
      end
    end
  end

  @primary_key false
  embedded_schema do
    embeds_one :program, Program, on_replace: :update
    embeds_many :schedules, Schedule, on_replace: :delete
  end

  def changeset(program_form, attrs \\ %{}) do
    program_form
    |> cast(attrs, [])
    |> cast_embed(:program)
    |> cast_embed(:schedules)
  end

  def from_program(program) do
    schedules =
      Enum.map(
        program.schedules,
        &Schedule.from_program_schedule/1
      )

    %__MODULE__{program: program, schedules: schedules}
  end

  def to_program_attributes(changeset) do
    with {:ok, %__MODULE__{program: program, schedules: schedules}} <-
           apply_action(changeset, :validate) do
      schedules = Enum.map(schedules, &Schedule.to_program_schedule_attrs/1)

      attrs =
        Map.from_struct(program)
        |> Map.put(:schedules, schedules)

      {:ok, attrs}
    end
  end
end
