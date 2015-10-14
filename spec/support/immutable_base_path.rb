RSpec.shared_examples ImmutableBasePath do
  describe 'validations' do
    it 'is valid for the default factory' do
      expect(subject).to be_valid
    end

    context 'when a live content item exists' do
      before do
        create(:live_content_item, content_id: '123', base_path: '/foo')

        subject.content_id = '123'
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
    end
  end
end
