# frozen_string_literal: true

require 'uri'

# Validate whether text fields contain external links
class ContainsExternalLinksValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    uris = extract_uris(value)
    record.errors.add(attribute, 'cannot contain external links') if uris.length.positive?
  end

  private

  def extract_uris(value)
    URI.extract(value)
  end
end

# app/models/document_type.rb
class DocumentType < ApplicationRecord
  has_paper_trail

  belongs_to :user, optional: true

  has_many :documents

  validates :name, length: { maximum: 50 }
  validates :name, presence: true
  validates :name, uniqueness: true
  validates :name, contains_external_links: true
  validates_format_of :name, with: /^[a-zA-Z\d ]*$/i, multiline: true, message: 'can only contain letters and numbers.'
  validates :description, presence: true
  validates :description, uniqueness: true
  validates :description, length: { maximum: 200 }
  validates :description, contains_external_links: true
  validates :status, inclusion: { in: %w[approved pending declined], allow_nil: false }
end
