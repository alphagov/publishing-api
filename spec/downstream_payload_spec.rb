RSpec.describe DownstreamPayload do
  def create_edition(factory, factory_options = {})
    create(factory, factory_options)
  end

  let(:payload_version) { 1 }
  let(:draft) { false }
  subject(:downstream_payload) do
    DownstreamPayload.new(
      edition,
      payload_version,
      draft:,
    )
  end

  describe "#state" do
    let(:edition) { create_edition(:live_edition) }

    it "equals edition.state" do
      expect(downstream_payload.state).to eq edition.state
    end
  end

  describe "#unpublished?" do
    context "unpublished edition" do
      let(:edition) { create_edition(:unpublished_edition) }

      it "returns true" do
        expect(downstream_payload.unpublished?).to be true
      end
    end

    context "published edition" do
      let(:edition) { create_edition(:live_edition) }

      it "returns false" do
        expect(downstream_payload.unpublished?).to be false
      end
    end
  end

  describe "#content_store_action" do
    context "no base_path" do
      let(:edition) { create_edition(:pathless_live_edition) }

      it "returns :no_op" do
        expect(downstream_payload.content_store_action).to be :no_op
      end
    end

    context "published item" do
      let(:edition) { create_edition(:live_edition) }

      it "returns :put" do
        expect(downstream_payload.content_store_action).to be :put
      end
    end

    context "draft item" do
      let(:edition) { create_edition(:draft_edition) }

      it "returns :put" do
        expect(downstream_payload.content_store_action).to be :put
      end
    end

    context "unpublished item" do
      context "withdrawn type" do
        let(:edition) { create_edition(:withdrawn_unpublished_edition) }

        it "returns :put" do
          expect(downstream_payload.content_store_action).to be :put
        end
      end

      context "redirect type" do
        let(:edition) { create_edition(:redirect_unpublished_edition) }

        it "returns :put" do
          expect(downstream_payload.content_store_action).to be :put
        end
      end

      context "gone type" do
        let(:edition) { create_edition(:gone_unpublished_edition) }

        it "returns :put" do
          expect(downstream_payload.content_store_action).to be :put
        end
      end

      context "vanish type" do
        let(:edition) { create_edition(:vanish_unpublished_edition) }

        it "returns :delete" do
          expect(downstream_payload.content_store_action).to be :delete
        end
      end
    end
  end

  describe "#content_store_payload" do
    let(:content_store_payload_hash) do
      {
        title: edition.title,
        base_path: edition.base_path,
        payload_version:,
      }
    end

    context "published item" do
      context "standard edition" do
        let(:edition) { create_edition(:live_edition) }

        it "returns a content store payload" do
          expect(downstream_payload.content_store_payload).to include(content_store_payload_hash)
        end
      end

      context "redirect edition" do
        let(:edition) { create_edition(:redirect_live_edition) }
        let(:redirect_presenter_double) { instance_double(Presenters::RedirectPresenter) }

        it "returns a content store payload" do
          expect(Presenters::RedirectPresenter).to receive(:from_published_edition).and_return(redirect_presenter_double)
          expect(redirect_presenter_double).to receive(:for_content_store).with(payload_version)
          downstream_payload.content_store_payload
        end
      end
    end

    context "draft item" do
      let(:edition) { create_edition(:draft_edition) }

      it "returns a content store payload" do
        expect(downstream_payload.content_store_payload).to include(content_store_payload_hash)
      end
    end

    context "unpublished item" do
      context "withdrawn type" do
        let(:edition) { create_edition(:withdrawn_unpublished_edition) }

        it "returns a content store payload" do
          expect(downstream_payload.content_store_payload).to include(content_store_payload_hash)
        end
      end

      context "redirect type" do
        let(:edition) { create_edition(:redirect_unpublished_edition) }

        it "returns a redirect payload" do
          expect(downstream_payload.content_store_payload).to include(
            document_type: "redirect",
            base_path: edition.base_path,
          )
        end
      end

      context "redirect type with unpublishing type of gone" do
        let(:edition) do
          create_edition(:redirect_edition, unpublishing: create(
            :unpublishing,
            type: "gone",
          ))
        end

        it "returns a gone payload" do
          expect(downstream_payload.content_store_payload).to include(
            document_type: "gone",
            base_path: edition.base_path,
          )
        end
      end

      context "gone type" do
        let(:edition) { create_edition(:gone_unpublished_edition) }

        it "returns a gone payload" do
          expect(downstream_payload.content_store_payload).to include(
            document_type: "gone",
            base_path: edition.base_path,
          )
        end
      end
    end
  end

  describe "#message_queue_payload" do
    context "a published edition" do
      let(:edition) { create_edition(:live_edition, update_type: "major") }

      it "uses the edition presenter" do
        expect_any_instance_of(Presenters::EditionPresenter).to receive(:for_message_queue).with(payload_version)
        downstream_payload.message_queue_payload
      end
    end

    context "a gone edition" do
      let(:edition) { create_edition(:gone_unpublished_edition, update_type: "major") }

      it "uses the gone presenter" do
        expect_any_instance_of(Presenters::GonePresenter).to receive(:for_message_queue).with(payload_version)
        downstream_payload.message_queue_payload
      end
    end

    context "a substitute edition" do
      let(:edition) { create_edition(:substitute_unpublished_edition, update_type: "major") }

      it "uses the substitute presenter" do
        expect_any_instance_of(Presenters::SubstitutePresenter).to receive(:for_message_queue).with(payload_version)
        downstream_payload.message_queue_payload
      end
    end

    context "a vanish edition" do
      let(:edition) { create_edition(:vanish_unpublished_edition, update_type: "major") }

      it "uses the vanish presenter" do
        expect_any_instance_of(Presenters::VanishPresenter).to receive(:for_message_queue).with(payload_version)
        downstream_payload.message_queue_payload
      end
    end

    context "an unpublished redirect" do
      let(:edition) { create_edition(:redirect_unpublished_edition, update_type: "major") }
      let(:redirect_presenter_double) { instance_double(Presenters::RedirectPresenter) }

      it "uses the redirect presenter" do
        expect(Presenters::RedirectPresenter).to receive(:from_unpublished_edition).and_return(redirect_presenter_double)
        expect(redirect_presenter_double).to receive(:for_message_queue).with(payload_version)
        downstream_payload.message_queue_payload
      end
    end

    context "a published redirect" do
      let(:edition) { create_edition(:redirect_live_edition, update_type: "major") }
      let(:redirect_presenter_double) { instance_double(Presenters::RedirectPresenter) }

      it "uses the redirect presenter" do
        expect(Presenters::RedirectPresenter).to receive(:from_published_edition).and_return(redirect_presenter_double)
        expect(redirect_presenter_double).to receive(:for_message_queue).with(payload_version)
        downstream_payload.message_queue_payload
      end
    end
  end
end
