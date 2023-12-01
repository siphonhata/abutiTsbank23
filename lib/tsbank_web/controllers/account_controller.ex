defmodule TsbankWeb.AccountController do
  use TsbankWeb, :controller

#  alias Tsbank.Repo
  alias Tsbank.{Accounts, Accounts.Account}
  alias Tsbank.{Users}
  alias TsbankWeb.{Auth.Guardian, Auth.ErrorResponse}

  action_fallback TsbankWeb.FallbackController

  def index(conn, _params) do
    accounts = Accounts.list_accounts()
    render(conn, :index, accounts: accounts)
  end

  def create(conn, %{"account" => account_params}) do

    cust_id = Guardian.get_me_id(conn.assigns.user.user_id)
    custom = Users.get_customer_user(cust_id) # returns a customer
    accounts = Accounts.get_customer_accounts_by_id(cust_id)

    account_types = ["savings", "fixed", "credit", "cheque"]
    target_value = Map.get(account_params, "type")

    case {accounts, target_value} do
      {[], _} ->
        if Enum.member?(account_types, target_value) do
          account_params = Map.put(account_params, "dateOpened", DateTime.utc_now)
          with {:ok, %Account{} = account} <- Accounts.create_account(custom, account_params) do
            conn
            |> put_status(:created)
            |> render(:show, account: account)
          end
        else
          raise ErrorResponse.Unauthorized, message: "Invalid Account Type"
        end

      {existing_account_types, target_value}  ->
              IO.inspect(existing_account_types)
              Enum.each(existing_account_types, fn val ->
              if val.type == target_value do
                conn
                  |> put_status(:unprocessable_entity)
                  |> render(:error, message: "Customer already has an existing account with account type #{target_value}")
              else
                with {:ok, %Account{} = account} <- Accounts.create_account(custom, account_params) do
                  conn
                  |> put_status(:created)
                  |> render(:show, account: account)
                end

        end
    end)
    end

  end

  def show(conn, %{"id" => id}) do
    account = Accounts.get_account!(id)
    render(conn, :status, account: account)
  end

  def update(conn, %{"id" => id, "account" => account_params}) do
    account = Accounts.get_account!(id)
    with {:ok, %Account{} = account} <- Accounts.update_account(account, account_params) do
      render(conn, :show, account: account)
    end
  end

  def delete(conn, %{"id" => id}) do
    account = Accounts.get_account!(id)

    with {:ok, %Account{}} <- Accounts.delete_account(account) do
      send_resp(conn, :no_content, "")
    end
  end

  def customerAccounts(conn, %{"customer_id" => customer_id}) do
    accounts = Accounts.get_customer_accounts_by_id(customer_id)
    # IO.puts "========================="
    # IO.inspect(accounts)
    # IO.puts "+++++++++++++++++++++++++++++"
    # # accounts_as_maps = Enum.map(accounts, &Map.from_struct/1)
    # # types_list = Enum.map(accounts_as_maps, &(&1.type))
    # #acc_map = Map.from_struct(accounts)
    # IO.inspect(types_list)
    # #IO.inspect(Map.from_struct(accounts))
    # IO.puts "+++++++++++++++++++++++++++++"
    render(conn, :showAccounts, accounts: accounts)

  end

  def view_one_account(conn, %{"account_id" => account_id}) do
    account = Accounts.get_single_account(account_id)
    render(conn, :showSpecificAccount, account: account)
  end

  def view_all_accounts(conn, _params) do
    accounts = Accounts.list_accounts()
    render(conn, :showAccounts, accounts: accounts)
  end


  def status_update(conn, %{"account_id" => account_id}) do
    account = Accounts.get_single_account(account_id)
    if account.status == "true" do
      with {:ok, %Account{} = account} <- Accounts.update_account(account, %{status: "false"}) do
        render(conn, :show, account: account)
      end
    else
      with {:ok, %Account{} = account} <- Accounts.update_account(account,  %{status: "true"}) do
        render(conn, :show, account: account)
      end
    end
    #Map.put(user_params, "end_date", DateTime.utc_now)
  end

  def get_account_types_per_customer(customer_id) do
    customer = Tsbank.Customers.get_customer!(customer_id)
    #customer = get_customer!(Tsbank.Customer, customer_id)
    customer
  end
end
