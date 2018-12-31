require 'spec_helper'

describe Services::DataConverter do
  subject(:data_converter) { Services::DataConverter }

  describe '.hash_to_key_value_pairs' do
    context 'when the hash is empty' do
      let(:hash) do
        {}
      end

      let(:pairs) { [] }

      it 'returns an empty array' do
        expect(data_converter.hash_to_key_value_pairs(hash)).to eq(pairs)
      end
    end

    context 'when the hash contains keys' do
      let(:hash) do
        { x: 'y', a: 5, b: true }
      end

      let(:pairs) do
        [
          { Key: 'x', Value: 'y' },
          { Key: 'a', Value: 5 },
          { Key: 'b', Value: true }
        ]
      end

      it 'converts the hash into an array of key-value pairs' do
        expect(data_converter.hash_to_key_value_pairs(hash)).to eq(pairs)
      end
    end
  end

  describe '.key_value_pairs_to_hash' do
    context 'when the array is empty' do
      let(:pairs) { [] }

      let(:hash) do
        {}
      end

      it 'returns an empty hash' do
        expect(data_converter.key_value_pairs_to_hash(pairs)).to eq(hash)
      end
    end

    context 'when the array contains pairs' do
      let(:pairs) do
        [
          { 'Key' => 'x', 'Value' => 'y' },
          { 'Key' => 'a', 'Value' => 5 },
          { 'Key' => 'b', 'Value' => true }
        ]
      end

      let(:hash) do
        { 'x' => 'y', 'a' => 5, 'b' => true }
      end

      it 'converts the pairs into a hash' do
        expect(data_converter.key_value_pairs_to_hash(pairs)).to eq(hash)
      end
    end
  end

  describe '.xml_node_to_hash' do
    context 'when the node has no children' do
      let(:xml) { '<root></root>' }

      let(:hash) do
        {}
      end

      it 'returns an empty hash' do
        expect(data_converter.xml_node_to_hash(xml)).to eq(hash)
      end
    end

    context 'when the node has children' do
      let(:xml) { '<root><child1>x</child1><child2>42</child2><child3>false</child3></root>' }

      let(:hash) do
        {
          'child1' => 'x',
          'child2' => '42',
          'child3' => 'false'
        }
      end

      it 'converts the node into a hash' do
        expect(data_converter.xml_node_to_hash(xml)).to eq(hash)
      end
    end
  end

  describe '.encode_response' do
    context 'when the response is already in unicode' do
      let(:response) { "I am unicode response" }

      it 'returns the response as is' do
        expect(data_converter.encode_response(response)).to eq(response)
      end
    end

    context 'when the response contains non-unicode characters' do
      let(:response) { "I am non\x96unicode response" }
      let(:encoded) { "I am non–unicode response" }

      it 'encodes the response to unicode' do
        expect(data_converter.encode_response(response)).to eq(encoded)
      end
    end
  end

  describe '.case_response_to_hash' do
    context 'when response does not contain Detailed Decision' do
      let(:response) do
        {
          'a' => 'b',
          'x' => 42,
          'ContextData' => [
            { 'Key' => 'TEResponse', 'Value' => '<root><child>value</child></root>' }
          ]
        }
      end

      let(:hash) do
        {
          'a' => 'b',
          'x' => 42,
          'ContextData' => {
            'TEResponse' => {
              'child' => 'value'
            }
          }
        }
      end

      it 'converts the response into a hash' do
        expect(data_converter.case_response_to_hash(response.to_json)).to eq(hash)
      end
    end

    context 'when response contains Detailed Decision' do
      let(:response) do
        {
          'a' => 'b',
          'x' => 42,
          'ContextData' => [
            {
              'Key' => 'TEResponse',
              'Value' => "<root><TrustevDetailedDecision>#{detailed_decision.to_json}</TrustevDetailedDecision></root>"
            }
          ]
        }
      end

      let(:detailed_decision) do
        {
          'y' => true
        }
      end

      let(:hash) do
        {
          'a' => 'b',
          'x' => 42,
          'ContextData' => {
            'TEResponse' => {
              'TrustevDetailedDecision' => {
                'y' => true
              }
            }
          }
        }
      end

      it 'converts the response into a hash' do
        expect(data_converter.case_response_to_hash(response.to_json)).to eq(hash)
      end
    end
  end
end
