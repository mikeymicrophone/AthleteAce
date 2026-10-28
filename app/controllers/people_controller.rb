class PeopleController < ApplicationController
  def show
    @person = Person.find(params.expect(:id))
    @staff_tenures = @person.staff_tenures.includes(:person, :organization, :team).chronological
  end
end
