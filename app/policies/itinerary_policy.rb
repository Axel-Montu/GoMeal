class ItineraryPolicy < ApplicationPolicy
  def create?
    # The controller already looked among this user's matches only.
    # Saying it here too puts the rule where it can be read.
    record.user == user
  end

  def show?
    create?
  end
end
