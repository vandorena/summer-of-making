# frozen_string_literal: true

class DevlogPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    user && user == record.project.user
  end

  def update?
    user && user == record.user
  end

  def destroy?
    user && (user == record.user || user.is_admin?)
  end

  def api_create?
    false # do we really need this??
  end
end
