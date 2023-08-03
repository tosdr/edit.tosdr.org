# frozen_string_literal: true

# app/models/concerns/ota.rb
module Ota
  extend ActiveSupport::Concern

  # The code inside the included block is evaluated
  # in the context of the class that includes the Visible concern.
  # You can write class macros here, and
  # any methods become instance methods of the including class.
  included do
    def ota_documents(link, terms_type = nil)
      res = Ota::RetrieveDocumentService.new(ota_service_link: link).document
      body = JSON.parse(res.body)
      # return nil if no terms for service
      return nil if body['terms'].empty?

      # return terms from response if no filter
      return body['terms'] unless terms_type

      # filter terms if filter
      terms = body['terms']
      terms.select { |t| t['type'] == terms_type }
    end
  end

  # The methods added inside the class_methods block (or, ClassMethods module)
  # become the class methods on the including class.
  # class_methods do
  # end
end
