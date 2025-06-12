class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def my_projects?
    index?
  end

  def create?
    user.has_hackatime?
  end

  def edit?
    update?
  end

  def update?
    user.is_admin? || user == record.user
  end

  def destroy?
    update?
  end

  def ship?
    update?
  end

  def follow?
    record.user != user &&
      !user.project_follows.exists?(project: record)
  end

  def unfollow?
    record.user != user &&
      user.project_follows.exists?(project: record)
  end

  def stake_stonks?
    update?
  end

  def unstake_stonks?
    update?
  end
end
