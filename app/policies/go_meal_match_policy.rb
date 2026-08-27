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

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user: user)
    end
  end
end
