RSpec.shared_examples ReceiptOrderable do
  describe "receipt_order" do
    before do
      subject.save
    end

    context "after_save" do
      it "is incremented" do
        expect(subject.receipt_order).to eq(1)
        subject.save
        expect(subject.receipt_order).to eq(2)
      end

      it "doesn't mark the item dirty" do
        expect(subject).not_to be_changed
      end
    end

    context "on touch" do
      it "is incremented" do
        original_receipt_order = subject.receipt_order
        subject.touch
        expect(subject.receipt_order).to eq(original_receipt_order + 1)
      end
    end
  end
end
