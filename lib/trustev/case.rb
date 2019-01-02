require 'nokogiri'
require 'rest-client'

module Trustev
  REQUEST_MESSAGE_TYPE = 'T'.freeze
  SUCCESSFUL_RESPONSE_ERROR_CODE = '0'.freeze

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
      trustev_response['ErrorCode']
    end

    def error_text
      trustev_response['ErrorText']
    end

    def error?
      error_code != SUCCESSFUL_RESPONSE_ERROR_CODE
    end

    def risk
      raise FieldNotReturnedError if error?

      trustev_response['TEvRisk']
    end

    def score
      raise FieldNotReturnedError if error?

      trustev_detailed_decision['Score']
    end

    def result
      raise FieldNotReturnedError if error?

      trustev_detailed_decision['Result']
    end

    def confidence
      raise FieldNotReturnedError if error?

      trustev_detailed_decision['Confidence']
    end

    def comment
      raise FieldNotReturnedError if error?

      trustev_detailed_decision['Comment']
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
        TUAdditionalData: transunion_additional_data,
        SessionID: applicant_hash[:session_id],
        Language: 'en-CA',
        Applicant: applicant
      }
      hash[:messageType] = REQUEST_MESSAGE_TYPE unless Trustev.configuration.is_production

      ::Services::DataConverter.hash_to_key_value_pairs(hash)
    end

    def transunion_additional_data
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

    def trustev_response
      @trustev_response ||= context_data['TEResponse']
    end

    def trustev_detailed_decision
      @trustev_detailed_decision ||= trustev_response['TrustevDetailedDecision']
    end
  end
end
