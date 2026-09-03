class ReviewPolicy < ApplicationPolicy
  # A review belongs to a lunch, and a lunch belongs to one user. Every
  # question this policy answers is that one.
  def new?
    create?
  end

  def create?
    record.go_meal_match.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:go_meal_match).where(go_meal_matches: { user: user })
    end
  end
end
