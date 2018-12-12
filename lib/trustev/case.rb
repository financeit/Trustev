require 'nokogiri'
require 'rest-client'

module Trustev
  class Case
    def initialize(loan, session_id)
      @loan = loan
      @session_id = session_id
    end

    def post
      response = resource.post(payload.to_json)
      @response_hash = ::Services::DataConverter.case_response_to_hash(response)
    end

    def response
      response_hash
    end

    def error_code
      te_response['ErrorCode']
    end

    def error_text
      te_response['ErrorText']
    end

    def error?
      error_code != CaseResponseErrorCodes::NO_ERROR
    end

    def risk
      context_data['Decision'] unless error?
    end

    def score
      te_detailed_decision['Score'] unless error?
    end

    private

    attr_reader :loan, :session_id

    def resource
      RestClient::Resource.new(
        Trustev.configuration.url,
        headers: {
          accept: :json,
          content_type: :json
        }
      )
    end

    def payload
      {
        Authentication: authentication,
        RequestInfo: request_info,
        Fields: fields
      }
    end

    def authentication
      {
        Type: 'OnDemand',
        UserId: Trustev.configuration.username,
        Password: Trustev.configuration.password
      }
    end

    def request_info
      {
        SolutionSetId: Trustev.configuration.solution_set_id,
        ExecuteLatestVersion: true,
        ExecutionMode: 3
      }
    end

    def fields
      hash = {
        ExternalApplicationId: "FIT_#{loan.id}",
        TUAdditionalData: tu_additional_data,
        SessionID: session_id,
        Language: 'en-CA',
        Applicant: applicant
      }
      hash[:messageType] = 'T' unless Trustev.configuration.is_production

      ::Services::DataConverter.hash_to_key_value_pairs(hash)
    end

    def tu_additional_data
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.TUAdditionalData do
          xml.ReferenceID
        end
      end

      builder.to_xml
    end

    def applicant
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.Applicant do
          xml.FirstName borrower.first_name
          xml.LastName borrower.last_name
          xml.Email borrower.email
          xml.AddressPhoneNumber borrower.mobile_phone_number
          xml.UnparsedAddrLine1 borrower.address
          xml.AddressCity borrower.city
          xml.AddressStProv borrower.province
          xml.AddressZipPostal borrower.postal_code
          xml.PreviousUnparsedAddrLine1 borrower.former_address
          xml.PreviousAddressCity borrower.former_city
          xml.PreviousAddressStProv borrower.former_province
          xml.PreviousAddressZipPostal borrower.former_postal_code
          xml.EmployerName borrower.employer_name
          xml.Occupation borrower.position_title
          xml.BirthDate borrower.birthdate.to_s(:insurance)
          xml.SIN borrower.sin_number
        end
      end

      builder.to_xml
    end

    def borrower
      @borrower ||= loan.borrower
    end

    def response_hash
      @response_hash || {}
    end

    def context_data
      @context_data ||= response_hash['ContextData']
    end

    def te_response
      @te_response ||= context_data['TEResponse']
    end

    def te_detailed_decision
      @te_detailed_decision ||= te_response['TrustevDetailedDecision']
    end
  end
end
