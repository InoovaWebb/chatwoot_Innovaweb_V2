class Api::V1::Accounts::AsaasController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def show
    render json: {
      asaas_api_key: Current.account.asaas_api_key.present? ? '********' : '',
      asaas_environment: Current.account.asaas_environment || 'sandbox'
    }
  end

  def update
    # Apenas atualiza a chave se ela não estiver mascarada (ou seja, se o usuário digitou uma nova)
    if params[:asaas_api_key].present? && params[:asaas_api_key] != '********'
      Current.account.asaas_api_key = params[:asaas_api_key]
    end
    
    if params[:asaas_environment].present?
      Current.account.asaas_environment = params[:asaas_environment]
    end
    
    Current.account.save!
    render json: { message: I18n.t('asaas.settings_updated', default: 'Configurações salvas com sucesso!') }
  end

  def create_charge
    unless Current.account.asaas_api_key.present?
      return render json: { error: 'Chave de API do Asaas não configurada.' }, status: :unprocessable_entity
    end

    service = AsaasService.new(
      account: Current.account,
      user: current_user,
      conversation_id: params[:conversation_id],
      contact_id: params[:contact_id],
      charge_params: charge_params
    )

    result = service.perform
    if result[:success]
      render json: { message: 'Cobrança gerada com sucesso!' }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def charge_params
    params.require(:charge).permit(
      :name, :email, :cpfCnpj, :value, :dueDate, :billingType,
      :description, :subscription, :fine, :interest, :discount, :sendAsaasNotification
    )
  end

  def check_authorization
    authorize :asaas, :show?, policy_class: AsaasPolicy if action_name == 'show'
    authorize :asaas, :update?, policy_class: AsaasPolicy if action_name == 'update'
    authorize :asaas, :create_charge?, policy_class: AsaasPolicy if action_name == 'create_charge'
  end
end
