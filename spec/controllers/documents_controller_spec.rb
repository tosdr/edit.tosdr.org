require 'rails_helper'

# spec/controllers/documents_controller_spec.rb
describe DocumentsController do
  login_user

  context 'OTA API' do
    describe '#show' do
      it 'retrieves the document' do
        # searches for the document's service in federated collection api
        # traverses the results to find the terms
        # retrieves the document from the first service result to contain the terms
      end
    end

    describe '#update' do
      context 'document sourced from non-tosdr collection' do
        it '?' do
          # what is the expected behavior here?
        end
      end

      context 'document sourced from tosdr collection' do
        it '?' do
          # what PATCH functionalities are available over the API, if any?
        end
      end
    end

    describe '#create' do
      context 'service exists in collection, document does not' do
        it 'instructs users to contribute a PR to the collection' do
        end
      end
      context 'neither service nor document exists in any collection' do
        it 'creates the service and the document in the tosdr collection' do
        end
      end
    end

    describe '#destroy' do
      it '?' do
        # Do collections allow for DELETE requests?
      end
    end
  end
end
