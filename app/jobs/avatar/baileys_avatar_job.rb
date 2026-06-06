class Avatar::BaileysAvatarJob < ApplicationJob
  queue_as :low

  def perform(contact, phone, inbox_id)
    return unless contact.respond_to?(:avatar)
    return if contact.avatar.attached?

    inbox = Inbox.find_by(id: inbox_id)
    return unless inbox

    jid = "#{phone}@s.whatsapp.net"
    response = inbox.channel.provider_service.get_profile_pic(jid)
    avatar_url = response&.dig('data', 'profilePictureUrl')
    
    return unless avatar_url.present?

    ::Avatar::AvatarFromUrlJob.perform_now(contact, avatar_url)
  rescue StandardError => e
    Rails.logger.error "Avatar::BaileysAvatarJob failed for #{phone}: #{e.message}"
  end
end
