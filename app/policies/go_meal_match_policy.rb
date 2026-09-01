class GoMealMatchPolicy < ApplicationPolicy

  def like?
    true
  end

  def reject?
    true
  end

  def show?
    true
  end

  def not_visited?
    record.user == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
