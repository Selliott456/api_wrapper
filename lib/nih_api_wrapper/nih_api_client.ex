defmodule NihApiWrapper.NihApiClient do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://www.assessmentcenter.net/ac_api/"
  plug Tesla.Middleware.JSON
  # make this less yikes in terms of security
  plug Tesla.Middleware.BasicAuth,
    username: "E311151C-D7CE-431C-BDF5-C6E7E2161F10",
    password: "3574FC35-6E21-405A-AF10-87ECBEEE8837"

@doc """
 Fetches specific assessment form, identified by OID. returns an assessment token.
  """
  def create_assessment(oid) do
    with {:ok, response} <- api_get_request("2014-01/Assessments/#{oid}.json") do
    Jason.decode!(response.body)

    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  uses assessment token to either administer an assessment or continue an assessment, depending on if the DateFinished property returns an empty string or not.
  """
  def next_question(assessment_token) do
    with {:ok, response} <- api_get_request("2014-01/Participants/#{assessment_token}.json") do
      Jason.decode!(response.body)
    else
      {:error, reason} ->
        %{"DateFinished" => "2/13/2017 3:02:41 PM","Items" => []}
    end
  end


  @doc """
  sends the response of each question in the assessment with question oid and the value of the response chosen.
  """
  def send_response(assessment_token, item_response_oid, response_value ) do
    with {:ok, response} <- api_get_request("2014-01/Participants/#{assessment_token}.json?ItemResponseOID=#{item_response_oid}&Response=#{response_value})") do
      Jason.decode!(response.body)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Sends the assessment item values to be scored.
  """
  def retrieve_scored_assessment(assessment_token) do
    with {:ok, response} <- api_get_request("2014-01/Results/#{assessment_token}.json") do
      Jason.decode!(response.body)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc"""
  fetches all NIH forms.
  """
  def get_all_forms() do
    with {:ok, response} <- api_get_request("/2014-01/Forms/.json") do
      Jason.decode!(response.body)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc"""
  the body of a get request with a base url that can be used for every function that requires it.
  """
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

  @doc"""
  the body of a post request with a base url that can be used for every function that requires it.
  """
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
