require 'spec_helper'

describe Trustev::Case do
  subject(:trustev_case) { Trustev::Case.new(applicant_hash) }

  let(:applicant_hash) do
    {
      external_application_id: "EXTERNAL_APPLICATION_ID",
      session_id: "SESSION_ID",
      first_name: "FIRST_NAME",
      last_name: "LAST_NAME",
      email: "email@example.com",
      address_phone_number: "1234567890",
      address: "ADDRESS",
      city: "CITY",
      province: "PROVINCE",
      postal_code: "POSTAL_CODE",
      previous_address: "FORMER_ADDRESS",
      previous_city: "FORMER_CITY",
      previous_province: "FORMER_PROVINCE",
      previous_postal_code: "FORMER_POSTAL_CODE",
      employer_name: "EMPLOYER_NAME",
      occupation: "OCCUPATION",
      birth_date: "01/09/1999",
      sin_number: "SIN_NUMBER"
    }
  end

  let(:payload) do
    {
      Authentication: {
        Type: "OnDemand",
        UserId: "foo",
        Password: "bar"
      },
      RequestInfo: {
        SolutionSetId: "baz",
        ExecuteLatestVersion: true,
        ExecutionMode: 3
      },
      Fields: fields
    }
  end

  let(:fields) do
    [
      { Key: "ExternalApplicationId", Value: "EXTERNAL_APPLICATION_ID" },
      {
        Key: "TUAdditionalData",
        Value: "<?xml version=\"1.0\"?>\n<TUAdditionalData>\n  <ReferenceID/>\n</TUAdditionalData>\n"
      },
      { Key: "SessionID", Value: "SESSION_ID" },
      { Key: "Language", Value: "en-CA" },
      { Key: "Applicant", Value: applicant_xml },
      { Key: "messageType", Value: "T" }
    ]
  end

  let(:applicant_xml) do
    "<?xml version=\"1.0\"?>\n<Applicant>\n  <FirstName>FIRST_NAME</FirstName>\n  <LastName>LAST_NAME</LastName>\n  "\
    "<Email>email@example.com</Email>\n  <AddressPhoneNumber>1234567890</AddressPhoneNumber>\n  <UnparsedAddrLine1>"\
    "ADDRESS</UnparsedAddrLine1>\n  <AddressCity>CITY</AddressCity>\n  <AddressStProv>PROVINCE</AddressStProv>\n  "\
    "<AddressZipPostal>POSTAL_CODE</AddressZipPostal>\n  <PreviousUnparsedAddrLine1>FORMER_ADDRESS"\
    "</PreviousUnparsedAddrLine1>\n  <PreviousAddressCity>FORMER_CITY</PreviousAddressCity>\n  "\
    "<PreviousAddressStProv>FORMER_PROVINCE</PreviousAddressStProv>\n  <PreviousAddressZipPostal>FORMER_POSTAL_CODE"\
    "</PreviousAddressZipPostal>\n  <EmployerName>EMPLOYER_NAME</EmployerName>\n  <Occupation>OCCUPATION"\
    "</Occupation>\n  <BirthDate>01/09/1999</BirthDate>\n  <SIN>SIN_NUMBER</SIN>\n</Applicant>\n"
  end

  let(:resource) { instance_double(RestClient::Resource) }
  let(:case_response) { "CASE_RESPONSE" }

  let(:error_code) { "0" }
  let(:error_text) { "ERROR_TEXT" }
  let(:risk) { "RISK" }
  let(:score) { "SCORE" }
  let(:result) { "RESULT" }
  let(:confidence) { "CONFIDENCE" }
  let(:comment) { "COMMENT" }
  let(:response_hash) do
    {
      'ContextData' => {
        'TEResponse' => {
          'ErrorCode' => error_code,
          'ErrorText' => error_text,
          'TEvRisk' => risk,
          'TrustevDetailedDecision' => {
            'Score' => score,
            'Result' => result,
            'Confidence' => confidence,
            'Comment' => comment
          }
        }
      }
    }
  end

  before do
    allow(RestClient::Resource).to(receive(:new)).and_return(resource)
    allow(resource).to(receive(:post)).and_return(case_response.to_json)
    allow(::Services::DataConverter).to(receive(:case_response_to_hash)).and_return(response_hash)
    trustev_case.post
  end

  describe '#post' do
    it 'posts the JSON payload to the resource' do
      expect(resource).to have_received(:post).with(payload.to_json)
    end

    it 'converts the response to hash' do
      expect(::Services::DataConverter).to have_received(:case_response_to_hash).with(case_response.to_json)
    end

    it 'sets the response_hash' do
      expect(trustev_case.send(:response_hash)).to eq(response_hash)
    end

    it 'returns the response_hash' do
      expect(trustev_case.post).to eq(response_hash)
    end
  end

  describe '#error_code' do
    it 'returns the error code from the response hash' do
      expect(trustev_case.error_code).to eq(error_code)
    end
  end

  describe '#error_text' do
    it 'returns the error text from the response hash' do
      expect(trustev_case.error_text).to eq(error_text)
    end
  end

  describe '#error?' do
    context 'when the error code is 0' do
      it 'returns false' do
        expect(trustev_case.error?).to eq(false)
      end
    end

    context 'when the error code is not 0' do
      let(:error_code) { "123" }

      it 'returns true' do
        expect(trustev_case.error?).to eq(true)
      end
    end
  end

  describe '#risk' do
    context 'when there was no error' do
      it 'returns the risk from the response hash' do
        expect(trustev_case.risk).to eq(risk)
      end
    end

    context 'when there was an error' do
      let(:error_code) { "123" }

      it 'raises FieldNotReturnedError error' do
        expect do
          trustev_case.risk
        end.to raise_error(Trustev::FieldNotReturnedError)
      end
    end
  end

  describe '#score' do
    context 'when there was no error' do
      it 'returns the score from the response hash' do
        expect(trustev_case.score).to eq(score)
      end
    end

    context 'when there was an error' do
      let(:error_code) { "123" }

      it 'raises FieldNotReturnedError error' do
        expect do
          trustev_case.score
        end.to raise_error(Trustev::FieldNotReturnedError)
      end
    end
  end

  describe '#result' do
    context 'when there was no error' do
      it 'returns the result from the response hash' do
        expect(trustev_case.result).to eq(result)
      end
    end

    context 'when there was an error' do
      let(:error_code) { "123" }

      it 'raises FieldNotReturnedError error' do
        expect do
          trustev_case.result
        end.to raise_error(Trustev::FieldNotReturnedError)
      end
    end
  end

  describe '#confidence' do
    context 'when there was no error' do
      it 'returns the confidence from the response hash' do
        expect(trustev_case.confidence).to eq(confidence)
      end
    end

    context 'when there was an error' do
      let(:error_code) { "123" }

      it 'raises FieldNotReturnedError error' do
        expect do
          trustev_case.confidence
        end.to raise_error(Trustev::FieldNotReturnedError)
      end
    end
  end

  describe '#comment' do
    context 'when there was no error' do
      it 'returns the comment from the response hash' do
        expect(trustev_case.comment).to eq(comment)
      end
    end

    context 'when there was an error' do
      let(:error_code) { "123" }

      it 'raises FieldNotReturnedError error' do
        expect do
          trustev_case.comment
        end.to raise_error(Trustev::FieldNotReturnedError)
      end
    end
  end
end
