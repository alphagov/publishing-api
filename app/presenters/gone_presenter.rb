module GonePresenter
  def self.present(base_path:, publishing_app:, alternative_path:, explanation:)
    {
      document_type: "gone",
      schema_name: "gone",
      base_path: base_path,
      publishing_app: publishing_app,
      details: {
        explanation: explanation,
        alternative_path: alternative_path,
      },
      routes: [
        {
          path: base_path,
          type: "exact",
        }
      ],
    }
  end
end
