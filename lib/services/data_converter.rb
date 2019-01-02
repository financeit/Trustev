require 'json'
require 'nokogiri'

module Services
  class DataConverter
    def self.hash_to_key_value_pairs(hash)
      pairs = []

      hash.each do |key, value|
        pairs << { Key: key.to_s, Value: value }
      end

      pairs
    end

    def self.key_value_pairs_to_hash(pairs)
      result = {}

      pairs.each do |pair|
        result[pair['Key']] = pair['Value']
      end

      result
    end

    def self.xml_node_to_hash(xml_node)
      Hash[Nokogiri.XML(xml_node).root.children.map { |child_node| [child_node.name, child_node.text] }]
    end

    def self.encode_response(response)
      # Trustev response contains non-unicode characters that needs conversion
      response.encode("UTF-8", "Windows-1252")
    end

    def self.case_response_to_hash(response)
      result = JSON.parse(encode_response(response))
      context_data = key_value_pairs_to_hash(result['ContextData'])
      trustev_response = xml_node_to_hash(context_data['TEResponse'])

      unless trustev_response['TrustevDetailedDecision'].nil?
        trustev_detailed_decision = JSON.parse(trustev_response['TrustevDetailedDecision'])
        trustev_response['TrustevDetailedDecision'] = trustev_detailed_decision
      end

      context_data['TEResponse'] = trustev_response
      result['ContextData'] = context_data
      result
    end
  end
end
