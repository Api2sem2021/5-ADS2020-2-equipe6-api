defmodule SakaVault.Auth do
  @moduledoc false

  alias SakaVault.{Accounts, Guardian, Krypto}
  alias SakaVault.Accounts.User

  def authenticate(%User{} = user) do
    {:ok, token, _} = Guardian.encode_and_sign(user, %{})

    {:ok, %{token: token, user: decrypt_user(user)}}
  end

  def authenticate(email, password) do
    with {:ok, %User{} = user} <- Accounts.find_by_email(email),
         true <- Argon2.verify_pass(password, user.password_hash) do
      authenticate(user)
    else
      false -> {:error, :invalid_password}
      {:ok, nil} -> {:error, :not_found}
    end
  end

  defp decrypt_user(%User{} = user) do
    user
    |> Krypto.decrypt()
    |> Map.take([:id, :name, :email])
  end
end
