class HDocument < ApplicationRecord
  self.table_name = 'document'
  validates :web_uri, uniqueness: true
end