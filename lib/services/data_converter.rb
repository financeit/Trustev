require 'json'
require 'nokogiri'

module Services
  class DataConverter
    def self.hash_to_key_value_pairs(hash)
      pairs = []

      hash.each_key do |key|
        pairs << { Key: key.to_s, Value: hash[key] }
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

    def self.case_response_to_hash(response)
      result = JSON.parse(response)
      context_data = key_value_pairs_to_hash(result['ContextData'])
      te_response = xml_node_to_hash(context_data['TEResponse'])

      unless te_response['TrustevDetailedDecision'].nil?
        te_detailed_decision = JSON.parse(te_response['TrustevDetailedDecision'])
        te_response['TrustevDetailedDecision'] = te_detailed_decision
      end

      context_data['TEResponse'] = te_response
      result['ContextData'] = context_data
      result
    end
  end
end
