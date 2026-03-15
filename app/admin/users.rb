ActiveAdmin.register User do
  permit_params :email, :username, :curator, :admin, :bot, :deactivated

  index do
    selectable_column
    id_column
    column :email
    column :username
    column :admin
    column :curator
    column :bot
    column :deactivated
    column :created_at
    actions
  end

  filter :email
  filter :username
  filter :admin
  filter :curator
  filter :bot
  filter :deactivated
  filter :created_at
end
