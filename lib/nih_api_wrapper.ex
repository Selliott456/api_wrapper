defmodule NihApiWrapper do
  # how often do we want to do this? Are we going to run it once and save the data in one of our tables? Should a data fetch be set on a chron? Maybe a Repo.all in a context rather than request.
  def get_forms() do
    NihApiWrapper.NihApiClient.get("2014-01/Forms/.json")
  end

  # display all forms with checkbox and set selected values as oid_list

  def administer_instruments(oid_list) do
    oid_list
    |> Enum.map(fn oid -> NihApiWrapper.NihApiClient.get("2014-01/Forms/#{oid}.json") end)

    # render instruments
  end

  # capture scores per question for each instrument using itemResponseOID
  # POST to assesment endpoint with UID and EXPIRATION (time in days assessment should be completed by) as header params
  # HOW DO WE CAPTURE UID? Do we have a users Table?
end
