class Spam < ApplicationRecord
  belongs_to :spammable, polymorphic: true
end
