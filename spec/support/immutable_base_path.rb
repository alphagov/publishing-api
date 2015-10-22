RSpec.shared_examples ImmutableBasePath do
  describe 'validations' do
    context 'when a live content item exists' do
      before do
        FactoryGirl.create(:live_content_item,
               content_id: subject.content_id,
               base_path: '/foo')

        subject.base_path = '/bar'
      end

      it 'does not allow the base path to be changed' do
        expect(subject).not_to be_valid
      end

      context 'when the mutable_base_path flag is set' do
        before { subject.mutable_base_path = true }

        it 'does allow the base path to be changed' do
          expect(subject).to be_valid
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

        expect(subject).to be_valid
      end
    end
  end
end
