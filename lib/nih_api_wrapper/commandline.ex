defmodule NihApiWrapper.Commandline do
  alias NihApiWrapper.NihApiClient, as: NAC

  def main() do
    assessment_token =
      display_forms()
      |> select_form()
      |> get_assessment_token()

      administer_question(assessment_token)

      get_results(assessment_token)
  end


@doc"""
fetches all forms and displays the top 5 results (so not to have to deal with all of them)
"""
  def display_forms() do
    form_list = NAC.get_all_forms()["Form"]
    display_list = form_list
    |> Enum.map(fn form -> "#{form["Name"]}\n" end )
    |> Enum.take(5)

    IO.puts(display_list)
    {display_list, form_list}
  end

  @doc """
  allows user to select a form by number and finds form name using it as index
  """
  def select_form({display_list, form_list}) do
    form_number = IO.gets("ENTER FORM NUMBER\n")
    |> to_string()
    |> String.trim("\n")
    |> String.to_integer()

    form_index = form_number - 1
    form_name = Enum.at(display_list, form_index)
    |> String.trim("\n")

    {form_name, form_list}
  end

  @doc"""
  takes the from/assessment oid and creates an instance of it,
  returning an assessment token.
  """
  def get_assessment_token({form_name, form_list}) do
    %{"OID" => oid} = Enum.find(form_list, fn map -> map["Name"] == form_name end)

    assessment = NAC.create_assessment(oid)
    assessment_token = assessment["OID"]

    assessment_token
  end

  @doc"""
  recursively calls the next question until the form is marked
  as complete via a string in its "DateFinished" field
  """
  def administer_question (assessment_token) do
    %{"DateFinished" => date_finished, "Items" => items} = NAC.next_question(assessment_token)

    get_question_elements(items)
    |> display_question()
    |> parse_and_send_response(assessment_token)

    case date_finished do
      "" -> administer_question(assessment_token)
      _ -> nil
    end
  end


@doc"""
Breaks down the elements of the question into a prompt
and answer. The answer is always last, and the prompts
come in one or two parts, answer is taken off as first
item after reversing.
"""
  def get_question_elements(items) do

    item =  Enum.at(items, 0)
    elements = item["Elements"]
    |> Enum.reverse()

    [answers, question] = elements

    {question, answers}
  end

  @doc """
  Displays the prompts and answers and captures a users response
  as a ~c"raw_response"
  """
  def display_question({question, answers}) do
    IO.puts(question["Description"])

    # case question do
      # is_list -> question
      # |>Enum.reverse()
      # |> Enum.map(fn item -> IO.puts (item["Description"]) end)
      # _ -> IO.puts(question["Description"])
    # end

    # ^ see Steven

    raw_response = IO.gets(Enum.map(answers["Map"], fn(answer)-> "#{answer["Position"]} - #{answer["Description"]} \n" end ))

    {raw_response, answers}
  end

  @doc"""
  parses the user response and finds the answer that matches.
  Then sends it to API as an ItemResponseOID and a value
  """
  def parse_and_send_response({raw_response, answers}, assessment_token) do
    response_number =  raw_response
    |> to_string()
    |> String.at(0)

    %{
      "ItemResponseOID" => item_response_oid,
      "Value" => response_value
    } = Enum.find(answers["Map"], fn map -> map["Position"] == response_number end)
    NAC.send_response(assessment_token, item_response_oid, response_value)
  end

  @doc"""
  posts completed survey to API. Currently blows up.... I think I've done the post request wrong but I cant see how.
  """
  def get_results(assessment_token) do
    NAC.retrieve_scored_assessment(assessment_token)
  end

end
