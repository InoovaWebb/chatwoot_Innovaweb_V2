class AsaasPolicy < ApplicationPolicy
  def show?
    @user.administrator?
  end

  def update?
    @user.administrator?
  end

  def create_charge?
    @user.administrator? || @user.agent?
  end
end
