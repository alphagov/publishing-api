RSpec.shared_examples ImmutableBasePath do
  describe 'validations' do
    context 'when a live content item exists' do
      before do
        FactoryGirl.create(
          :live_content_item,
          content_id: subject.content_id,
          base_path: '/foo',
        )

        subject.base_path = '/bar'
      end

      it 'does not allow the base path to be changed' do
        subject.valid?
        expect(subject.errors[:base_path].size).to eq(1)
      end

      context 'when the mutable_base_path flag is set' do
        before { subject.mutable_base_path = true }

        it 'does allow the base path to be changed' do
          subject.valid?
          expect(subject.errors[:base_path].size).to eq(0)
        end
      end

      it 'scopes the content item by locale correctly' do
        FactoryGirl.create(
          :live_content_item,
          content_id: subject.content_id,
          base_path: '/baz',
          locale: 'ar'
        )

        subject.base_path = '/foo'

        subject.valid?
        expect(subject.errors[:base_path].size).to eq(0)
      end
    end
  end
end
