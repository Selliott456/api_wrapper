defmodule NihApiWrapper.NihApiClient do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://www.assessmentcenter.net/ac_api/"
  plug Tesla.Middleware.JSON
  # make this less yikes in terms of security
  plug Tesla.Middleware.BasicAuth,
    username: "E311151C-D7CE-431C-BDF5-C6E7E2161F10",
    password: "3574FC35-6E21-405A-AF10-87ECBEEE8837"

  @adapter Tesla.Adapter.Hackney

  def administer_survey() do
    # create the assessment
    # get the first question
    # display the first question
    # get the user's response
    # send the response
    # get the next question
    # ....
    # get the last question
    # send the response

  end

  # In some other module in a galaxy far away
  # def administer_question(oid) do
    # with {:ok, next_question} <- next_question(oid) do
      # response = get_user_response(next_question)
      # send_response(response)
    # end
  # end

  def create_assessment(oid) do
    with {:ok, response} <- api_get_request("2014-01/Assessments/#{oid}.json") do
      Jason.decode!(response.body)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def next_question(assessment_token) do

  end

  def send_response(assessment_token, item_response_oid, response_value ) do

  end

  def retrieve_scored_assessment(assessment_token) do

  end



  def get_all_forms() do
    with {:ok, response} <- api_get_request("/2014-01/Form/.json") do
      Jason.decode!(response.body)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def api_get_request(url, error_msg \\ "Unexpected response ") do
    case get(url) do
      {:ok, %Tesla.Env{status: 200} = response} ->
        {:ok, response}

      {:ok, response} ->
        {:error, error_msg <> " #{inspect response}"}

      {:error, reason} ->
        {:error, error_msg <> " #{inspect reason}"}
    end
  end

  def api_post_request(url, body, error_msg \\ "Unexpected response ") do
    case post(url, body) do
      {:ok, %Tesla.Env{status: 200} = response} ->
        {:ok, response}

      {:ok, response} ->
        {:error, error_msg <> " #{inspect response}"}

      {:error, reason} ->
        {:error, error_msg <> " #{inspect reason}"}
    end
  end
end
