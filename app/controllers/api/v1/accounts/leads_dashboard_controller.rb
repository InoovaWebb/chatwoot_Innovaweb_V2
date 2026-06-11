require 'csv'

class Api::V1::Accounts::LeadsDashboardController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    start_date = parse_date(params[:start_date]) || Time.zone.now.beginning_of_month
    end_date   = parse_date(params[:end_date])&.end_of_day || Time.zone.now.end_of_day
    inbox_id   = params[:inbox_id].presence

    conversations = Current.account.conversations.where(created_at: start_date..end_date)
    conversations = conversations.where(inbox_id: inbox_id) if inbox_id

    contact_ids = conversations.pluck(:contact_id).uniq.compact

    # Total de leads únicos no período
    total_leads = contact_ids.size

    # Leads por dia para o gráfico
    leads_per_day = conversations
      .group("DATE(created_at)")
      .select("DATE(created_at) as day, COUNT(DISTINCT contact_id) as count")
      .map { |r| { date: r.day.to_s, count: r.count.to_i } }
      .sort_by { |r| r[:date] }

    # Resumo de etiquetas das conversas no período
    conversation_ids = conversations.pluck(:id)
    label_counts = ConversationLabel
      .where(conversation_id: conversation_ids)
      .joins("INNER JOIN labels ON labels.title = conversation_labels.label AND labels.account_id = #{Current.account.id}")
      .group("conversation_labels.label, labels.color")
      .select("conversation_labels.label, labels.color, COUNT(DISTINCT conversation_labels.conversation_id) as count")

    labels_summary = label_counts.map do |l|
      {
        label: l.label,
        color: l.color,
        count: l.count.to_i,
        percentage: total_leads > 0 ? ((l.count.to_f / total_leads) * 100).round(1) : 0
      }
    end.sort_by { |l| -l[:count] }

    # Conversas sem etiqueta
    conversations_with_labels = ConversationLabel.where(conversation_id: conversation_ids).distinct.pluck(:conversation_id)
    conversations_without_labels = conversation_ids.size - conversations_with_labels.size
    without_label_count = conversations_without_labels > 0 ? conversations_without_labels : 0

    render json: {
      total_leads: total_leads,
      leads_per_day: leads_per_day,
      labels_summary: labels_summary,
      without_label_count: without_label_count,
      period: {
        start_date: start_date.strftime('%d/%m/%Y'),
        end_date: end_date.strftime('%d/%m/%Y')
      }
    }
  end

  private

  def parse_date(value)
    return nil if value.blank?

    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    nil
  end
end
