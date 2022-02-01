defmodule BikeBrigade.QueryContextTest do
  use BikeBrigade.DataCase

  alias BikeBrigade.QueryContext
  alias BikeBrigade.QueryContext.{Sort, Pager}

  test "new" do
    assert QueryContext.new(:foo, :desc) == %QueryContext{
             sort: %Sort{field: :foo, order: :desc},
             pager: nil,
             filters: []
           }

    assert QueryContext.new(:bar, :asc, 20) == %QueryContext{
             sort: %Sort{field: :bar, order: :asc},
             pager: %Pager{offset: 0, limit: 20},
             filters: []
           }
  end

  test "sort/3" do
    ctx = QueryContext.new(:foo, :desc, 20)

    assert %{sort: %Sort{field: :bar, order: :asc}} = QueryContext.sort(ctx, :bar, :asc)

    # pagination is reset when sorting
    assert %{pager: %{offset: 0}} =
             ctx
             |> QueryContext.next_page()
             |> QueryContext.sort(:bar, :asc)
  end

  describe "paging" do
    setup do
      %{ctx: QueryContext.new(:foo, :desc, 20), unpaged_ctx: QueryContext.new(:bar, :asc)}
    end

    test "next_page/1", %{ctx: ctx, unpaged_ctx: unpaged_ctx} do
      assert %{pager: %{offset: 20}} = ctx |> QueryContext.next_page()

      assert %{pager: %{offset: 40}} = ctx |> QueryContext.next_page() |> QueryContext.next_page()

      assert %{pager: nil} = unpaged_ctx |> QueryContext.next_page()
    end

    test "prev_page/1", %{ctx: ctx, unpaged_ctx: unpaged_ctx} do
      assert %{pager: %{offset: 0}} = ctx |> QueryContext.prev_page()

      assert %{pager: %{offset: 20}} =
               put_in(ctx.pager.offset, 40)
               |> QueryContext.prev_page()

      assert %{pager: %{offset: 0}} =
               put_in(ctx.pager.offset, 10)
               |> QueryContext.prev_page()

      assert %{pager: nil} = unpaged_ctx |> QueryContext.prev_page()
    end
  end

  describe "filters" do
    setup do
      %{ctx: QueryContext.new(:foo, :desc)}
    end

    test "add_filter/3", %{ctx: ctx} do
      assert %{filters: [{:foo, "hello"}]} = ctx |> QueryContext.add_filter({:foo, "hello"})

      assert %{filters: [{:foo, "hello"}, {:bar, "world"}]} =
               ctx
               |> QueryContext.add_filter({:foo, "hello"})
               |> QueryContext.add_filter({:bar, "world"})
    end

    test "set_filters/2", %{ctx: ctx} do
      assert %{filters: [{:bar, "world"}, {:baz, "!!"}]} =
               ctx
               |> QueryContext.add_filter({:foo, "hello"})
               |> QueryContext.set_filters([{:bar, "world"}, {:baz, "!!"}])
    end

    test "clear_filters/1", %{ctx: ctx} do
      assert %{filters: []} =
               ctx
               |> QueryContext.add_filter({:foo, "hello"})
               |> QueryContext.add_filter({:bar, "world"})
               |> QueryContext.clear_filters()
    end


  end
end
