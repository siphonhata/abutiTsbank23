defmodule TsbankWeb.UserController do
  use TsbankWeb, :controller
 require Logger
  alias TsbankWeb.{Auth.Guardian, Auth.ErrorResponse}
  alias Tsbank.{Users, Admins, Admins.Admin, Users.User, Customers, Customers.Customer}
  alias CounterServer

  action_fallback TsbankWeb.FallbackController



  def index(conn, _params) do
    users = Users.list_users()
    render(conn, :index, users: users)
  end

  @spec create(any(), map()) :: any()
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Users.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user),
         {:ok, %Customer{} = customer} <-  Customers.create_customer(user, user_params) do
        Logger.info("User Customer Created.")
      conn
        |> put_status(:created)
        |> render(:showDataCustomer, user: user, customer: customer, token: token)
    end
  end

  def sign_in(conn, %{"email" => email,  "password" => password}) do
     case Guardian.authenticate(email, password) do
       {:ok, user, token} ->
        customer =Users.get_customer_user(Guardian.get_me_id(user.id))
        Users.update_user(%User{} = user, %{lastLoginDate: DateTime.utc_now})
        Logger.info("User succesfully logged in.")
        conn
          |> Plug.Conn.put_session(:user_id, user.id)
          |> put_status(:ok)
          |> render(:showDataLogin, user: user, customer: customer, token: token)
       {:error, :unauthorized} ->
          Logger.error("Email or Password incorrect.")
          raise ErrorResponse.Unauthorized, message: "Email or Password incorrect."
     end
  end

  def show(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    render(conn, :show, user: user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Users.get_user!(id)
    with {:ok, %User{} = user} <- Users.update_user(user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Users.get_user!(id)
    with {:ok, %User{}} <- Users.delete_user(user) do
      send_resp(conn, :no_content, "Deleted")
    end
  end

  ################ADMINS

  def createAdmin(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Users.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user),
         {:ok, %Admin{} = admin} <-  Admins.create_admin(user, user_params) do
      conn
        |> put_status(:created)
        |> render(:showDataAdmin, user: user, admin: admin, token: token)
    end
  end

  def log_in(conn, %{"email" => email,  "password" => password}) do
    case Guardian.authenticate(email, password) do
      {:ok, user, token} ->
        #IO.inspect(user)
        #update_account(%Account{} = account, %{lastLoginDate: DateTime.utc_now})
       conn
         |> Plug.Conn.put_session(:user_id, user.id)
         |> put_status(:ok)
         |> render(:showAdminData, user: user, token: token)
         {:error, :unauthorized} -> raise ErrorResponse.Unauthorized, message: "Email or Password incorrect."
    end
 end

end
