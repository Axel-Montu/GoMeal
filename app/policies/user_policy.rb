class UserPolicy < ApplicationPolicy

  def edit?
    record == user
  end

  def update?
    record == user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(id: user.id)
    end
  end
end
