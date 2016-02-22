RSpec.shared_examples ReceiptOrderable do
  describe "#increment_receipt_order" do
    it "increments the receipt order" do
      subject.save
      5.times do |count|
        subject.increment_receipt_order
        expect(subject.receipt_order).to eq(count + 1)
      end
    end
  end
end
