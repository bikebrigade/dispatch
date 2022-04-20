defmodule BikeBrigade.Repo.Migrations.AddMessageTemplates do
  use Ecto.Migration
  import Ecto.Query

  alias BikeBrigade.Repo

  # keep the structs in here so the migrations are portable
  defmodule Template do
    use BikeBrigade.Schema

    schema "message_templates" do
      field(:body, :string)

      Ecto.Schema.timestamps()
    end
  end

  def up do
    create table(:message_templates) do
      add(:body, :text)
      timestamps()
    end

    alter table(:sms_messages) do
      add(:template_id, references(:message_templates))
    end

    alter table(:campaigns) do
      add(:instructions_template_id, references(:message_templates))
      add(:welcome_template_id, references(:message_templates))
    end

    flush()

    campaigns =
      Repo.all(
        from(c in "campaigns",
          where: not is_nil(c.message),
          select: {c.id, c.message}
        )
      )

    for {campaign_id, template} <- campaigns do
      {:ok, template} = Repo.insert(%Template{body: template})

      from(c in "campaigns",
        where: c.id == ^campaign_id,
        update: [set: [instructions_template_id: ^template.id]]
      )
      |> Repo.update_all([])
    end

    flush()

    alter table(:campaigns) do
      remove(:message)
      remove(:message_sent_at)
    end
  end

  def down do
    alter table(:sms_messages) do
      remove(:template_id)
    end

    alter table(:campaigns) do
      remove(:welcome_template_id)
      add(:message_sent_at, :utc_datetime)
      add(:message, :text)
    end

    flush()

    templates =
      Repo.all(
        from(t in "message_templates",
          join: c in "campaigns",
          on: c.instructions_template_id == t.id,
          select: {c.id, t.body}
        )
      )

    for {campaign_id, body} <- templates do
      from(c in "campaigns",
        where: c.id == ^campaign_id,
        update: [set: [message: ^body]]
      )
      |> Repo.update_all([])
    end

    flush()

    alter table(:campaigns) do
      remove(:instructions_template_id)
    end

    drop(table(:message_templates))
  end
end
