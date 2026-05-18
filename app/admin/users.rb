ActiveAdmin.register User do
  permit_params :email, :username, :curator, :admin, :bot, :deactivated, :verified_contributor

  index do
    selectable_column
    id_column
    column :email
    column :username
    column :admin
    column :curator
    column :verified_contributor
    column :approved_points_count
    column :level
    column :bot
    column :deactivated
    column :created_at
    actions
  end

  filter :email
  filter :username
  filter :admin
  filter :curator
  filter :verified_contributor
  filter :level
  filter :bot
  filter :deactivated
  filter :created_at
end
