RSpec.describe "GraphQL" do
  describe "generic edition" do
    let(:document) { create(:document, content_id: "d53db33f-d4ac-4eb3-839a-d415174eb906") }
    let(:edition) do
      create(
        :live_edition,
        document:,
        document_type: "generic_type",
        first_published_at: Time.utc(2025, 1, 1, 0, 0, 0),
        public_updated_at: Time.utc(2025, 4, 1, 0, 0, 0),
        updated_at: Time.utc(2025, 4, 1, 0, 0, 0),
      )
    end

    it "exposes generic edition fields" do
      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"#{edition.base_path}\") {
              ... on Edition {
                title
                analytics_identifier
                base_path
                content_id
                description
                details {
                  body
                }
                document_type
                first_published_at
                locale
                phase
                public_updated_at
                publishing_app
                publishing_request_id
                publishing_scheduled_at
                rendering_app
                scheduled_publishing_delay_seconds
                schema_name
                updated_at
                withdrawn_notice {
                  explanation
                  withdrawn_at
                }
              }
            }
          }",
      }

      expected = {
        "data": {
          "edition": {
            "analytics_identifier": edition.analytics_identifier,
            "base_path": edition.base_path,
            "content_id": edition.content_id,
            "description": edition.description,
            "details": {
              "body": edition.details[:body],
            },
            "document_type": edition.document_type,
            "first_published_at": "2025-01-01T00:00:00+00:00",
            "locale": edition.locale,
            "phase": edition.phase,
            "public_updated_at": "2025-04-01T01:00:00+01:00",
            "publishing_app": edition.publishing_app,
            "publishing_request_id": edition.publishing_request_id,
            "publishing_scheduled_at": nil,
            "rendering_app": edition.rendering_app,
            "scheduled_publishing_delay_seconds": nil,
            "schema_name": edition.schema_name,
            "title": edition.title,
            "updated_at": "2025-04-01T01:00:00+01:00",
            "withdrawn_notice": nil,
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end

    it "sets the document type as a prometheus label" do
      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"#{edition.base_path}\") {
              ... on Edition {
                title
                document_type
                schema_name
              }
            }
          }",
      }

      expect(request.env["govuk.prometheus_labels"]["document_type"]).to eq(edition.document_type)
      expect(request.env["govuk.prometheus_labels"]["schema_name"]).to eq(edition.schema_name)
    end

    it "logs the base_path, document_type, schema_name and timings" do
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info).with(/
        #{Regexp.escape("GraphQL response for #{edition.base_path}")}
        .*
        #{Regexp.escape('(generic / generic_type)')}
        .*
        timing:\ utime\ =.*,\ stime\ =.*,\ real\ =.*
      /x)
      post "/graphql", params: {
        query: %({
          edition(base_path: "#{edition.base_path}") {
            ... on Edition { base_path, document_type, schema_name }
          }
        }),
      }
    end

    it "sets the contains_errors prometheus label if there is an error" do
      post "/graphql", params: {
        query: "{brokenQuery}",
      }

      expect(request.env["govuk.prometheus_labels"]["contains_errors"]).to eq(true)
    end

    context "when the edition is unpublished" do
      context "when the unpublishing type is 'gone'" do
        let(:edition) do
          create(
            :gone_unpublished_edition,
          )
        end

        before do
          post "/graphql", params: {
            query:
              "{
                edition(base_path: \"#{edition.base_path}\") {
                  ... on Edition {
                    title
                  }
                }
              }",
          }
        end

        it "does not return the edition" do
          parsed_response = JSON.parse(response.body).deep_symbolize_keys
          expect(parsed_response.dig(:data, :edition)).to be_nil
        end

        it "includes the unpublishing type and other data in the error" do
          parsed_response = JSON.parse(response.body).deep_symbolize_keys
          expect(parsed_response.dig(:errors, 0, :message)).to eq("Edition has been unpublished")
          expect(parsed_response.dig(:errors, 0, :extensions, :document_type)).to eq("gone")
          expect(parsed_response.dig(:errors, 0, :extensions, :details, :alternative_path)).to eq(edition.unpublishing.alternative_path)
          expect(parsed_response.dig(:errors, 0, :extensions, :details, :explanation)).to eq(edition.unpublishing.explanation)
          expect(parsed_response.dig(:errors, 0, :extensions, :public_updated_at)).to eq("2014-01-02T03:04:05Z")
        end
      end

      context "when the unpublishing type is 'redirect'" do
        let(:edition) do
          create(
            :redirect_unpublished_edition,
          )
        end

        before do
          post "/graphql", params: {
            query:
              "{
                edition(base_path: \"#{edition.base_path}\") {
                  ... on Edition {
                    title
                  }
                }
              }",
          }
        end

        it "does not return the edition" do
          parsed_response = JSON.parse(response.body).deep_symbolize_keys
          expect(parsed_response.dig(:data, :edition)).to be_nil
        end

        it "includes the unpublishing type and other data in the error" do
          parsed_response = JSON.parse(response.body).deep_symbolize_keys
          expect(parsed_response.dig(:errors, 0, :message)).to eq("Edition has been unpublished")
          expect(parsed_response.dig(:errors, 0, :extensions, :document_type)).to eq("redirect")
          expect(parsed_response.dig(:errors, 0, :extensions, :redirects)).to eq(edition.unpublishing.redirects)
          expect(parsed_response.dig(:errors, 0, :extensions, :public_updated_at)).to eq("2014-01-02T04:04:05Z")
        end
      end

      context "when the unpublishing type is 'vanish'" do
        let(:edition) do
          create(
            :vanish_unpublished_edition,
          )
        end

        before do
          post "/graphql", params: {
            query:
              "{
                edition(base_path: \"#{edition.base_path}\") {
                  ... on Edition {
                    title
                  }
                }
              }",
          }
        end

        it "does not return the edition" do
          parsed_response = JSON.parse(response.body).deep_symbolize_keys
          expect(parsed_response.dig(:data, :edition)).to be_nil
        end

        it "includes the unpublishing type in the error" do
          parsed_response = JSON.parse(response.body).deep_symbolize_keys
          expect(parsed_response.dig(:errors, 0, :message)).to eq("Edition has been unpublished")
          expect(parsed_response.dig(:errors, 0, :extensions, :document_type)).to eq("vanish")
        end
      end

      context "when the unpublishing type is 'withdrawal'" do
        let(:edition) do
          create(
            :withdrawn_unpublished_edition,
            explanation: "for integration testing",
            document_type: "generic_type",
            unpublished_at: Time.utc(2024, 10, 28, 17, 0, 0),
          )
        end

        it "populates the withdrawn notice" do
          post "/graphql", params: {
            query:
              "{
                edition(base_path: \"#{edition.base_path}\") {
                  ... on Edition {
                    withdrawn_notice {
                      explanation
                      withdrawn_at
                    }
                  }
                }
              }",
          }

          expected = {
            "data": {
              "edition": {
                "withdrawn_notice": {
                  "explanation": "for integration testing",
                  "withdrawn_at": "2024-10-28T17:00:00+00:00",
                },
              },
            },
          }

          parsed_response = JSON.parse(response.body).deep_symbolize_keys

          expect(parsed_response).to eq(expected)
        end
      end
    end

    it "handles multiple copies of the same linked-to Edition for distinct link_types" do
      source_edition = create(:live_edition, title: "News Article")
      linked_to_edition = create(:live_edition, title: "News Office")

      create(
        :link_set,
        content_id: source_edition.content_id,
        links_hash: {
          "organisations" => [linked_to_edition.content_id],
          "primary_publishing_organisation" => [linked_to_edition.content_id],
        },
      )

      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"#{source_edition.base_path}\") {
              ... on Edition {
                title

                links {
                  organisations {
                    title
                  }

                  primary_publishing_organisation {
                    title
                  }
                }
              }
            }
          }",
      }

      expected = {
        data: {
          edition: {
            title: "News Article",
            links: {
              organisations: [
                { title: "News Office" },
              ],
              primary_publishing_organisation: [
                { title: "News Office" },
              ],
            },
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end

    it "handles multiple copies of the same LinkSet Link for distinct source Editions" do
      source_edition = create(:live_edition, title: "News Article")
      organisation_edition = create(:live_edition, title: "News Office")
      related_edition1 = create(:live_edition, title: "Related Article 1")
      related_edition2 = create(:live_edition, title: "Related Article 2")

      create(
        :link_set,
        content_id: related_edition1.content_id,
        links_hash: {
          "parent_taxons" => [organisation_edition.content_id],
        },
      )

      create(
        :link_set,
        content_id: related_edition2.content_id,
        links_hash: {
          "parent_taxons" => [organisation_edition.content_id],
        },
      )

      create(
        :link_set,
        content_id: source_edition.content_id,
        links_hash: {
          "taxons" => [
            organisation_edition.content_id,
            related_edition1.content_id,
            related_edition2.content_id,
          ],
        },
      )

      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"#{source_edition.base_path}\") {
              ... on Edition {
                title

                links {
                  taxons {
                    title

                    links {
                      parent_taxons {
                        title
                      }
                    }
                  }
                }
              }
            }
          }",
      }

      expected = {
        data: {
          edition: {
            title: "News Article",
            links: {
              taxons: [
                {
                  title: "News Office",
                  links: {
                    parent_taxons: [],
                  },
                },
                {
                  title: "Related Article 1",
                  links: {
                    parent_taxons: [
                      { title: "News Office" },
                    ],
                  },
                },
                {
                  title: "Related Article 2",
                  links: {
                    parent_taxons: [
                      { title: "News Office" },
                    ],
                  },
                },
              ],
            },
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end

    it "handles multiple copies of the same Edition Link for distinct source Editions" do
      organisation_edition = create(:live_edition, title: "News Office")

      related_edition1 = create(
        :live_edition,
        title: "Related Article 1",
        links_hash: {
          "parent_taxons" => [organisation_edition.content_id],
        },
      )

      related_edition2 = create(
        :live_edition,
        title: "Related Article 2",
        links_hash: {
          "parent_taxons" => [organisation_edition.content_id],
        },
      )

      source_edition = create(
        :live_edition,
        title: "News Article",
        links_hash: {
          "taxons" => [
            organisation_edition.content_id,
            related_edition1.content_id,
            related_edition2.content_id,
          ],
        },
      )

      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"#{source_edition.base_path}\") {
              ... on Edition {
                title

                links {
                  taxons {
                    title

                    links {
                      parent_taxons {
                        title
                      }
                    }
                  }
                }
              }
            }
          }",
      }

      expected = {
        data: {
          edition: {
            title: "News Article",
            links: {
              taxons: [
                {
                  title: "News Office",
                  links: {
                    parent_taxons: [],
                  },
                },
                {
                  title: "Related Article 1",
                  links: {
                    parent_taxons: [
                      { title: "News Office" },
                    ],
                  },
                },
                {
                  title: "Related Article 2",
                  links: {
                    parent_taxons: [
                      { title: "News Office" },
                    ],
                  },
                },
              ],
            },
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end

    it "handles multiple copies of the same reverse LinkSet Link for distinct target Editions" do
      target_edition = create(:live_edition, title: "News Article")

      organisation_edition = create(:live_edition, title: "News Office")
      related_edition1 = create(:live_edition, title: "Related Article 1")
      related_edition2 = create(:live_edition, title: "Related Article 2")

      create(
        :link_set,
        content_id: organisation_edition.content_id,
        links_hash: {
          "parent_taxons" => [
            target_edition.content_id,
            related_edition1.content_id,
            related_edition2.content_id,
          ],
        },
      )

      create(
        :link_set,
        content_id: related_edition1.content_id,
        links_hash: {
          "parent_taxons" => [target_edition.content_id],
        },
      )

      create(
        :link_set,
        content_id: related_edition2.content_id,
        links_hash: {
          "parent_taxons" => [target_edition.content_id],
        },
      )

      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"#{target_edition.base_path}\") {
              ... on Edition {
                title

                links {
                  child_taxons {
                    title

                    links {
                      child_taxons {
                        title
                      }
                    }
                  }
                }
              }
            }
          }",
      }

      expected = {
        data: {
          edition: {
            title: "News Article",
            links: {
              child_taxons: [
                {
                  title: "News Office",
                  links: {
                    child_taxons: [],
                  },
                },
                {
                  title: "Related Article 1",
                  links: {
                    child_taxons: [
                      { title: "News Office" },
                    ],
                  },
                },
                {
                  title: "Related Article 2",
                  links: {
                    child_taxons: [
                      { title: "News Office" },
                    ],
                  },
                },
              ],
            },
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end

    it "handles multiple copies of the same reverse Edition Link for distinct target Editions" do
      target_edition = create(:live_edition, title: "News Article")

      related_edition1 = create(
        :live_edition,
        title: "Related Article 1",
        links_hash: {
          "parent_taxons" => [target_edition.content_id],
        },
      )

      related_edition2 = create(
        :live_edition,
        title: "Related Article 2",
        links_hash: {
          "parent_taxons" => [target_edition.content_id],
        },
      )

      create(
        :live_edition,
        title: "News Office",
        links_hash: {
          "parent_taxons" => [
            target_edition.content_id,
            related_edition1.content_id,
            related_edition2.content_id,
          ],
        },
      )

      post "/graphql", params: {
        query:
          "{
            edition(base_path: \"#{target_edition.base_path}\") {
              ... on Edition {
                title

                links {
                  child_taxons {
                    title

                    links {
                      child_taxons {
                        title
                      }
                    }
                  }
                }
              }
            }
          }",
      }

      expected = {
        data: {
          edition: {
            title: "News Article",
            links: {
              child_taxons: [
                {
                  title: "Related Article 1",
                  links: {
                    child_taxons: [
                      { title: "News Office" },
                    ],
                  },
                },
                {
                  title: "Related Article 2",
                  links: {
                    child_taxons: [
                      { title: "News Office" },
                    ],
                  },
                },
                {
                  title: "News Office",
                  links: {
                    child_taxons: [],
                  },
                },
              ],
            },
          },
        },
      }

      parsed_response = JSON.parse(response.body).deep_symbolize_keys

      expect(parsed_response).to eq(expected)
    end
  end
end
