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
displays requested forms
"""
  def display_forms() do

    display_list = ["PROMIS Bank v2.0 - Physical Function (recommended)\n",
      "PROMIS Bank v2.1 - Upper Extremity (recommended)\n",
      "PROMIS Bank v1.1 - Pain Interference (recommended)\n",
      "PROMIS Bank v1.0 - Anxiety\n"]

    IO.puts(display_list)
    display_list
  end

  @doc """
  allows user to select a form by number and finds form name using it as index
  """

  def select_form(display_list) do
    form_list = NAC.get_all_forms()["Form"]
    form_number = IO.gets("ENTER FORM NUMBER\n")
    |> to_string()
    |> String.trim("\n")
    |> String.to_integer()

    handle_errors({form_number, form_list}, display_list)


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

    case date_finished do
      "" ->
        get_question_elements(items)
        |> display_question()
        |> parse_and_send_response(assessment_token)
#
        administer_question(assessment_token)
      _ -> nil
    end
  end


@doc"""
Breaks down the elements of the question into a prompt
and answer. The answer is the last item in `items`.
"""

  def get_question_elements(items) do
    item =  Enum.at(items, 0)
    elements = item["Elements"]
    |> Enum.reverse()
    [answers | question] = elements

    {answers, question}
  end

  @doc """
  Displays the prompts and answers and captures a users response
  as a ~c"raw_response"
  """

  def display_question({answers, question}) do
    Enum.map(question, fn question -> IO.puts(question["Description"]) end)

    raw_response = IO.gets(Enum.map(answers["Map"], fn(answer)-> "#{answer["Position"]} - #{answer["Description"]} \n" end ))
    response_number =  raw_response
    |> to_string()
    |> String.at(0)

    handle_errors(response_number, answers, question)
  end

  @doc"""
  parses the user response and finds the answer that matches.
  Then sends it to API as an ItemResponseOID and a value
  """
  def parse_and_send_response({response_number, answers, question}, assessment_token) do
    %{
      "ItemResponseOID" => item_response_oid,
      "Value" => response_value
    } = Enum.find(answers["Map"], fn map -> map["Position"] == response_number end)
    NAC.send_response(assessment_token, item_response_oid, response_value)

  end

  @doc"""
  posts completed survey to API. Returns results object.
  """
  def get_results(assessment_token) do
    NAC.retrieve_scored_assessment(assessment_token)
  end

  @doc """
  handles for selection errors
  """
  def handle_errors({form_number, form_list} , display_list) do
    unless form_number < 1 or form_number > length(display_list) + 1 do
      form_index = form_number - 1
      form_name = Enum.at(display_list, form_index)
      |> String.trim("\n")

      {form_name, form_list}
    else
      IO.puts("INCORRECT SELECTION - FORM DOES NOT EXIST")
      select_form(display_list)
    end
  end


  @doc """
  handles question response errors
  """
  def handle_errors(response_number, answers, question) do
    unless String.to_integer(response_number) > 5 or String.to_integer(response_number) < 1 do
      {response_number, answers, question}
    else
      IO.puts("INVALID RESPONSE")
    display_question({answers, question})
    end
  end

end
