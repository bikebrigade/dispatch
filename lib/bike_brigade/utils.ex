defmodule BikeBrigade.Utils do
  def dev? do
    Application.get_env(:bike_brigade, :environment) == :dev
  end

  def prod? do
    Application.get_env(:bike_brigade, :environment) == :prod
  end

  def test? do
    Application.get_env(:bike_brigade, :environment) == :test
  end

  defmacro get_config(keyword) do
    quote do
      config = Application.get_env(:bike_brigade, __MODULE__)

      case config[unquote(keyword)] do
        {:system, var, :optional} -> System.get_env(var)
        {:system, var} -> System.get_env(var) || raise "Missing environment variable #{var}"
        val when not is_nil(val) -> val
        nil -> raise "Missing configuration: :bike_brigade, #{__MODULE__}, :#{unquote(keyword)}"
      end
    end
  end

  def random_enum(enum) do
    enum.__enum_map__()
    |> Keyword.keys()
    |> Enum.random()
  end

  @doc "returns the given string, with a default if it's blank or nil"
  def with_default(nil, default), do: default
  def with_default("", default), do: default
  def with_default(value, _default), do: value

  @doc """
  `replace_if_updated` takes a struct or a list of structs to be tested and the updated struct.
  If the argument is a list, each item is tested.
  If the two arguments are the same struct and `id` field matches, it returns `updated` otherwise it returns `struct.
  Options:
    - `replace_with:` - specify an optional thing to replace with (e.g. replace_if_updated(foo, bar, nil)) will return nil if foo has the same id as bar
  """
  def replace_if_updated(_, updated, opts \\ [])

  def replace_if_updated(items, updated, opts) when is_list(items) do
    Enum.map(items, &replace_if_updated(&1, updated, opts))
  end

  def replace_if_updated(%mod{id: id}, %mod{id: id} = updated, opts) do
    Keyword.get(opts, :replace_with, updated)
  end

  def replace_if_updated(struct, _, _), do: struct

  def task_count(tasks) do
    Map.values(count_tasks(tasks)) |> Enum.sum()
  end

  def humanized_task_count(tasks) do
    count_tasks(tasks)
    |> Enum.map(fn {item, count} ->
      if count == 1 do
        "1 #{item.name}"
      else
        "#{count} #{item.plural_name}"
      end
    end)
    |> Enum.join(" and ")
  end

  def fetch_env!(cfg_section, key) do
    Application.fetch_env!(:bike_brigade, cfg_section)
    |> Keyword.fetch!(key)
  end

  def get_env(cfg_section, key, default \\ nil) do
    Application.get_env(:bike_brigade, cfg_section, [])
    |> Keyword.get(key, default)
  end

  def put_env(cfg_section, key, value) do
    cfg =
      Application.get_env(:bike_brigade, cfg_section, [])
      |> Keyword.put(key, value)

    Application.put_env(:bike_brigade, cfg_section, cfg)
  end

  @spec change_scheme(String.t(), String.t()) :: String.t()
  def change_scheme(url, scheme) do
    uri = URI.parse(url)
    first = uri.scheme |> String.length()
    last = url |> String.length()
    scheme <> String.slice(url, first..last)
  end

  defp count_tasks(tasks) do
    tasks
    |> Enum.reduce(%{}, fn task, counts ->
      new_counts =
        for task_item <- task.task_items, into: %{} do
          {task_item.item, task_item.count}
        end

      Map.merge(counts, new_counts, fn _k, v1, v2 -> v1 + v2 end)
    end)
  end



  @doc """
  Given a sorted list, returns a list of tuples `{x, group}`,
  where x is the result of calling `fun` on the elements in `group`.
  Maintains the sort order.
  """
  def ordered_group_by([], _fun), do: []
  def ordered_group_by([head | rest], fun), do: ordered_group_by(rest, [{fun.(head), [head]}], fun)

  def ordered_group_by([], [{key, group} | groups], _fun) do
    Enum.reverse([{key, Enum.reverse(group)} | groups])
  end

  def ordered_group_by([head | rest], [{last_key, group} | groups], fun) do
    key = fun.(head)
    if key == last_key do
      ordered_group_by(rest, [{key, [head | group]} | groups], fun)
    else
      ordered_group_by(rest, [{key, [head]} | [{last_key, Enum.reverse(group)} | groups]], fun)
    end
  end
end
