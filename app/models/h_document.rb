# frozen_string_literal: true

# app/models/h_document.rb
class HDocument < ApplicationRecord
  self.table_name = 'document'
  validates :web_uri, uniqueness: true
end
