module Refinements
  module ArraySequence
    refine Array do
      def index_of_sequence(sequence)
        index_sequence = sequence.map { |value| index(value) }
        return if index_sequence.include?(nil)
        first_index = index_sequence[0]
        last_index = first_index + (sequence.length - 1)
        index_sequence == (first_index..last_index).to_a ? first_index : nil
      end
    end
  end
end
