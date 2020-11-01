defmodule SakaVault.Accounts do
  @moduledoc false

  alias SakaVault.Accounts.User
  alias SakaVault.{Krypto, Repo}

  def find(id) do
    {:ok, Repo.get(User, id)}
  end

  def find_by_email(email) do
    email_hash = Krypto.hash_value(email)

    {:ok, Repo.get_by(User, email_hash: email_hash)}
  end

  def create(attrs \\ %{}) do
    attrs
    |> User.changeset()
    |> create_secret()
    |> Krypto.encrypt()
    |> Repo.insert()
  end

  def process_request(request), do: request

  defp create_secret(%{valid?: false} = changeset), do: changeset

  defp create_secret(%{changes: user} = changeset) do
    secret_id = Krypto.secret_id(user)

    secret_key =
      [
        secret_id,
        Argon2.gen_salt()
      ]
      |> Enum.join("")
      |> Krypto.salt()
      |> Krypto.secret_key()

    with {:ok, _} <- secrets().create(secret_id, secret_key) do
      changeset
    end
  end

  defp secrets do
    Application.get_env(:sakavault, :secrets)
  end
end
