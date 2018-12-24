require 'nokogiri'
require 'rest-client'

module Trustev
  class Case
    def initialize(applicant_hash)
      @applicant_hash = applicant_hash
    end

    def post
      response = resource.post(payload.to_json)
      @response_hash = ::Services::DataConverter.case_response_to_hash(response)
    end

    def response_hash
      @response_hash || {}
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
      te_response['TEvRisk'] unless error?
    end

    def score
      te_detailed_decision['Score'] unless error?
    end

    def result
      te_detailed_decision['Result'] unless error?
    end

    def confidence
      te_detailed_decision['Confidence'] unless error?
    end

    def comment
      te_detailed_decision['Comment'] unless error?
    end

    private

    attr_reader :applicant_hash

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
        ExternalApplicationId: applicant_hash[:external_application_id],
        TUAdditionalData: tu_additional_data,
        SessionID: applicant_hash[:session_id],
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
          xml.FirstName applicant_hash[:first_name]
          xml.LastName applicant_hash[:last_name]
          xml.Email applicant_hash[:email]
          xml.AddressPhoneNumber applicant_hash[:address_phone_number]
          xml.UnparsedAddrLine1 applicant_hash[:address]
          xml.AddressCity applicant_hash[:city]
          xml.AddressStProv applicant_hash[:province]
          xml.AddressZipPostal applicant_hash[:postal_code]
          xml.PreviousUnparsedAddrLine1 applicant_hash[:previous_address]
          xml.PreviousAddressCity applicant_hash[:previous_city]
          xml.PreviousAddressStProv applicant_hash[:previous_province]
          xml.PreviousAddressZipPostal applicant_hash[:previous_postal_code]
          xml.EmployerName applicant_hash[:employer_name]
          xml.Occupation applicant_hash[:occupation]
          xml.BirthDate applicant_hash[:birth_date]
          xml.SIN applicant_hash[:sin_number]
        end
      end

      builder.to_xml
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
