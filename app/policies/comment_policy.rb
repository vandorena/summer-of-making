# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    user && (user == record.user || user.is_admin?)
  end
end
