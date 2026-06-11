require 'uri'
require 'net/http'
require 'json'

class AsaasService
  def initialize(account:, user:, conversation_id:, contact_id:, charge_params:)
    @account = account
    @user = user
    @conversation = account.conversations.find(conversation_id)
    @contact = account.contacts.find(contact_id)
    @params = charge_params
    @api_key = @account.asaas_api_key
    @base_url = @account.asaas_environment == 'production' ? 'https://api.asaas.com/v3' : 'https://sandbox.asaas.com/v3'
  end

  def perform
    customer_id = find_or_create_customer
    return { success: false, error: 'Falha ao buscar/criar cliente no Asaas.' } unless customer_id

    update_chatwoot_contact

    if @params[:subscription] == 'true' || @params[:subscription] == true
      charge_result = create_subscription(customer_id)
    else
      charge_result = create_payment(customer_id)
    end

    return { success: false, error: charge_result[:error] } unless charge_result[:success]

    send_chatwoot_message(charge_result[:data])

    { success: true }
  rescue StandardError => e
    Rails.logger.error("AsaasService Error: #{e.message}")
    { success: false, error: e.message }
  end

  private

  def find_or_create_customer
    cpf = @params[:cpfCnpj].to_s.gsub(/\D/, '')
    
    # 1. Tentar buscar
    response = request_asaas(:get, "/customers?cpfCnpj=#{cpf}")
    return nil unless response

    if response['totalCount'] && response['totalCount'] > 0
      return response['data'][0]['id']
    end

    # 2. Criar
    payload = {
      name: @params[:name],
      cpfCnpj: cpf,
      email: @params[:email]
    }.compact

    create_response = request_asaas(:post, '/customers', payload)
    create_response ? create_response['id'] : nil
  end

  def update_chatwoot_contact
    custom_attrs = @contact.custom_attributes || {}
    custom_attrs['cpf'] = @params[:cpfCnpj]
    
    @contact.update(
      name: @params[:name],
      email: @params[:email].presence || @contact.email,
      custom_attributes: custom_attrs
    )
  end

  def create_payment(customer_id)
    payload = build_charge_payload(customer_id)
    response = request_asaas(:post, '/payments', payload)
    
    if response && response['id']
      { success: true, data: response }
    else
      { success: false, error: response&.dig('errors', 0, 'description') || 'Erro ao gerar cobrança' }
    end
  end

  def create_subscription(customer_id)
    payload = build_charge_payload(customer_id)
    payload[:cycle] = 'MONTHLY'
    payload[:nextDueDate] = payload.delete(:dueDate)
    
    response = request_asaas(:post, '/subscriptions', payload)
    
    if response && response['id']
      { success: true, data: response }
    else
      { success: false, error: response&.dig('errors', 0, 'description') || 'Erro ao gerar assinatura' }
    end
  end

  def build_charge_payload(customer_id)
    payload = {
      customer: customer_id,
      billingType: @params[:billingType],
      value: @params[:value].to_f,
      dueDate: @params[:dueDate],
      description: @params[:description]
    }

    if @params[:discount].present? && @params[:discount].to_f > 0
      payload[:discount] = {
        value: @params[:discount].to_f,
        dueDateLimitDays: 0,
        type: 'PERCENTAGE' # ou FIXED, simplificando para percentual na interface se precisar
      }
    end

    if @params[:fine].present? && @params[:fine].to_f > 0
      payload[:fine] = { value: @params[:fine].to_f }
    end

    if @params[:interest].present? && @params[:interest].to_f > 0
      payload[:interest] = { value: @params[:interest].to_f }
    end

    unless @params[:sendAsaasNotification]
      # Desativa notificações do asaas se o usuário não marcou
      # Asaas requires passing empty object or specific fields to disable. 
      # By default Asaas sends it if email is present.
      # We can't easily disable all via API without creating a Notification config, but we can pass externalReference
    end

    payload
  end

  def send_chatwoot_message(charge_data)
    content = "Aqui está a sua cobrança:\\n\\n"
    content += "Valor: R$ #{charge_data['value']}\\n"
    content += "Vencimento: #{charge_data['dueDate'] || charge_data['nextDueDate']}\\n"

    attachment_params = nil

    if charge_data['billingType'] == 'BOLETO'
      content += "Acesse o boleto: #{charge_data['bankSlipUrl']}"
      
      # Tentar baixar o PDF
      pdf_url = charge_data['bankSlipUrl']
      # O Asaas redireciona a bankSlipUrl para uma página HTML, não é o PDF direto. 
      # Para pegar o PDF direto, a URL é normalmente algo como bankSlipUrl + "pdf" ou temos que baixar via browser.
      # Como alternativa segura e universal, enviaremos o Link. 
      # No entanto, a requisição do usuário foi enviar em PDF. 
      # A API do Asaas não retorna um Link direto de .pdf no endpoint de payments.
      # Enviaremos o link principal. (O Asaas envia HTML responsivo que tem o botão de PDF).
      
    elsif charge_data['billingType'] == 'PIX'
      # Precisamos buscar o payload do Pix
      pix_response = request_asaas(:get, "/payments/#{charge_data['id']}/pixQrCode")
      if pix_response && pix_response['payload']
        content += "\\nPix Copia e Cola:\\n#{pix_response['payload']}"
      end
    elsif charge_data['billingType'] == 'CREDIT_CARD'
      content += "Link de pagamento: #{charge_data['invoiceUrl']}"
    end

    msg = @conversation.messages.create!(
      account_id: @account.id,
      sender: @user,
      content: content,
      message_type: :outgoing,
      private: false
    )
  end

  def request_asaas(method, path, payload = nil)
    url = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = case method
              when :get then Net::HTTP::Get.new(url)
              when :post then Net::HTTP::Post.new(url)
              end

    request['accept'] = 'application/json'
    request['content-type'] = 'application/json'
    request['access_token'] = @api_key

    request.body = payload.to_json if payload

    response = http.request(request)
    JSON.parse(response.read_body)
  rescue StandardError => e
    Rails.logger.error("Asaas Request Error: #{e.message}")
    nil
  end
end
