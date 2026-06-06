class AddAttendantsQueueToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :attendants_queue, :jsonb, default: []
  end
end
